const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { authenticate } = require('../middleware/auth');
const { isAdmin } = require('../middleware/admin');

router.post('/login', adminController.loginAdmin);

router.use(authenticate);
router.use(isAdmin);

router.get('/stats', adminController.getStats);
router.get('/alerts', adminController.getAlerts);
router.get('/users', adminController.getAllUsers);
router.put('/users/:id/bloquer', adminController.bloquerUser);
router.put('/users/:id/debloquer', adminController.debloquerUser);
router.get('/tontines', adminController.getAllTontines);
router.get('/paiements', adminController.getAllPaiements);
router.post('/notifications/envoyer', adminController.envoyerNotificationMasse);
router.get('/catalogue', adminController.getCatalogue);
router.post('/catalogue', adminController.ajouterProduit);
router.put('/catalogue/:id', adminController.modifierProduit);
router.delete('/catalogue/:id', adminController.supprimerProduit);
router.get('/fournisseurs', adminController.getFournisseurs);
router.post('/fournisseurs', adminController.ajouterFournisseur);
router.put('/fournisseurs/:id', adminController.modifierFournisseur);

module.exports = router;