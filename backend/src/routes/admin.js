const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { authenticate } = require('../middleware/auth');
const { isAdmin } = require('../middleware/admin');

// ── LOGIN (sans auth) ─────────────────────────────────
router.post('/login', adminController.loginAdmin);

router.use(authenticate);
router.use(isAdmin);

// ── STATS & ALERTES ───────────────────────────────────
router.get('/stats', adminController.getStats);
router.get('/alerts', adminController.getAlerts);

// ── UTILISATEURS ──────────────────────────────────────
router.get('/users', adminController.getAllUsers);
router.get('/users/:id', adminController.getUserDetail);
router.put('/users/:id/bloquer', adminController.bloquerUser);
router.put('/users/:id/debloquer', adminController.debloquerUser);

// ── TONTINES ──────────────────────────────────────────
router.get('/tontines', adminController.getAllTontines);
router.get('/tontines/:id', adminController.getTontineDetail);
router.put('/tontines/:id/suspendre', adminController.suspendreTontine);
router.put('/tontines/:id/reactiver', adminController.reactiverTontine);

// ── COMPTES VIRTUELS ──────────────────────────────────
router.get('/comptes-virtuels', adminController.getAllComptesVirtuels);
router.get('/comptes-virtuels/:id', adminController.getCompteVirtuelDetail);
router.get('/comptes-virtuels/:id/transactions', adminController.getTransactionsCompte);

// ── RETRAITS ──────────────────────────────────────────
router.get('/retraits', adminController.getAllRetraits);
router.get('/retraits/:id', adminController.getRetraitDetail);
router.put('/retraits/:id/valider', adminController.validerRetrait);
router.put('/retraits/:id/refuser', adminController.refuserRetrait);

// ── TRANSACTIONS ──────────────────────────────────────
router.get('/paiements', adminController.getAllPaiements);
router.get('/paiements/export', adminController.exporterPaiements);

// ── NOTIFICATIONS ─────────────────────────────────────
router.post('/notifications/envoyer', adminController.envoyerNotificationMasse);
router.get('/notifications/historique', adminController.getHistoriqueNotifications);

// ── CATALOGUE ─────────────────────────────────────────
router.get('/catalogue', adminController.getCatalogue);
router.post('/catalogue', adminController.ajouterProduit);
router.put('/catalogue/:id', adminController.modifierProduit);
router.delete('/catalogue/:id', adminController.supprimerProduit);

// ── COMMERÇANTS ───────────────────────────────────────
router.get('/commercants', adminController.getCommercants);
router.post('/commercants', adminController.ajouterCommercant);
router.put('/commercants/:id', adminController.modifierCommercant);
router.put('/commercants/:id/valider', adminController.validerCommercant);
router.put('/commercants/:id/refuser', adminController.refuserCommercant);
router.delete('/commercants/:id', adminController.supprimerCommercant);

// ── FOURNISSEURS (ancien système) ─────────────────────
router.get('/fournisseurs', adminController.getFournisseurs);
router.post('/fournisseurs', adminController.ajouterFournisseur);
router.put('/fournisseurs/:id', adminController.modifierFournisseur);

// ── ADMINS & DROITS ───────────────────────────────────
router.get('/admins', adminController.getAdmins);
router.post('/admins', adminController.ajouterAdmin);
router.put('/admins/:id/droits', adminController.modifierDroitsAdmin);
router.delete('/admins/:id', adminController.supprimerAdmin);

module.exports = router;