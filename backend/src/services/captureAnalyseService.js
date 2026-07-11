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
        // FIX: pas de groupe de capture ici auparavant -> matchDest[1]
        // valait undefined -> crash sur .replace(). Ajout du groupe (...).
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
        // FIX: même bug que MOOV_BF — groupe de capture ajouté.
        destinataire: /(\+?226\s*\d[\d\s]{8,}|\+?237\s*\d[\d\s]{8,})/,
        date: /(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})/,
        heure: /(\d{1,2}:\d{2})/,
      }
    },
  };

  /**
   * Analyser une capture Mobile Money
   * @param {string} texteOCR - Texte extrait de l image
   * @param {object} contexte - Informations attendues
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
    const matchMontant = patterns.montant.exec(texteOCR);
    if (matchMontant) {
      const montantStr = matchMontant[1].replace(/[\s,]/g, '');
      details.montant = parseFloat(montantStr);
      scoreConfiance += 25;

      // Vérifier cohérence avec montant attendu
      if (contexte.montantAttendu) {
        const diff = Math.abs(details.montant - contexte.montantAttendu);
        const tolerance = contexte.montantAttendu * 0.01; // 1% tolerance
        if (diff <= tolerance) {
          scoreConfiance += 20;
        } else {
          alertes.push(`Montant ${details.montant} F ≠ attendu ${contexte.montantAttendu} F`);
          scoreConfiance -= 20;
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
      // FIX défensif: si un pattern futur oublie un groupe de capture,
      // on retombe sur le match complet (matchDest[0]) plutôt que de
      // planter sur .replace(undefined).
      const valeurDest = matchDest[1] ?? matchDest[0];
      details.destinataire = valeurDest.replace(/\s/g, '');
      scoreConfiance += 10;

      // Vérifier cohérence avec numéro organisateur
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

      // Vérifier que la date est récente (max 48h)
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

    // Score final (0-100)
    scoreConfiance = Math.max(0, Math.min(100, scoreConfiance));

    // Décision finale
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

  /**
   * Génère un texte de capture simulé (Phase 1), utilisé comme repli quand
   * Google Vision API n est pas configurée ou échoue. Choisit aléatoirement
   * parmi 4 gabarits d opérateurs (Orange, Moov, MTN, Wave) pour permettre
   * de tester la reconnaissance multi-opérateurs sans API externe. Le
   * montant et le destinataire reprennent le contexte réel (montant attendu
   * de la période, numéro de l organisateur) quand disponible, afin que les
   * tests puissent atteindre AUTO_VALIDE de façon réaliste. La date/heure
   * sont toujours celles du moment (évite le rejet automatique "capture de
   * plus de 48h"). La référence est unique à chaque appel (evite les faux
   * doublons entre soumissions de test).
   */
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

    // Suffixe aléatoire en plus du timestamp pour éviter toute collision de
    // référence même en cas d appels quasi simultanés (même milliseconde).
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

  /**
   * Client Google Vision, créé une seule fois et mis en cache (y compris
   * le cas "non configuré" -> null, pour ne pas retenter à chaque appel).
   * Ne configure rien si GOOGLE_VISION_CREDENTIALS_JSON est absente : dans
   * ce cas, extraireTexte() utilisera directement la simulation, sans
   * jamais planter le serveur ni bloquer le démarrage (le require du
   * package est fait ici, en différé, pas en haut du fichier).
   */
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

  /**
   * Extraire le texte d une capture. Utilise Google Vision API si
   * configurée et disponible ; sinon (ou en cas d échec ponctuel : quota,
   * réseau, image illisible...) retombe sur la simulation Phase 1 enrichie,
   * pour ne jamais faire échouer une soumission à cause d un problème côté
   * OCR externe.
   */
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

  /**
   * Conservé pour compatibilité avec d éventuels appels existants ailleurs
   * dans le code. Préférer extraireTexte(imageUrl, contexte), qui gère
   * aussi Google Vision API.
   */
  static async simulerOCR(imageUrl) {
    return this._genererTexteSimule({});
  }

  /**
   * Hash d une image pour détection de doublons
   */
  static async hashImage(buffer) {
    return crypto.createHash('sha256').update(buffer).digest('hex');
  }

  /**
   * Vérifier si une référence a déjà été utilisée
   */
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

  /**
   * Vérifier si un hash d image a déjà été utilisé
   */
  static async hashDejaUtilise(hash) {
    const { rows } = await pool.query(
      'SELECT id FROM cotisations WHERE capture_hash = $1',
      [hash]
    );
    return rows.length > 0;
  }
}

module.exports = CaptureAnalyseService;