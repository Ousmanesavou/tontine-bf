const express = require('express');
const router = express.Router();
const multer = require('multer');
const cloudinary = require('cloudinary').v2;
const { pool } = require('../../config/database');
const { authenticate } = require('../middleware/auth');
const CaptureAnalyseService = require('../services/captureAnalyseService');
const streamifier = require('streamifier');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB max
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) cb(null, true);
    else cb(new Error('Seules les images sont acceptées'));
  }
});

/**
 * Applique un surplus (trop-perçu sur une période) aux périodes suivantes
 * du même membre, dans l'ordre chronologique, jusqu'à épuisement du
 * surplus ou absence de période éligible restante.
 */
async function appliquerSurplus(client, tontineId, membreId, membreInfo, surplusInitial, periodeDepart) {
  let surplus = surplusInitial;
  let derniereDeriode = periodeDepart;

  while (surplus > 0) {
    const { rows: [prochaine] } = await client.query(
      `SELECT * FROM cotisations
       WHERE tontine_id = $1 AND membre_id = $2
       AND (
         (statut = 'en_attente' AND capture_url IS NULL)
         OR statut = 'partiel'
       )
       AND periode_numero > $3
       ORDER BY periode_numero ASC
       LIMIT 1`,
      [tontineId, membreId, derniereDeriode]
    );

    if (!prochaine) break;

    const montantDu = parseFloat(prochaine.montant);
    const dejaPaye = parseFloat(prochaine.montant_paye) || 0;
    const restant = montantDu - dejaPaye;
    const aAppliquer = Math.min(surplus, restant);
    const cumul = dejaPaye + aAppliquer;
    const nouveauStatut = cumul >= montantDu ? 'paye' : 'partiel';

    await client.query(
      `UPDATE cotisations SET
        statut = $1,
        montant_paye = $2,
        date_paiement = CASE WHEN $1 = 'paye' THEN NOW() ELSE date_paiement END
       WHERE id = $3`,
      [nouveauStatut, Math.min(cumul, montantDu), prochaine.id]
    );

    // FIX: RETURNING id pour récupérer le compte_virtuel_id réel, et le
    // renseigner (avec utilisateur_id) sur transactions_virtuelles — sans
    // ça, ces colonnes restent NULL et l écran "Compte virtuel" côté app
    // (qui filtre dessus dans tontineController.js) ne trouve jamais rien.
    const { rows: [compteVirtuel] } = await client.query(
      `INSERT INTO comptes_virtuels (tontine_id, solde, total_depots)
       VALUES ($1, $2, $2)
       ON CONFLICT (tontine_id)
       DO UPDATE SET solde = comptes_virtuels.solde + $2,
                     total_depots = COALESCE(comptes_virtuels.total_depots, 0) + $2,
                     updated_at = NOW()
       RETURNING id`,
      [tontineId, aAppliquer]
    );

    await client.query(
      `INSERT INTO transactions_virtuelles (
        tontine_id, compte_virtuel_id, type, montant, membre_id, utilisateur_id,
        cotisation_id, description, solde_avant, solde_apres
      )
      SELECT $1, $2, 'depot', $3, $4, $5, $6, $7,
             COALESCE(solde, 0) - $3, COALESCE(solde, 0)
      FROM comptes_virtuels WHERE tontine_id = $1`,
      [
        tontineId, compteVirtuel.id, aAppliquer, membreId, membreId, prochaine.id,
        `Surplus reporté (période ${derniereDeriode} → ${prochaine.periode_numero}) - ${membreInfo.prenom} ${membreInfo.nom_membre}`
      ]
    );

    surplus -= aAppliquer;
    derniereDeriode = prochaine.periode_numero;
  }

  return surplus;
}

router.use(authenticate);

// ── SOUMETTRE UNE COTISATION AVEC CAPTURE ─────────────
router.post('/soumettre', upload.single('capture'), async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { tontine_id, montant, methode_paiement, notes } = req.body;
    const userId = req.user.id;

    if (!req.file) {
      return res.status(400).json({ error: 'Capture d écran requise' });
    }

    // 1. Vérifier que l utilisateur est membre de la tontine
    const { rows: [membre] } = await client.query(
      `SELECT mt.*, t.montant_cotisation, t.nom as tontine_nom,
              u.prenom, u.nom as nom_membre,
              COALESCE(org.orange_money_numero, org.moov_money_numero) as numero_mobile_money
       FROM membres_tontine mt
       JOIN tontines t ON t.id = mt.tontine_id
       JOIN utilisateurs u ON u.id = mt.utilisateur_id
       JOIN utilisateurs org ON org.id = t.responsable_id
       WHERE mt.tontine_id = $1 AND mt.utilisateur_id = $2 AND mt.est_actif = true`,
      [tontine_id, userId]
    );

    if (!membre) {
      return res.status(403).json({ error: 'Vous n êtes pas membre de cette tontine' });
    }

    // 2. Trouver la période de cotisation à honorer
    const { rows: [cotisationCible] } = await client.query(
      `SELECT * FROM cotisations
       WHERE tontine_id = $1 AND membre_id = $2
       AND (
         (statut = 'en_attente' AND capture_url IS NULL)
         OR statut = 'rejete'
         OR statut = 'partiel'
       )
       ORDER BY periode_numero ASC
       LIMIT 1`,
      [tontine_id, userId]
    );

    if (!cotisationCible) {
      return res.status(400).json({
        error: 'Aucune cotisation en attente de paiement pour cette tontine. Vous êtes soit à jour, soit une soumission précédente est déjà en cours de validation.'
      });
    }

    // 3. Hash de l image (anti-doublon)
    const imageHash = await CaptureAnalyseService.hashImage(req.file.buffer);
    const hashUtilise = await CaptureAnalyseService.hashDejaUtilise(imageHash);
    if (hashUtilise) {
      return res.status(400).json({
        error: 'Cette capture a déjà été utilisée',
        code: 'CAPTURE_DUPLIQUEE'
      });
    }

    // 4. Upload sur Cloudinary
    const uploadResult = await new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        {
          folder: `tontiligdi/cotisations/${tontine_id}`,
          resource_type: 'image',
          transformation: [
            { quality: 'auto', fetch_format: 'auto' },
            { width: 1200, crop: 'limit' }
          ]
        },
        (error, result) => {
          if (error) reject(error);
          else resolve(result);
        }
      );
      streamifier.createReadStream(req.file.buffer).pipe(stream);
    });

    // 5. Analyse IA de la capture
    const montantRestantDu = Math.max(
      0,
      parseFloat(cotisationCible.montant) - (parseFloat(cotisationCible.montant_paye) || 0)
    );
    const contexteAnalyse = {
      montantAttendu: montantRestantDu || membre.montant_cotisation,
      numeroOrganisateur: membre.numero_mobile_money,
    };
    const texteOCR = await CaptureAnalyseService.extraireTexte(uploadResult.secure_url, contexteAnalyse);
    const analyse = CaptureAnalyseService.analyserTexte(texteOCR, contexteAnalyse);

    // 6. Vérifier référence unique
    if (analyse.details.reference) {
      const refUtilisee = await CaptureAnalyseService.referenceDejaUtilisee(
        analyse.details.reference, tontine_id
      );
      if (refUtilisee) {
        return res.status(400).json({
          error: 'Cette référence de transaction a déjà été utilisée',
          code: 'REFERENCE_DUPLIQUEE'
        });
      }
    }

    // 7. Déterminer l issue selon le score IA
    let decisionStatut;
    switch (analyse.decision) {
      case 'AUTO_VALIDE':
        decisionStatut = 'accepte';
        break;
      case 'VALIDATION_MANUELLE':
        decisionStatut = 'en_attente';
        break;
      case 'REJETE':
        decisionStatut = 'rejete';
        break;
      default:
        decisionStatut = 'en_attente';
    }

    // 8. Calculer l application du paiement (plein, partiel, ou en attente)
    const montantRecu = analyse.details.montant || 0;
    const montantDejaPaye = parseFloat(cotisationCible.montant_paye) || 0;
    const montantDu = parseFloat(cotisationCible.montant);

    let statut;
    let nouveauMontantPaye = montantDejaPaye;
    let montantPropose = null;
    let surplus = 0;

    if (decisionStatut === 'rejete') {
      statut = 'rejete';
    } else if (decisionStatut === 'accepte') {
      const cumul = montantDejaPaye + montantRecu;
      if (cumul >= montantDu) {
        statut = 'paye';
        surplus = cumul - montantDu;
        nouveauMontantPaye = montantDu;
      } else {
        statut = 'partiel';
        nouveauMontantPaye = cumul;
      }
    } else {
      statut = 'en_attente';
      montantPropose = montantRecu;
    }

    const datePaiementValue = statut === 'paye' ? new Date() : null;

    const { rows: [cotisation] } = await client.query(
      `UPDATE cotisations SET
        statut = $1,
        montant_paye = $2,
        montant_propose = $3,
        capture_url = $4,
        capture_hash = $5,
        methode_paiement = $6,
        reference_transaction = $7,
        operateur_detecte = $8,
        score_ia = $9,
        decision_ia = $10,
        alertes_ia = $11,
        texte_ocr = $12,
        notes = $13,
        date_paiement = $14
       WHERE id = $15
       RETURNING *`,
      [
        statut,
        nouveauMontantPaye,
        montantPropose,
        uploadResult.secure_url,
        imageHash,
        methode_paiement || analyse.operateur,
        analyse.details.reference || null,
        analyse.operateur,
        analyse.scoreConfiance,
        analyse.decision,
        JSON.stringify(analyse.alertes),
        texteOCR,
        notes || null,
        datePaiementValue,
        cotisationCible.id,
      ]
    );

    // 9. Si accepté (paye ou partiel) → appliquer au solde immédiatement
    let surplusNonAffecte = 0;
    if (decisionStatut === 'accepte' && (statut === 'paye' || statut === 'partiel')) {
      const montantAppliqueCettePeriode = statut === 'paye'
        ? (montantDu - montantDejaPaye)
        : montantRecu;

      // FIX: RETURNING id pour propager compte_virtuel_id + utilisateur_id
      // sur transactions_virtuelles (voir explication dans appliquerSurplus).
      const { rows: [compteVirtuel] } = await client.query(
        `INSERT INTO comptes_virtuels (tontine_id, solde, total_depots)
         VALUES ($1, $2, $2)
         ON CONFLICT (tontine_id)
         DO UPDATE SET solde = comptes_virtuels.solde + $2,
                       total_depots = COALESCE(comptes_virtuels.total_depots, 0) + $2,
                       updated_at = NOW()
         RETURNING id`,
        [tontine_id, montantAppliqueCettePeriode]
      );

      await client.query(
        `INSERT INTO transactions_virtuelles (
          tontine_id, compte_virtuel_id, type, montant, membre_id, utilisateur_id,
          cotisation_id, description, solde_avant, solde_apres
        )
        SELECT $1, $2, 'depot', $3, $4, $5, $6, $7,
               COALESCE(solde, 0) - $3,
               COALESCE(solde, 0)
        FROM comptes_virtuels WHERE tontine_id = $1`,
        [
          tontine_id,
          compteVirtuel.id,
          montantAppliqueCettePeriode,
          userId,
          userId,
          cotisation.id,
          `Cotisation ${membre.prenom} ${membre.nom_membre} - ${analyse.operateur}` +
            (statut === 'partiel' ? ' (paiement partiel)' : '')
        ]
      );

      await client.query(
        `UPDATE utilisateurs
         SET score_fiabilite = LEAST(100, score_fiabilite + 2)
         WHERE id = $1`,
        [userId]
      );

      if (surplus > 0) {
        surplusNonAffecte = await appliquerSurplus(
          client, tontine_id, userId,
          { prenom: membre.prenom, nom_membre: membre.nom_membre },
          surplus, cotisationCible.periode_numero
        );
      }
    }

    // 10. Notifier organisateur et membres
    const { rows: membres } = await client.query(
      `SELECT u.id, u.prenom FROM membres_tontine mt
       JOIN utilisateurs u ON u.id = mt.utilisateur_id
       WHERE mt.tontine_id = $1 AND mt.est_actif = true`,
      [tontine_id]
    );

    const { rows: [tontine] } = await client.query(
      'SELECT responsable_id, nom FROM tontines WHERE id = $1',
      [tontine_id]
    );

    const montantRestantApres = Math.max(0, montantDu - nouveauMontantPaye);

    const messageNotif = statut === 'paye'
      ? `✅ Cotisation de ${membre.prenom} validée automatiquement (${analyse.scoreConfiance}% confiance)` +
        (surplus > 0 ? ` — surplus de ${surplus} F reporté sur la suite` : '')
      : statut === 'partiel'
      ? `⏳ Paiement partiel de ${membre.prenom} validé (${montantRecu} F). Reste dû: ${montantRestantApres} F`
      : statut === 'en_attente'
      ? `⏳ Cotisation de ${membre.prenom} en attente de validation (${analyse.scoreConfiance}% confiance)`
      : `❌ Cotisation de ${membre.prenom} rejetée (${analyse.scoreConfiance}% confiance)`;

    await client.query(
      `INSERT INTO notifications (utilisateur_id, tontine_id, type, titre, message, canal)
       VALUES ($1, $2, 'cotisation', 'Nouvelle cotisation', $3, 'push')`,
      [tontine.responsable_id, tontine_id, messageNotif]
    );

    if (statut === 'paye' || statut === 'partiel') {
      for (const m of membres) {
        if (m.id !== userId) {
          await client.query(
            `INSERT INTO notifications (utilisateur_id, tontine_id, type, titre, message, canal)
             VALUES ($1, $2, 'transaction', 'Transaction validée', $3, 'push')`,
            [m.id, tontine_id,
             `${membre.prenom} a payé ${statut === 'partiel' ? 'une partie de' : ''} sa cotisation pour "${tontine.nom}"`]
          );
        }
      }
    }

    await client.query('COMMIT');

    const io = req.app.get('io');
    if (io) {
      io.to(`tontine_${tontine_id}`).emit('nouvelle_cotisation', {
        cotisation,
        analyse,
        membre: { prenom: membre.prenom, nom: membre.nom_membre },
      });
    }

    let messagePrincipal;
    if (statut === 'paye') {
      messagePrincipal = surplus > 0
        ? `✅ Cotisation validée ! Surplus de ${surplus} F ${surplusNonAffecte > 0 ? `(dont ${surplusNonAffecte} F non affecté, aucune échéance restante)` : 'appliqué à la suite'}.`
        : '✅ Cotisation validée automatiquement !';
    } else if (statut === 'partiel') {
      messagePrincipal = `⏳ Paiement partiel enregistré : ${montantRecu} F reçus. Il vous reste ${montantRestantApres} F à payer pour cette échéance.`;
    } else if (statut === 'en_attente') {
      messagePrincipal = '⏳ Cotisation soumise — en attente de validation par l organisateur';
    } else {
      messagePrincipal = '❌ Cotisation rejetée — veuillez soumettre une nouvelle capture';
    }

    res.json({
      success: true,
      cotisation,
      analyse: {
        operateur: analyse.operateur,
        scoreConfiance: analyse.scoreConfiance,
        decision: analyse.decision,
        statut,
        alertes: analyse.alertes,
        details: analyse.details,
      },
      montantRestant: montantRestantApres,
      surplus,
      surplusNonAffecte,
      message: messagePrincipal,
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Erreur soumission cotisation:', err);
    res.status(500).json({ error: err.message });
  } finally {
    client.release();
  }
});

// ── HISTORIQUE TRANSACTIONS TONTINE ───────────────────
router.get('/tontine/:tontineId/transactions', async (req, res) => {
  try {
    const { tontineId } = req.params;
    const userId = req.user.id;

    const { rows: [acces] } = await pool.query(
      `SELECT 1 FROM membres_tontine
       WHERE tontine_id = $1 AND utilisateur_id = $2 AND est_actif = true
       UNION
       SELECT 1 FROM tontines
       WHERE id = $1 AND responsable_id = $2`,
      [tontineId, userId]
    );

    if (!acces) {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    const { rows: transactions } = await pool.query(
      `SELECT tv.*, u.prenom, u.nom,
              c.capture_url, c.score_ia, c.decision_ia,
              c.operateur_detecte, c.reference_transaction
       FROM transactions_virtuelles tv
       LEFT JOIN utilisateurs u ON u.id = tv.membre_id
       LEFT JOIN cotisations c ON c.id = tv.cotisation_id
       WHERE tv.tontine_id = $1
       ORDER BY tv.created_at DESC
       LIMIT 100`,
      [tontineId]
    );

    const { rows: [compte] } = await pool.query(
      'SELECT solde, total_depots, total_retraits FROM comptes_virtuels WHERE tontine_id = $1',
      [tontineId]
    );

    res.json({
      success: true,
      solde: compte?.solde || 0,
      totalDepots: compte?.total_depots || 0,
      totalRetraits: compte?.total_retraits || 0,
      transactions,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── VALIDER MANUELLEMENT UNE COTISATION ───────────────
router.post('/cotisations/:id/valider', async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { id } = req.params;
    const userId = req.user.id;

    const { rows: [cot] } = await client.query(
      `SELECT c.*, t.responsable_id, t.nom as tontine_nom,
              u.prenom, u.nom as nom_membre
       FROM cotisations c
       JOIN tontines t ON t.id = c.tontine_id
       JOIN utilisateurs u ON u.id = c.membre_id
       WHERE c.id = $1`,
      [id]
    );

    if (!cot) return res.status(404).json({ error: 'Cotisation non trouvée' });
    if (cot.responsable_id !== userId) {
      return res.status(403).json({ error: 'Seul l organisateur peut valider' });
    }
    if (cot.statut !== 'en_attente' || cot.montant_propose === null) {
      return res.status(400).json({ error: 'Cette cotisation ne peut pas être validée (aucun paiement en attente)' });
    }

    const montantDu = parseFloat(cot.montant);
    const dejaPaye = parseFloat(cot.montant_paye) || 0;
    const propose = parseFloat(cot.montant_propose);
    const cumul = dejaPaye + propose;
    const nouveauStatut = cumul >= montantDu ? 'paye' : 'partiel';
    const montantApplique = Math.min(cumul, montantDu);
    const montantAAppliquerMaintenant = montantApplique - dejaPaye;
    const surplus = Math.max(0, cumul - montantDu);

    await client.query(
      `UPDATE cotisations SET statut = $1, montant_paye = $2, montant_propose = NULL,
       date_paiement = CASE WHEN $1 = 'paye' THEN NOW() ELSE date_paiement END,
       valide_par = $3, date_validation = NOW()
       WHERE id = $4`,
      [nouveauStatut, montantApplique, userId, id]
    );

    // FIX: même ajout de compte_virtuel_id/utilisateur_id qu ailleurs.
    const { rows: [compteVirtuel] } = await client.query(
      `INSERT INTO comptes_virtuels (tontine_id, solde, total_depots)
       VALUES ($1, $2, $2)
       ON CONFLICT (tontine_id)
       DO UPDATE SET solde = comptes_virtuels.solde + $2,
                     total_depots = COALESCE(comptes_virtuels.total_depots, 0) + $2,
                     updated_at = NOW()
       RETURNING id`,
      [cot.tontine_id, montantAAppliquerMaintenant]
    );

    await client.query(
      `INSERT INTO transactions_virtuelles (
        tontine_id, compte_virtuel_id, type, montant, membre_id, utilisateur_id,
        cotisation_id, description
      ) VALUES ($1, $2, 'depot', $3, $4, $5, $6, $7)`,
      [cot.tontine_id, compteVirtuel.id, montantAAppliquerMaintenant, cot.membre_id, cot.membre_id, id,
       `Cotisation validée manuellement - ${cot.prenom} ${cot.nom_membre}` +
         (nouveauStatut === 'partiel' ? ' (partiel)' : '')]
    );

    await client.query(
      `UPDATE utilisateurs SET score_fiabilite = LEAST(100, score_fiabilite + 2)
       WHERE id = $1`,
      [cot.membre_id]
    );

    let surplusNonAffecte = 0;
    if (surplus > 0) {
      surplusNonAffecte = await appliquerSurplus(
        client, cot.tontine_id, cot.membre_id,
        { prenom: cot.prenom, nom_membre: cot.nom_membre },
        surplus, cot.periode_numero
      );
    }

    const montantRestant = Math.max(0, montantDu - montantApplique);
    const messageMembre = nouveauStatut === 'paye'
      ? `✅ Votre cotisation de ${montantApplique} F a été validée pour "${cot.tontine_nom}"` +
        (surplus > 0 ? ` (surplus de ${surplus} F reporté sur la prochaine échéance)` : '')
      : `✅ Paiement partiel de ${propose} F validé pour "${cot.tontine_nom}". Reste à payer: ${montantRestant} F`;

    await client.query(
      `INSERT INTO notifications (utilisateur_id, tontine_id, type, titre, message, canal)
       VALUES ($1, $2, 'cotisation', 'Cotisation validée', $3, 'push')`,
      [cot.membre_id, cot.tontine_id, messageMembre]
    );

    await client.query('COMMIT');

    const io = req.app.get('io');
    if (io) {
      io.to(`tontine_${cot.tontine_id}`).emit('cotisation_validee', { cotisationId: id, statut: nouveauStatut });
    }

    res.json({
      success: true,
      message: messageMembre,
      statut: nouveauStatut,
      montantRestant,
      surplus,
      surplusNonAffecte,
    });
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(500).json({ error: err.message });
  } finally {
    client.release();
  }
});

// ── REJETER UNE COTISATION ────────────────────────────
router.post('/cotisations/:id/rejeter', async (req, res) => {
  try {
    const { id } = req.params;
    const { motif } = req.body;
    const userId = req.user.id;

    const { rows: [cot] } = await pool.query(
      `SELECT c.*, t.responsable_id, u.prenom
       FROM cotisations c
       JOIN tontines t ON t.id = c.tontine_id
       JOIN utilisateurs u ON u.id = c.membre_id
       WHERE c.id = $1`,
      [id]
    );

    if (!cot) return res.status(404).json({ error: 'Non trouvée' });
    if (cot.responsable_id !== userId) {
      return res.status(403).json({ error: 'Non autorisé' });
    }

    const dejaPaye = parseFloat(cot.montant_paye) || 0;
    const statutApresRejet = dejaPaye > 0 ? 'partiel' : 'rejete';

    await pool.query(
      `UPDATE cotisations SET statut = $1, montant_propose = NULL, motif_rejet = $2,
       valide_par = $3, date_validation = NOW()
       WHERE id = $4`,
      [statutApresRejet, motif || 'Capture invalide', userId, id]
    );

    await pool.query(
      `INSERT INTO notifications (utilisateur_id, tontine_id, type, titre, message, canal)
       VALUES ($1, $2, 'cotisation', 'Cotisation rejetée', $3, 'push')`,
      [cot.membre_id, cot.tontine_id,
       `❌ Votre cotisation a été rejetée. Motif: ${motif || 'Capture invalide'}. Veuillez soumettre à nouveau.` +
         (dejaPaye > 0 ? ` (${dejaPaye} F déjà validés restent acquis)` : '')]
    );

    await pool.query(
      `UPDATE utilisateurs SET score_fiabilite = GREATEST(0, score_fiabilite - 5)
       WHERE id = $1`,
      [cot.membre_id]
    );

    res.json({ success: true, message: 'Cotisation rejetée', statut: statutApresRejet });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── VUE ADMIN - TOUTES LES TRANSACTIONS ───────────────
router.get('/admin/transactions', async (req, res) => {
  try {
    const userId = req.user.id;

    // FIX: est_admin n'existe pas comme colonne — utiliser role = 'admin'.
    const { rows: [user] } = await pool.query(
      'SELECT role FROM utilisateurs WHERE id = $1',
      [userId]
    );

    if (user?.role !== 'admin') {
      return res.status(403).json({ error: 'Accès admin requis' });
    }

    const { page = 1, limit = 50, statut, tontine_id } = req.query;
    const offset = (page - 1) * limit;

    let whereClause = '';
    const params = [];
    if (statut) { params.push(statut); whereClause += ` AND c.statut = $${params.length}`; }
    if (tontine_id) { params.push(tontine_id); whereClause += ` AND c.tontine_id = $${params.length}`; }

    params.push(limit, offset);

    const { rows } = await pool.query(
      `SELECT c.*,
              u.prenom, u.nom, u.telephone,
              t.nom as tontine_nom,
              org.prenom as organisateur_prenom,
              org.nom as organisateur_nom
       FROM cotisations c
       JOIN utilisateurs u ON u.id = c.membre_id
       JOIN tontines t ON t.id = c.tontine_id
       JOIN utilisateurs org ON org.id = t.responsable_id
       WHERE 1=1 ${whereClause}
       ORDER BY c.created_at DESC
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );

    const { rows: [stats] } = await pool.query(
      `SELECT
        COUNT(*) FILTER (WHERE statut = 'paye') as total_valides,
        COUNT(*) FILTER (WHERE statut = 'partiel') as total_partiels,
        COUNT(*) FILTER (WHERE statut = 'en_attente') as total_attente,
        COUNT(*) FILTER (WHERE statut = 'rejete') as total_rejetes,
        COALESCE(SUM(montant_paye) FILTER (WHERE statut IN ('paye', 'partiel')), 0) as volume_total,
        AVG(score_ia) FILTER (WHERE score_ia IS NOT NULL) as score_ia_moyen
       FROM cotisations`
    );

    res.json({ success: true, cotisations: rows, stats });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;