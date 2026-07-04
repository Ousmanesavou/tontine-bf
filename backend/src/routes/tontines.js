const express = require('express');
const router = express.Router();
const tontineController = require('../controllers/tontineController');
const { authenticate } = require('../middleware/auth');
const { validateTontine } = require('../middleware/validation');
const { pool } = require('../../config/database');
const notificationService = require('../services/notificationService');

router.use(authenticate);

// ── ROUTES SPÉCIFIQUES AVANT /:id ──────────────────────
router.get('/publiques', tontineController.getTontinesPubliques);
router.get('/adhesions/mes-demandes', tontineController.getMesDemandes);

// ── TONTINES STANDARD ──────────────────────────────────
router.get('/', tontineController.getMesTontines);
router.post('/', validateTontine, tontineController.creerTontine);
router.get('/:id', tontineController.getTontine);
router.put('/:id', tontineController.modifierTontine);
router.delete('/:id', tontineController.supprimerTontine);

// ── MEMBRES ────────────────────────────────────────────
router.get('/:id/membres', tontineController.getMembres);
router.post('/:id/membres/inviter', tontineController.inviterMembre);
router.post('/:id/membres/rejoindre', tontineController.rejoindreTontine);
router.delete('/:id/membres/:membreId', tontineController.retirerMembre);

// ── ADHÉSIONS ──────────────────────────────────────────
router.post('/:id/demander-adhesion', tontineController.demanderAdhesion);
router.put('/adhesions/:adhesionId/accepter', tontineController.accepterAdhesion);
router.put('/adhesions/:adhesionId/refuser', tontineController.refuserAdhesion);

// ── COTISATIONS & STATS ────────────────────────────────
router.get('/:id/cotisations', tontineController.getCotisations);
router.get('/:id/statistiques', tontineController.getStatistiques);
router.get('/:id/rapport', tontineController.genererRapport);

// ── EMPRUNTS ───────────────────────────────────────────
router.post('/:id/emprunts', tontineController.demanderEmprunt);
router.put('/:id/emprunts/:empruntId/voter', tontineController.voterEmprunt);
router.post('/:id/emprunts/:empruntId/rembourser', tontineController.rembourserEmprunt);

// ── COMPTE VIRTUEL ─────────────────────────────────────
router.get('/:id/compte-virtuel', tontineController.getCompteVirtuel);
router.post('/:id/compte-virtuel/depot', tontineController.effectuerDepot);
router.post('/:id/compte-virtuel/retrait/initier', tontineController.initierRetrait);
router.post('/:id/compte-virtuel/retrait/:retraitId/voter', tontineController.voterRetrait);
router.get('/:id/compte-virtuel/transactions', tontineController.getTransactions);

// ── DASHBOARD ORGANISATEUR ─────────────────────────────
router.get('/:id/dashboard', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    console.log('DASHBOARD REQUEST - tontineId:', id, 'userId:', userId);

    // Vérifier que l'utilisateur est organisateur
    const { rows: [tontine] } = await pool.query(
      'SELECT * FROM tontines WHERE id = $1 AND responsable_id = $2',
      [id, userId]
    );
    if (!tontine) return res.status(403).json({ error: 'Non autorisé' });

    // Membres avec score et jours de retard
    const { rows: membres } = await pool.query(`
      SELECT u.id, u.nom, u.prenom, u.telephone, u.score_fiabilite,
             mt.position_rotation, mt.a_recu, mt.joined_at,
             CASE
               WHEN EXISTS (
                 SELECT 1 FROM cotisations c
                 WHERE c.tontine_id = $1
                 AND c.membre_id = u.id
                 AND c.statut = 'en_retard'
               ) THEN EXTRACT(DAY FROM NOW() - (
                 SELECT MAX(date_echeance) FROM cotisations
                 WHERE tontine_id = $1 AND membre_id = u.id
                 AND statut = 'en_retard'
               ))::int
               ELSE 0
             END as jours_retard,
             COALESCE((
               SELECT COUNT(*) FROM cotisations
               WHERE tontine_id = $1 AND membre_id = u.id
               AND statut = 'paye'
             ), 0) as nb_paiements_ok,
             COALESCE((
               SELECT COUNT(*) FROM cotisations
               WHERE tontine_id = $1 AND membre_id = u.id
               AND statut = 'en_retard'
             ), 0) as nb_retards
      FROM membres_tontine mt
      JOIN utilisateurs u ON u.id = mt.utilisateur_id
      WHERE mt.tontine_id = $1 AND mt.est_actif = true
      ORDER BY mt.position_rotation
    `, [id]);

    // Cotisations période actuelle
    const { rows: cotisations } = await pool.query(`
      SELECT c.*, u.prenom, u.nom, u.telephone
      FROM cotisations c
      JOIN utilisateurs u ON u.id = c.membre_id
      WHERE c.tontine_id = $1
      ORDER BY c.date_echeance DESC
      LIMIT 50
    `, [id]);

    // Demandes d'adhésion en attente
    const { rows: demandes } = await pool.query(`
      SELECT a.*, u.prenom, u.nom, u.telephone, u.score_fiabilite
      FROM adhesions_tontine a
      JOIN utilisateurs u ON u.id = a.demandeur_id
      WHERE a.tontine_id = $1 AND a.statut = 'en_attente'
      ORDER BY a.created_at DESC
    `, [id]);

    // Statistiques globales
    const { rows: [stats] } = await pool.query(`
      SELECT
        COUNT(*) FILTER (WHERE statut = 'paye') as total_payes,
        COUNT(*) FILTER (WHERE statut = 'en_retard') as total_retards,
        COUNT(*) FILTER (WHERE statut = 'en_attente') as total_attente,
        COALESCE(SUM(montant) FILTER (WHERE statut = 'paye'), 0) as montant_collecte,
        COUNT(*) as total_cotisations
      FROM cotisations
      WHERE tontine_id = $1
    `, [id]);

    // Solde compte virtuel
    const { rows: [compte] } = await pool.query(
      'SELECT solde FROM comptes_virtuels WHERE tontine_id = $1',
      [id]
    );

    // Activité récente (dernières 10 actions)
    const { rows: activite } = await pool.query(`
      SELECT c.*, u.prenom, u.nom,
             'cotisation' as type_action
      FROM cotisations c
      JOIN utilisateurs u ON u.id = c.membre_id
      WHERE c.tontine_id = $1
      ORDER BY c.created_at DESC
      LIMIT 10
    `, [id]);

    res.json({
      tontine,
      membres,
      cotisations,
      demandes,
      stats: {
        ...stats,
        solde: compte?.solde || 0,
        taux_paiement: stats.total_cotisations > 0
          ? Math.round((stats.total_payes / stats.total_cotisations) * 100)
          : 0,
      },
      activite,
      derniere_mise_a_jour: new Date().toISOString(),
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// ── ACTIONS ORGANISATEUR ───────────────────────────────

// Relancer un membre
router.post('/:id/membres/:membreId/relancer', async (req, res) => {
  try {
    const { id, membreId } = req.params;
    const userId = req.user.id;

    // Vérifier organisateur
    const { rows: [tontine] } = await pool.query(
      'SELECT nom FROM tontines WHERE id = $1 AND responsable_id = $2',
      [id, userId]
    );
    if (!tontine) return res.status(403).json({ error: 'Non autorisé' });

    // Créer notification de rappel
    await pool.query(`
      INSERT INTO notifications (utilisateur_id, tontine_id, type, titre, message, canal)
      VALUES ($1, $2, 'rappel_cotisation',
              'Rappel de cotisation',
              'L''organisateur vous rappelle de payer votre cotisation pour la tontine ' || $3,
              'push')
    `, [membreId, id, tontine.nom]);

    res.json({ success: true, message: 'Rappel envoyé' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Exclure un membre
router.delete('/:id/membres/:membreId/exclure', async (req, res) => {
  try {
    const { id, membreId } = req.params;
    const userId = req.user.id;

    const { rows: [tontine] } = await pool.query(
      'SELECT nom FROM tontines WHERE id = $1 AND responsable_id = $2',
      [id, userId]
    );
    if (!tontine) return res.status(403).json({ error: 'Non autorisé' });

    await pool.query(
      'UPDATE membres_tontine SET est_actif = false WHERE tontine_id = $1 AND utilisateur_id = $2',
      [id, membreId]
    );

    // Notifier le membre
    await pool.query(`
      INSERT INTO notifications (utilisateur_id, tontine_id, type, titre, message, canal)
      VALUES ($1, $2, 'exclusion',
              'Exclusion de tontine',
              'Vous avez été exclu de la tontine ' || $3,
              'push')
    `, [membreId, id, tontine.nom]);

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Valider paiement manuel
router.post('/:id/cotisations/:cotisationId/valider', async (req, res) => {
  try {
    const { id, cotisationId } = req.params;
    const userId = req.user.id;

    const { rows: [tontine] } = await pool.query(
      'SELECT id FROM tontines WHERE id = $1 AND responsable_id = $2',
      [id, userId]
    );
    if (!tontine) return res.status(403).json({ error: 'Non autorisé' });

    await pool.query(`
      UPDATE cotisations
      SET statut = 'paye', date_paiement = NOW(), methode_paiement = 'manuel_valide'
      WHERE id = $1 AND tontine_id = $2
    `, [cotisationId, id]);

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Demandes adhésion d'une tontine
router.get('/:id/demandes', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const { rows: [tontine] } = await pool.query(
      'SELECT id FROM tontines WHERE id = $1 AND responsable_id = $2',
      [id, userId]
    );
    if (!tontine) return res.status(403).json({ error: 'Non autorisé' });

    const { rows } = await pool.query(`
      SELECT a.*, u.prenom, u.nom, u.telephone, u.score_fiabilite
      FROM adhesions_tontine a
      JOIN utilisateurs u ON u.id = a.demandeur_id
      WHERE a.tontine_id = $1 AND a.statut = 'en_attente'
      ORDER BY a.created_at DESC
    `, [id]);

    res.json({ demandes: rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
