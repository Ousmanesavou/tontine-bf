const express = require('express');
const router = express.Router();
const tontineController = require('../controllers/tontineController');
const { authenticate } = require('../middleware/auth');
const { validateTontine } = require('../middleware/validation');
const { pool } = require('../../config/database');
const notificationService = require('../services/notificationService');

router.use(authenticate);

// ── ROUTES SPÉCIFIQUES EN PREMIER (avant /:id) ────────
// Tontines publiques
router.get('/publiques', async (req, res) => {
  try {
    const { search = '' } = req.query;
    const userId = req.user.id;

    let query = `
      SELECT
        t.*,
        u.prenom as responsable_prenom,
        u.nom as responsable_nom,
        u.telephone as responsable_telephone,
        COALESCE(COUNT(DISTINCT mt.id), 0) as total_membres,
        EXISTS(
          SELECT 1 FROM membres_tontine
          WHERE tontine_id = t.id AND utilisateur_id = $1 AND est_actif = true
        ) as est_membre,
        EXISTS(
          SELECT 1 FROM adhesions_tontine
          WHERE tontine_id = t.id AND utilisateur_id = $1 AND statut = 'en_attente'
        ) as demande_en_attente,
        cv.solde as solde_virtuel
      FROM tontines t
      LEFT JOIN utilisateurs u ON u.id = t.responsable_id
      LEFT JOIN membres_tontine mt ON mt.tontine_id = t.id AND mt.est_actif = true
      LEFT JOIN comptes_virtuels cv ON cv.tontine_id = t.id
      WHERE t.est_public = true AND t.statut = 'actif'
    `;

    const params = [userId];
    if (search) {
      params.push(`%${search}%`);
      query += ` AND (t.nom ILIKE $${params.length} OR u.prenom ILIKE $${params.length})`;
    }
    query += ` GROUP BY t.id, u.prenom, u.nom, u.telephone, cv.solde ORDER BY t.created_at DESC`;

    const { rows } = await pool.query(query, params);
    res.json({ success: true, data: rows });
  } catch (err) {
    console.error('Erreur tontines publiques:', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Mes demandes d'adhésion
router.get('/adhesions/mes-demandes', async (req, res) => {
  try {
    const { rows } = await pool.query(`
      SELECT a.*, t.nom as tontine_nom, t.type as tontine_type
      FROM adhesions_tontine a
      JOIN tontines t ON t.id = a.tontine_id
      WHERE a.utilisateur_id = $1
      ORDER BY a.created_at DESC
    `, [req.user.id]);
    res.json({ success: true, data: rows });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ── ROUTES TONTINES STANDARD ──────────────────────────
router.get('/', tontineController.getMesTontines);
router.post('/', validateTontine, tontineController.creerTontine);
router.get('/:id', tontineController.getTontine);
router.put('/:id', tontineController.modifierTontine);
router.delete('/:id', tontineController.supprimerTontine);

// ── MEMBRES ───────────────────────────────────────────
router.get('/:id/membres', tontineController.getMembres);
router.post('/:id/membres/inviter', tontineController.inviterMembre);
router.post('/:id/membres/rejoindre', tontineController.rejoindreTontine);
router.delete('/:id/membres/:membreId', tontineController.retirerMembre);

// ── ADHÉSIONS ─────────────────────────────────────────
router.post('/:id/demander-adhesion', async (req, res) => {
  try {
    const { id } = req.params;
    const { message = '' } = req.body;
    const userId = req.user.id;

    const { rows: membres } = await pool.query(
      'SELECT id FROM membres_tontine WHERE tontine_id = $1 AND utilisateur_id = $2 AND est_actif = true',
      [id, userId]
    );
    if (membres.length > 0)
      return res.status(400).json({ error: 'Vous êtes déjà membre' });

    const { rows: demandes } = await pool.query(
      'SELECT id FROM adhesions_tontine WHERE tontine_id = $1 AND utilisateur_id = $2 AND statut = \'en_attente\'',
      [id, userId]
    );
    if (demandes.length > 0)
      return res.status(400).json({ error: 'Demande déjà envoyée' });

    await pool.query(
      `INSERT INTO adhesions_tontine (tontine_id, utilisateur_id, message, statut)
       VALUES ($1, $2, $3, 'en_attente')`,
      [id, userId, message]
    );

    // Notifier le responsable
    const { rows: tontine } = await pool.query(
      'SELECT responsable_id, nom FROM tontines WHERE id = $1', [id]
    );
    if (tontine[0]) {
      const { rows: demandeur } = await pool.query(
        'SELECT prenom, nom FROM utilisateurs WHERE id = $1', [userId]
      );
      await notificationService.notifierMembre(tontine[0].responsable_id, {
        type: 'demande_adhesion',
        nom_tontine: tontine[0].nom,
        montant: `${demandeur[0]?.prenom} ${demandeur[0]?.nom}`,
        tontine_id: id,
      });
    }

    res.json({ success: true, message: 'Demande envoyée' });
  } catch (err) {
    console.error('Erreur adhésion:', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

router.put('/adhesions/:adhesionId/accepter', tontineController.accepterAdhesion);
router.put('/adhesions/:adhesionId/refuser', tontineController.refuserAdhesion);

// ── COTISATIONS & STATS ───────────────────────────────
router.get('/:id/cotisations', tontineController.getCotisations);
router.get('/:id/statistiques', tontineController.getStatistiques);
router.get('/:id/rapport', tontineController.genererRapport);

// ── EMPRUNTS ──────────────────────────────────────────
router.post('/:id/emprunts', tontineController.demanderEmprunt);
router.put('/:id/emprunts/:empruntId/voter', tontineController.voterEmprunt);
router.post('/:id/emprunts/:empruntId/rembourser', tontineController.rembourserEmprunt);

// ══════════════════════════════════════════════════════
// ── COMPTE VIRTUEL ────────────────────────────────────
// ══════════════════════════════════════════════════════

// Obtenir le compte virtuel d'une tontine
router.get('/:id/compte-virtuel', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Vérifier que l'utilisateur est membre
    const { rows: membre } = await pool.query(
      'SELECT id FROM membres_tontine WHERE tontine_id = $1 AND utilisateur_id = $2 AND est_actif = true',
      [id, userId]
    );
    if (membre.length === 0)
      return res.status(403).json({ error: 'Accès refusé' });

    const { rows } = await pool.query(`
      SELECT cv.*,
        t.nom as tontine_nom,
        t.date_fin,
        t.statut as tontine_statut,
        t.responsable_id,
        (SELECT COUNT(*) FROM votes_retrait WHERE compte_virtuel_id = cv.id AND vote = 'oui') as votes_oui,
        (SELECT COUNT(*) FROM votes_retrait WHERE compte_virtuel_id = cv.id) as total_votes,
        (SELECT COUNT(*) FROM membres_tontine WHERE tontine_id = $1 AND est_actif = true) as nb_membres
      FROM comptes_virtuels cv
      JOIN tontines t ON t.id = cv.tontine_id
      WHERE cv.tontine_id = $1
    `, [id]);

    if (rows.length === 0)
      return res.status(404).json({ error: 'Compte virtuel non trouvé' });

    // Transactions récentes
    const { rows: transactions } = await pool.query(`
      SELECT tv.*, u.prenom, u.nom
      FROM transactions_virtuelles tv
      LEFT JOIN utilisateurs u ON u.id = tv.utilisateur_id
      WHERE tv.compte_virtuel_id = $1
      ORDER BY tv.created_at DESC
      LIMIT 20
    `, [rows[0].id]);

    res.json({
      success: true,
      data: { ...rows[0], transactions }
    });
  } catch (err) {
    console.error('Erreur compte virtuel:', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Dépôt dans le compte virtuel
router.post('/:id/compte-virtuel/depot', async (req, res) => {
  try {
    const { id } = req.params;
    const { montant, methode_paiement, telephone_paiement, reference_externe } = req.body;
    const userId = req.user.id;

    if (!montant || montant <= 0)
      return res.status(400).json({ error: 'Montant invalide' });

    // Vérifier membre actif
    const { rows: membre } = await pool.query(
      'SELECT id FROM membres_tontine WHERE tontine_id = $1 AND utilisateur_id = $2 AND est_actif = true',
      [id, userId]
    );
    if (membre.length === 0)
      return res.status(403).json({ error: 'Vous n\'êtes pas membre de cette tontine' });

    // Récupérer le compte virtuel
    const { rows: cv } = await pool.query(
      'SELECT id, solde FROM comptes_virtuels WHERE tontine_id = $1',
      [id]
    );
    if (cv.length === 0)
      return res.status(404).json({ error: 'Compte virtuel non trouvé' });

    const cvId = cv[0].id;

    // Enregistrer la transaction
    const { rows: transaction } = await pool.query(`
      INSERT INTO transactions_virtuelles
        (compte_virtuel_id, utilisateur_id, type, montant, methode_paiement,
         telephone_paiement, reference_externe, statut, description)
      VALUES ($1, $2, 'depot', $3, $4, $5, $6, 'confirme', 'Dépôt cotisation')
      RETURNING *
    `, [cvId, userId, montant, methode_paiement, telephone_paiement, reference_externe || null]);

    // Mettre à jour le solde
    await pool.query(
      'UPDATE comptes_virtuels SET solde = solde + $1, total_depots = total_depots + $1 WHERE id = $2',
      [montant, cvId]
    );

    // Mettre à jour la cotisation correspondante
    await pool.query(`
      UPDATE cotisations SET statut = 'paye', date_paiement = NOW(),
        methode_paiement = $1
      WHERE tontine_id = $2 AND utilisateur_id = $3 AND statut = 'en_attente'
      ORDER BY date_echeance ASC LIMIT 1
    `, [methode_paiement, id, userId]);

    // Notifier tous les membres
    const { rows: tontine } = await pool.query(
      'SELECT nom FROM tontines WHERE id = $1', [id]
    );
    const { rows: user } = await pool.query(
      'SELECT prenom FROM utilisateurs WHERE id = $1', [userId]
    );
    await notificationService.notifierGroupeTontine(id, {
      type: 'paiement_confirme',
      nom_tontine: tontine[0]?.nom,
      montant: montant.toString(),
      tontine_id: id,
    });

    res.json({
      success: true,
      message: 'Dépôt enregistré avec succès',
      data: transaction[0]
    });
  } catch (err) {
    console.error('Erreur dépôt:', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Initier un retrait (créateur seulement)
router.post('/:id/compte-virtuel/retrait/initier', async (req, res) => {
  try {
    const { id } = req.params;
    const { montant, methode_retrait, telephone_retrait, motif } = req.body;
    const userId = req.user.id;

    // Vérifier que c'est le créateur
    const { rows: tontine } = await pool.query(
      'SELECT * FROM tontines WHERE id = $1', [id]
    );
    if (tontine.length === 0)
      return res.status(404).json({ error: 'Tontine non trouvée' });

    if (tontine[0].responsable_id !== userId)
      return res.status(403).json({ error: 'Seul le créateur peut initier un retrait' });

    // Vérifier que la période est terminée
    const maintenant = new Date();
    const dateFin = new Date(tontine[0].date_fin);
    if (maintenant < dateFin)
      return res.status(400).json({
        error: `Retrait impossible. La période se termine le ${dateFin.toLocaleDateString()}`
      });

    // Récupérer le compte virtuel
    const { rows: cv } = await pool.query(
      'SELECT * FROM comptes_virtuels WHERE tontine_id = $1', [id]
    );
    if (cv.length === 0)
      return res.status(404).json({ error: 'Compte virtuel non trouvé' });

    if (cv[0].solde < montant)
      return res.status(400).json({ error: 'Solde insuffisant' });

    // Créer la demande de retrait
    const { rows: retrait } = await pool.query(`
      INSERT INTO transactions_virtuelles
        (compte_virtuel_id, utilisateur_id, type, montant, methode_paiement,
         telephone_paiement, statut, description)
      VALUES ($1, $2, 'retrait', $3, $4, $5, 'en_attente_vote', $6)
      RETURNING *
    `, [cv[0].id, userId, montant, methode_retrait, telephone_retrait,
        motif || 'Retrait fin de période']);

    // Notifier tous les membres pour voter
    await notificationService.notifierGroupeTontine(id, {
      type: 'vote_retrait',
      nom_tontine: tontine[0].nom,
      montant: montant.toString(),
      tontine_id: id,
    });

    res.json({
      success: true,
      message: 'Demande de retrait créée. En attente des votes des membres.',
      data: retrait[0]
    });
  } catch (err) {
    console.error('Erreur retrait:', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Voter pour un retrait
router.post('/:id/compte-virtuel/retrait/:retraitId/voter', async (req, res) => {
  try {
    const { id, retraitId } = req.params;
    const { vote } = req.body; // 'oui' ou 'non'
    const userId = req.user.id;

    // Vérifier membre
    const { rows: membre } = await pool.query(
      'SELECT id FROM membres_tontine WHERE tontine_id = $1 AND utilisateur_id = $2 AND est_actif = true',
      [id, userId]
    );
    if (membre.length === 0)
      return res.status(403).json({ error: 'Accès refusé' });

    // Récupérer la transaction
    const { rows: retrait } = await pool.query(
      'SELECT * FROM transactions_virtuelles WHERE id = $1 AND statut = \'en_attente_vote\'',
      [retraitId]
    );
    if (retrait.length === 0)
      return res.status(404).json({ error: 'Demande de retrait non trouvée' });

    // Vérifier si déjà voté
    const { rows: dejaVote } = await pool.query(
      'SELECT id FROM votes_retrait WHERE transaction_id = $1 AND utilisateur_id = $2',
      [retraitId, userId]
    );
    if (dejaVote.length > 0)
      return res.status(400).json({ error: 'Vous avez déjà voté' });

    // Enregistrer le vote
    await pool.query(
      'INSERT INTO votes_retrait (transaction_id, compte_virtuel_id, utilisateur_id, vote) VALUES ($1, $2, $3, $4)',
      [retraitId, retrait[0].compte_virtuel_id, userId, vote]
    );

    // Vérifier si tous les membres ont voté OUI
    const { rows: stats } = await pool.query(`
      SELECT
        COUNT(*) FILTER (WHERE vote = 'oui') as votes_oui,
        COUNT(*) as total_votes,
        (SELECT COUNT(*) FROM membres_tontine WHERE tontine_id = $1 AND est_actif = true) as nb_membres
      FROM votes_retrait WHERE transaction_id = $2
    `, [id, retraitId]);

    const { votes_oui, total_votes, nb_membres } = stats[0];

    // Si tous ont voté OUI → approuver et traiter le retrait
    if (parseInt(votes_oui) === parseInt(nb_membres)) {
      await pool.query(
        'UPDATE transactions_virtuelles SET statut = \'approuve\' WHERE id = $1',
        [retraitId]
      );
      await pool.query(
        'UPDATE comptes_virtuels SET solde = solde - $1 WHERE id = $2',
        [retrait[0].montant, retrait[0].compte_virtuel_id]
      );

      // Notifier approbation
      const { rows: tontine } = await pool.query(
        'SELECT nom FROM tontines WHERE id = $1', [id]
      );
      await notificationService.notifierGroupeTontine(id, {
        type: 'retrait_approuve',
        nom_tontine: tontine[0]?.nom,
        montant: retrait[0].montant.toString(),
        tontine_id: id,
      });

      return res.json({
        success: true,
        message: 'Retrait approuvé par tous les membres !',
        approuve: true
      });
    }

    // Si quelqu'un vote NON → refuser
    if (vote === 'non') {
      await pool.query(
        'UPDATE transactions_virtuelles SET statut = \'refuse\' WHERE id = $1',
        [retraitId]
      );
      return res.json({
        success: true,
        message: 'Retrait refusé.',
        approuve: false
      });
    }

    res.json({
      success: true,
      message: `Vote enregistré. ${votes_oui}/${nb_membres} votes pour.`,
      votes_oui: parseInt(votes_oui),
      nb_membres: parseInt(nb_membres),
      approuve: false
    });
  } catch (err) {
    console.error('Erreur vote:', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Historique des transactions du compte virtuel
router.get('/:id/compte-virtuel/transactions', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Vérifier membre
    const { rows: membre } = await pool.query(
      'SELECT id FROM membres_tontine WHERE tontine_id = $1 AND utilisateur_id = $2 AND est_actif = true',
      [id, userId]
    );
    if (membre.length === 0)
      return res.status(403).json({ error: 'Accès refusé' });

    const { rows: cv } = await pool.query(
      'SELECT id FROM comptes_virtuels WHERE tontine_id = $1', [id]
    );
    if (cv.length === 0)
      return res.status(404).json({ error: 'Compte non trouvé' });

    const { rows } = await pool.query(`
      SELECT tv.*, u.prenom, u.nom, u.telephone,
        (SELECT json_agg(vr.*) FROM votes_retrait vr WHERE vr.transaction_id = tv.id) as votes
      FROM transactions_virtuelles tv
      LEFT JOIN utilisateurs u ON u.id = tv.utilisateur_id
      WHERE tv.compte_virtuel_id = $1
      ORDER BY tv.created_at DESC
    `, [cv[0].id]);

    res.json({ success: true, data: rows });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
});


// Ajoute ces routes avant module.exports
router.get('/:id/compte-virtuel', tontineController.getCompteVirtuel);
router.post('/:id/compte-virtuel/depot', tontineController.effectuerDepot);
router.post('/:id/compte-virtuel/retrait/initier', tontineController.initierRetrait);
router.post('/:id/compte-virtuel/retrait/:retraitId/voter', tontineController.voterRetrait);
router.get('/:id/compte-virtuel/transactions', tontineController.getTransactions);
module.exports = router;