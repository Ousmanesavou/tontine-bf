const express = require('express');
const router = express.Router();
const tontineController = require('../controllers/tontineController');
const { authenticate } = require('../middleware/auth');
const { validateTontine } = require('../middleware/validation');

router.use(authenticate);

router.get('/', tontineController.getMesTontines);
router.post('/', validateTontine, tontineController.creerTontine);
router.get('/:id', tontineController.getTontine);
router.put('/:id', tontineController.modifierTontine);
router.delete('/:id', tontineController.supprimerTontine);

router.get('/:id/membres', tontineController.getMembres);
router.post('/:id/membres/inviter', tontineController.inviterMembre);
router.post('/:id/membres/rejoindre', tontineController.rejoindreTontine);
router.delete('/:id/membres/:membreId', tontineController.retirerMembre);

router.get('/:id/cotisations', tontineController.getCotisations);
router.get('/:id/statistiques', tontineController.getStatistiques);
router.get('/:id/rapport', tontineController.genererRapport);

router.post('/:id/emprunts', tontineController.demanderEmprunt);
router.put('/:id/emprunts/:empruntId/voter', tontineController.voterEmprunt);
router.post('/:id/emprunts/:empruntId/rembourser', tontineController.rembourserEmprunt);

router.get('/publiques', tontineController.getTontinesPubliques);
router.post('/:id/rejoindre', tontineController.rejoindreTontine);
router.post('/:id/demander-adhesion', tontineController.demanderAdhesion);
router.get('/adhesions/mes-demandes', tontineController.getMesDemandes);
router.put('/adhesions/:adhesionId/accepter', tontineController.accepterAdhesion);
router.put('/adhesions/:adhesionId/refuser', tontineController.refuserAdhesion);
module.exports = router;
// Tontines publiques
router.get('/publiques', authenticate, async (req, res) => {
  try {
    const { search = '' } = req.query;
    const userId = req.user.id;

    let query = `
      SELECT 
        t.*,
        u.prenom as responsable_prenom,
        u.nom as responsable_nom,
        COUNT(mt.id) as total_membres,
        EXISTS(
          SELECT 1 FROM membres_tontine 
          WHERE tontine_id = t.id AND utilisateur_id = $1
        ) as est_membre,
        EXISTS(
          SELECT 1 FROM adhesions_tontine 
          WHERE tontine_id = t.id AND utilisateur_id = $1 AND statut = 'en_attente'
        ) as demande_en_attente
      FROM tontines t
      LEFT JOIN utilisateurs u ON u.id = t.responsable_id
      LEFT JOIN membres_tontine mt ON mt.tontine_id = t.id AND mt.est_actif = true
      WHERE t.est_public = true AND t.statut = 'actif'
    `;

    const params = [userId];

    if (search) {
      params.push(`%${search}%`);
      query += ` AND t.nom ILIKE $${params.length}`;
    }

    query += ` GROUP BY t.id, u.prenom, u.nom ORDER BY t.created_at DESC`;

    const { rows } = await pool.query(query, params);
    res.json({ success: true, data: rows });
  } catch (err) {
    console.error('Erreur tontines publiques:', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Demander adhésion
router.post('/:id/demander-adhesion', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const { message = '' } = req.body;
    const userId = req.user.id;

    // Vérifier si déjà membre
    const { rows: membres } = await pool.query(
      'SELECT id FROM membres_tontine WHERE tontine_id = $1 AND utilisateur_id = $2',
      [id, userId]
    );
    if (membres.length > 0) {
      return res.status(400).json({ error: 'Vous êtes déjà membre' });
    }

    // Vérifier si demande déjà envoyée
    const { rows: demandes } = await pool.query(
      'SELECT id FROM adhesions_tontine WHERE tontine_id = $1 AND utilisateur_id = $2',
      [id, userId]
    );
    if (demandes.length > 0) {
      return res.status(400).json({ error: 'Demande déjà envoyée' });
    }

    await pool.query(
      `INSERT INTO adhesions_tontine (tontine_id, utilisateur_id, message, statut)
       VALUES ($1, $2, $3, 'en_attente')`,
      [id, userId, message]
    );

    res.json({ success: true, message: 'Demande envoyée' });
  } catch (err) {
    console.error('Erreur adhésion:', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});