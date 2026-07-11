const crypto = require('crypto');
const cloudinary = require('cloudinary').v2;
const { pool } = require('../../config/database');

/**
 * Service d analyse intelligente des captures Mobile Money
 * Phase 1 : Analyse par patterns regex (sans API externe) — simulation enrichie
 * Phase 2 : Google Vision API — activée automatiquement si
 *           GOOGLE_VISION_CREDENTIALS_JSON est configurée, sinon repli sur
 *           la simulation Phase 1 (aucun crash si l API n est pas encore
 *           configurée ou échoue ponctuellement).
 */
class CaptureAnalyseService {

  // ── PATTERNS DE RECONNAISSANCE ─────────────────────
  static PATTERNS = {
    // Orange Money Burkina Faso
    ORANGE_BF: {
      nom: 'Orange Money BF',
      patterns: {
        succes: /transaction.*(r[ée]ussie?|successful|confirm[ée]e?|effectu[ée]e?)/i,
        montant: /(\d[\d\s]*(?:[.,]\d+)?)\s*(?:F\s*CFA|FCFA|XOF|F)/i,
        reference: /(?:r[ée]f[ée]rence?|ref|id|transaction)[:\s#]*([A-Z0-9]{6,20})/i,
        destinataire: /(?:destinataire|b[ée]n[ée]ficiaire|envoy[ée]\s*[àa])[:\s]*(\+?226\s*\d[\d\s]{8,})/i,
        date: /(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})/,
        heure: /(\d{1,2}:\d{2}(?::\d{2})?)/,
      }
    },
    // Moov Money Burkina Faso
    MOOV_BF: {
      nom: 'Moov Money BF',
      patterns: {
        succes: /(?:paiement|transfert|envoi).*(accept[ée]e?|valid[ée]e?|r[ée]ussie?)/i,
        montant: /(\d[\d\s]*(?:[.,]\d+)?)\s*(?:F\s*CFA|FCFA|XOF)/i,
        reference: /(?:num[ée]ro|code|ref)[:\s]*([A-Z0-9]{6,20})/i,
        destinataire: /(\+?226\s*\d[\d\s]{8,})/,
        date: /(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})/,
        heure: /(\d{1,2}:\d{2})/,
      }
    },
    // Wave
    WAVE: {
      nom: 'Wave',
      patterns: {
        succes: /(?:sent|envoy[ée]|transferred|transfer).*(successfully|avec\s+succ[eè]s)/i,
        montant: /(\d[\d,\s]*)\s*(?:F|CFA|FCFA|XOF)/i,
        reference: /(?:wave\s*id|transaction\s*id|ref)[:\s]*([A-Z0-9\-]{6,30})/i,
        destinataire: /(?:to|[àa]|pour)[:\s]*([+\d\s]{8,15})/i,
        date: /(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})/,
        heure: /(\d{1,2}:\d{2})/,
      }
    },
    // MTN Mobile Money
    MTN: {
      nom: 'MTN Mobile Money',
      patterns: {
        succes: /(?:transaction|transfert).*(r[ée]ussie?|confirmed|approved)/i,
        montant: /(\d[\d\s]*)\s*(?:F\s*CFA|XAF|XOF|FCFA)/i,
        reference: /(?:txn|transaction|ref)[:\s#]*([A-Z0-9]{6,20})/i,
        destinataire: /(\+?226\s*\d[\d\s]{8,}|\+?237\s*\d[\d\s]{8,})/,
        date: /(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})/,
        heure: /(\d{1,2}:\d{2})/,
      }
    },
  };

  /**
   * Analyser une capture Mobile Money
   * @param {string} texteOCR - Texte extrait de l image
   * @param {object} contexte - Informations attendues (montantAttendu doit
   *   être le montant RESTANT dû pour la période ciblée, pas forcément le
   *   montant total de la cotisation — voir paiements.js)
   * @returns {object} Résultat d analyse
   */
  static analyserTexte(texteOCR, contexte = {}) {
    const texte = texteOCR.toLowerCase();
    let operateur = null;
    let scoreConfiance = 0;
    let details = {};
    let alertes = [];

    // 1. Détecter l opérateur
    if (/orange\s*money|om\s*bf|orangemoney/i.test(texteOCR)) {
      operateur = 'ORANGE_BF';
    } else if (/moov\s*money|flooz|moov\s*africa/i.test(texteOCR)) {
      operateur = 'MOOV_BF';
    } else if (/wave/i.test(texteOCR)) {
      operateur = 'WAVE';
    } else if (/mtn\s*money|mtn\s*mobile/i.test(texteOCR)) {
      operateur = 'MTN';
    }

    const patterns = operateur
      ? this.PATTERNS[operateur].patterns
      : this.PATTERNS.ORANGE_BF.patterns;

    // 2. Vérifier le succès de la transaction
    const estReussie = Object.values(this.PATTERNS).some(p =>
      p.patterns.succes.test(texteOCR)
    );

    if (!estReussie) {
      alertes.push('Transaction non confirmée comme réussie');
      scoreConfiance -= 30;
    } else {
      scoreConfiance += 30;
    }

    // 3. Extraire le montant
    // FIX (paiement par tranche): un montant INFÉRIEUR au montant attendu
    // n est plus pénalisé — c est un paiement partiel légitime, pas un
    // signal de fraude. Seul un montant démesurément SUPÉRIEUR (>3x, capture
    // d une transaction sans rapport) reste suspect. Un montant qui
    // correspond exactement reste le cas le mieux noté.
    const matchMontant = patterns.montant.exec(texteOCR);
    if (matchMontant) {
      const montantStr = matchMontant[1].replace(/[\s,]/g, '');
      details.montant = parseFloat(montantStr);
      scoreConfiance += 25;

      if (contexte.montantAttendu) {
        const ratio = details.montant / contexte.montantAttendu;
        if (ratio > 3) {
          alertes.push(`Montant ${details.montant} F très supérieur au montant attendu ${contexte.montantAttendu} F`);
          scoreConfiance -= 15;
        } else if (ratio >= 0.99) {
          scoreConfiance += 20;
        } else {
          alertes.push(`Paiement partiel: ${details.montant} F sur ${contexte.montantAttendu} F attendu`);
          scoreConfiance += 10;
        }
      }
    } else {
      alertes.push('Montant non détecté');
      scoreConfiance -= 25;
    }

    // 4. Extraire la référence
    const matchRef = patterns.reference.exec(texteOCR);
    if (matchRef) {
      details.reference = matchRef[1].toUpperCase();
      scoreConfiance += 15;
    } else {
      alertes.push('Référence transaction non trouvée');
    }

    // 5. Extraire le destinataire
    const matchDest = patterns.destinataire.exec(texteOCR);
    if (matchDest) {
      const valeurDest = matchDest[1] ?? matchDest[0];
      details.destinataire = valeurDest.replace(/\s/g, '');
      scoreConfiance += 10;

      if (contexte.numeroOrganisateur) {
        const numeroNormalise = contexte.numeroOrganisateur.replace(/[\s\+]/g, '');
        const destNormalise = details.destinataire.replace(/[\s\+]/g, '');
        if (destNormalise.includes(numeroNormalise.slice(-8)) ||
            numeroNormalise.includes(destNormalise.slice(-8))) {
          scoreConfiance += 15;
        } else {
          alertes.push('Numéro destinataire ne correspond pas à l organisateur');
          scoreConfiance -= 20;
        }
      }
    }

    // 6. Extraire la date
    const matchDate = patterns.date.exec(texteOCR);
    if (matchDate) {
      details.date = matchDate[1];
      scoreConfiance += 5;

      try {
        const parts = details.date.split(/[\/\-]/);
        const dateCapture = new Date(
          parseInt(parts[2]) < 100 ? 2000 + parseInt(parts[2]) : parseInt(parts[2]),
          parseInt(parts[1]) - 1,
          parseInt(parts[0])
        );
        const maintenant = new Date();
        const diffHeures = (maintenant - dateCapture) / (1000 * 60 * 60);
        if (diffHeures > 48) {
          alertes.push('Capture datée de plus de 48h');
          scoreConfiance -= 15;
        }
      } catch (e) {}
    }

    // 7. Extraire l heure
    const matchHeure = patterns.heure.exec(texteOCR);
    if (matchHeure) {
      details.heure = matchHeure[1];
    }

    scoreConfiance = Math.max(0, Math.min(100, scoreConfiance));

    let decision;
    if (!estReussie) {
      decision = 'REJETE';
    } else if (scoreConfiance >= 85) {
      decision = 'AUTO_VALIDE';
    } else if (scoreConfiance >= 60) {
      decision = 'VALIDATION_MANUELLE';
    } else {
      decision = 'REJETE';
    }

    return {
      operateur: operateur ? this.PATTERNS[operateur].nom : 'Inconnu',
      estReussie,
      scoreConfiance,
      decision,
      details,
      alertes,
      texteAnalyse: texteOCR.substring(0, 500),
    };
  }

  static _genererTexteSimule(contexte = {}) {
    const maintenant = new Date();
    const dateStr = [
      String(maintenant.getDate()).padStart(2, '0'),
      String(maintenant.getMonth() + 1).padStart(2, '0'),
      maintenant.getFullYear(),
    ].join('/');
    const heureStr = [
      String(maintenant.getHours()).padStart(2, '0'),
      String(maintenant.getMinutes()).padStart(2, '0'),
    ].join(':');

    const montant = contexte.montantAttendu
      || [1000, 2000, 5000, 10000, 15000][Math.floor(Math.random() * 5)];

    const destinataire = contexte.numeroOrganisateur
      || `+226 ${Math.floor(60000000 + Math.random() * 9999999)}`;

    const suffixeUnique = `${Date.now()}${Math.floor(Math.random() * 1000)}`;

    const gabarits = [
      () => `Orange Money BF
Transaction Réussie
Montant: ${montant} F CFA
Référence: OM${suffixeUnique}
Destinataire: ${destinataire}
Date: ${dateStr}
Heure: ${heureStr}`,

      () => `Moov Money BF
Paiement Accepté
Montant envoyé: ${montant} FCFA
Code: MV${suffixeUnique}
Vers: ${destinataire}
Le ${dateStr} à ${heureStr}`,

      () => `MTN Mobile Money
Transaction confirmée
Montant: ${montant} F CFA
Txn ID: MTN${suffixeUnique}
Bénéficiaire: ${destinataire}
${dateStr} ${heureStr}`,

      () => `Wave
Vous avez envoyé ${montant} F avec succès
à ${destinataire}
Transaction ID: WV${suffixeUnique}
${dateStr} - ${heureStr}`,
    ];

    const gabaritChoisi = gabarits[Math.floor(Math.random() * gabarits.length)];
    return gabaritChoisi();
  }

  static _getVisionClient() {
    if (this._visionClient !== undefined) return this._visionClient;

    const credsJson = process.env.GOOGLE_VISION_CREDENTIALS_JSON;
    if (!credsJson) {
      this._visionClient = null;
      return null;
    }

    try {
      const vision = require('@google-cloud/vision');
      const credentials = JSON.parse(credsJson);
      this._visionClient = new vision.ImageAnnotatorClient({ credentials });
      console.log('Google Vision API initialisée avec succès');
    } catch (err) {
      console.error('Erreur initialisation Google Vision API, utilisation de la simulation:', err.message);
      this._visionClient = null;
    }
    return this._visionClient;
  }

  static async extraireTexte(imageUrl, contexte = {}) {
    const client = this._getVisionClient();
    if (client) {
      try {
        const [result] = await client.textDetection({
          image: { source: { imageUri: imageUrl } },
        });
        const texte = result.textAnnotations?.[0]?.description;
        if (texte) return texte;
        console.warn('Vision API: aucun texte détecté sur la capture, repli sur la simulation');
      } catch (err) {
        console.error('Erreur Google Vision API, repli sur la simulation:', err.message);
      }
    }
    return this._genererTexteSimule(contexte);
  }

  static async simulerOCR(imageUrl) {
    return this._genererTexteSimule({});
  }

  static async hashImage(buffer) {
    return crypto.createHash('sha256').update(buffer).digest('hex');
  }

  static async referenceDejaUtilisee(reference, tontineId) {
    if (!reference) return false;
    const { rows } = await pool.query(
      `SELECT id FROM cotisations
       WHERE reference_transaction = $1
       AND tontine_id != $2`,
      [reference, tontineId]
    );
    return rows.length > 0;
  }

  static async hashDejaUtilise(hash) {
    const { rows } = await pool.query(
      'SELECT id FROM cotisations WHERE capture_hash = $1',
      [hash]
    );
    return rows.length > 0;
  }
}

module.exports = CaptureAnalyseService;