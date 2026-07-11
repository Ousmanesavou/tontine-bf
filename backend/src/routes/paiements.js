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
    // FIX: t.numero_mobile_money n'existe pas sur la table tontines.
    // Le numéro mobile money appartient à l'organisateur (utilisateurs),
    // référencé via tontines.responsable_id. On joint donc utilisateurs
    // une seconde fois (alias org) et on prend Orange Money en priorité,
    // sinon Moov Money.
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

    // 2. Vérifier pas de cotisation déjà en attente
    const { rows: [cotExistante] } = await client.query(
      `SELECT id FROM cotisations
       WHERE tontine_id = $1 AND membre_id = $2
       AND statut IN ('en_attente', 'paye')
       AND EXTRACT(MONTH FROM date_echeance) = EXTRACT(MONTH FROM NOW())
       AND EXTRACT(YEAR FROM date_echeance) = EXTRACT(YEAR FROM NOW())`,
      [tontine_id, userId]
    );

    if (cotExistante) {
      return res.status(400).json({
        error: 'Vous avez déjà soumis une cotisation ce mois-ci'
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
    const texteOCR = await CaptureAnalyseService.simulerOCR(uploadResult.secure_url);
    const analyse = CaptureAnalyseService.analyserTexte(texteOCR, {
      montantAttendu: parseFloat(montant) || membre.montant_cotisation,
      numeroOrganisateur: membre.numero_mobile_money,
    });

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

    // 7. Déterminer statut selon score IA
    let statut;
    switch (analyse.decision) {
      case 'AUTO_VALIDE':
        statut = 'paye';
        break;
      case 'VALIDATION_MANUELLE':
        statut = 'en_attente';
        break;
      case 'REJETE':
        statut = 'rejete';
        break;
      default:
        statut = 'en_attente';
    }

    // 8. Enregistrer la cotisation
    const { rows: [cotisation] } = await client.query(
      `INSERT INTO cotisations (
        tontine_id, membre_id, montant, statut,
        capture_url, capture_hash, methode_paiement,
        reference_transaction, operateur_detecte,
        score_ia, decision_ia, alertes_ia,
        texte_ocr, notes, date_echeance, date_paiement
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14,
                DATE_TRUNC('month', NOW()) + INTERVAL '1 month' - INTERVAL '1 day',
                CASE WHEN $4::text = 'paye' THEN NOW() ELSE NULL END)
      RETURNING *`,
      [
        tontine_id,
        userId,
        parseFloat(montant) || membre.montant_cotisation,
        statut,
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
      ]
    );

    // 9. Si validé auto → mettre à jour solde virtuel
    if (statut === 'paye') {
      await client.query(
        `INSERT INTO comptes_virtuels (tontine_id, solde)
         VALUES ($1, $2)
         ON CONFLICT (tontine_id)
         DO UPDATE SET solde = comptes_virtuels.solde + $2,
                       updated_at = NOW()`,
        [tontine_id, cotisation.montant]
      );

      // Enregistrer transaction
      await client.query(
        `INSERT INTO transactions_virtuelles (
          tontine_id, type, montant, membre_id,
          cotisation_id, description, solde_avant, solde_apres
        )
        SELECT $1, 'entree', $2, $3, $4, $5,
               COALESCE(solde, 0) - $2,
               COALESCE(solde, 0)
        FROM comptes_virtuels WHERE tontine_id = $1`,
        [
          tontine_id,
          cotisation.montant,
          userId,
          cotisation.id,
          `Cotisation ${membre.prenom} ${membre.nom_membre} - ${analyse.operateur}`
        ]
      );

      // Mettre à jour score fiabilité
      await client.query(
        `UPDATE utilisateurs
         SET score_fiabilite = LEAST(100, score_fiabilite + 2)
         WHERE id = $1`,
        [userId]
      );
    }

    // 10. Notifier organisateur et membres
    const { rows: membres } = await client.query(
      `SELECT u.id, u.prenom FROM membres_tontine mt
       JOIN utilisateurs u ON u.id = mt.utilisateur_id
       WHERE mt.tontine_id = $1 AND mt.est_actif = true`,
      [tontine_id]
    );

    // Notification organisateur
    const { rows: [tontine] } = await client.query(
      'SELECT responsable_id, nom FROM tontines WHERE id = $1',
      [tontine_id]
    );

    const messageNotif = statut === 'paye'
      ? `✅ Cotisation de ${membre.prenom} validée automatiquement (${analyse.scoreConfiance}% confiance)`
      : statut === 'en_attente'
      ? `⏳ Cotisation de ${membre.prenom} en attente de validation (${analyse.scoreConfiance}% confiance)`
      : `❌ Cotisation de ${membre.prenom} rejetée (${analyse.scoreConfiance}% confiance)`;

    await client.query(
      `INSERT INTO notifications (utilisateur_id, tontine_id, type, titre, message, canal)
       VALUES ($1, $2, 'cotisation', 'Nouvelle cotisation', $3, 'push')`,
      [tontine.responsable_id, tontine_id, messageNotif]
    );

    // Notifier tous les membres si validé
    if (statut === 'paye') {
      for (const m of membres) {
        if (m.id !== userId) {
          await client.query(
            `INSERT INTO notifications (utilisateur_id, tontine_id, type, titre, message, canal)
             VALUES ($1, $2, 'transaction', 'Transaction validée', $3, 'push')`,
            [m.id, tontine_id,
             `${membre.prenom} a payé sa cotisation pour "${tontine.nom}"`]
          );
        }
      }
    }

    await client.query('COMMIT');

    // Émettre via Socket.io
    const io = req.app.get('io');
    if (io) {
      io.to(`tontine_${tontine_id}`).emit('nouvelle_cotisation', {
        cotisation,
        analyse,
        membre: { prenom: membre.prenom, nom: membre.nom_membre },
      });
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
      message: statut === 'paye'
        ? '✅ Cotisation validée automatiquement !'
        : statut === 'en_attente'
        ? '⏳ Cotisation soumise — en attente de validation par l organisateur'
        : '❌ Cotisation rejetée — veuillez soumettre une nouvelle capture',
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

    // Vérifier membre ou organisateur
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

    // Récupérer toutes les transactions
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

    // Solde actuel
    const { rows: [compte] } = await pool.query(
      'SELECT solde FROM comptes_virtuels WHERE tontine_id = $1',
      [tontineId]
    );

    res.json({
      success: true,
      solde: compte?.solde || 0,
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

    // Vérifier que c est l organisateur
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
    if (cot.statut !== 'en_attente') {
      return res.status(400).json({ error: 'Cette cotisation ne peut pas être validée' });
    }

    // Valider
    await client.query(
      `UPDATE cotisations SET statut = 'paye', date_paiement = NOW(),
       valide_par = $1, date_validation = NOW()
       WHERE id = $2`,
      [userId, id]
    );

    // Mettre à jour solde virtuel
    await client.query(
      `INSERT INTO comptes_virtuels (tontine_id, solde)
       VALUES ($1, $2)
       ON CONFLICT (tontine_id)
       DO UPDATE SET solde = comptes_virtuels.solde + $2, updated_at = NOW()`,
      [cot.tontine_id, cot.montant]
    );

    // Enregistrer transaction
    await client.query(
      `INSERT INTO transactions_virtuelles (
        tontine_id, type, montant, membre_id, cotisation_id, description
      ) VALUES ($1, 'entree', $2, $3, $4, $5)`,
      [cot.tontine_id, cot.montant, cot.membre_id, id,
       `Cotisation validée manuellement - ${cot.prenom} ${cot.nom_membre}`]
    );

    // Mettre à jour score fiabilité membre
    await client.query(
      `UPDATE utilisateurs SET score_fiabilite = LEAST(100, score_fiabilite + 2)
       WHERE id = $1`,
      [cot.membre_id]
    );

    // Notifier le membre
    await client.query(
      `INSERT INTO notifications (utilisateur_id, tontine_id, type, titre, message, canal)
       VALUES ($1, $2, 'cotisation', 'Cotisation validée', $3, 'push')`,
      [cot.membre_id, cot.tontine_id,
       `✅ Votre cotisation de ${cot.montant} F a été validée pour "${cot.tontine_nom}"`]
    );

    await client.query('COMMIT');

    // Émettre Socket.io
    const io = req.app.get('io');
    if (io) {
      io.to(`tontine_${cot.tontine_id}`).emit('cotisation_validee', { cotisationId: id });
    }

    res.json({ success: true, message: 'Cotisation validée avec succès' });
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

    await pool.query(
      `UPDATE cotisations SET statut = 'rejete', motif_rejet = $1,
       valide_par = $2, date_validation = NOW()
       WHERE id = $3`,
      [motif || 'Capture invalide', userId, id]
    );

    // Notifier membre
    await pool.query(
      `INSERT INTO notifications (utilisateur_id, tontine_id, type, titre, message, canal)
       VALUES ($1, $2, 'cotisation', 'Cotisation rejetée', $3, 'push')`,
      [cot.membre_id, cot.tontine_id,
       `❌ Votre cotisation a été rejetée. Motif: ${motif || 'Capture invalide'}. Veuillez soumettre à nouveau.`]
    );

    // Décrémenter score fiabilité
    await pool.query(
      `UPDATE utilisateurs SET score_fiabilite = GREATEST(0, score_fiabilite - 5)
       WHERE id = $1`,
      [cot.membre_id]
    );

    res.json({ success: true, message: 'Cotisation rejetée' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── VUE ADMIN - TOUTES LES TRANSACTIONS ───────────────
router.get('/admin/transactions', async (req, res) => {
  try {
    const userId = req.user.id;

    // Vérifier que c est admin
    const { rows: [user] } = await pool.query(
      'SELECT est_admin FROM utilisateurs WHERE id = $1',
      [userId]
    );

    if (!user?.est_admin) {
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

    // Stats globales
    const { rows: [stats] } = await pool.query(
      `SELECT
        COUNT(*) FILTER (WHERE statut = 'paye') as total_valides,
        COUNT(*) FILTER (WHERE statut = 'en_attente') as total_attente,
        COUNT(*) FILTER (WHERE statut = 'rejete') as total_rejetes,
        COALESCE(SUM(montant) FILTER (WHERE statut = 'paye'), 0) as volume_total,
        AVG(score_ia) FILTER (WHERE score_ia IS NOT NULL) as score_ia_moyen
       FROM cotisations`
    );

    res.json({ success: true, cotisations: rows, stats });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;