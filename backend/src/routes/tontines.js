const express = require('express');
const router = express.Router();
const tontineController = require('../controllers/tontineController');
const { authenticate } = require('../middleware/auth');
const { validateTontine } = require('../middleware/validation');
const { pool } = require('../../config/database');
const notificationService = require('../services/notificationService');

router.use(authenticate);

// ── ROUTES SPÉCIFIQUES AVANT /:id ─────────────────────
router.get('/publiques', tontineController.getTontinesPubliques);
router.get('/adhesions/mes-demandes', tontineController.getMesDemandes);

// ── TONTINES STANDARD ─────────────────────────────────
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
router.post('/:id/demander-adhesion', tontineController.demanderAdhesion);
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

// ── COMPTE VIRTUEL ────────────────────────────────────
router.get('/:id/compte-virtuel', tontineController.getCompteVirtuel);
router.post('/:id/compte-virtuel/depot', tontineController.effectuerDepot);
router.post('/:id/compte-virtuel/retrait/initier', tontineController.initierRetrait);
router.post('/:id/compte-virtuel/retrait/:retraitId/voter', tontineController.voterRetrait);
router.get('/:id/compte-virtuel/transactions', tontineController.getTransactions);

module.exports = router;