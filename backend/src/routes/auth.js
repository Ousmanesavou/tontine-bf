const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { validateInscription, validateConnexion } = require('../middleware/validation');

router.post('/inscription', validateInscription, authController.inscription);
router.post('/connexion', validateConnexion, authController.connexion);
router.post('/refresh-token', authController.refreshToken);
router.post('/deconnexion', authController.deconnexion);

module.exports = router;
