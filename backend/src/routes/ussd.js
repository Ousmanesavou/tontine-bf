const express = require('express');
const router = express.Router();
const ussdService = require('../services/ussdService');
const logger = require('../utils/logger');

router.post('/', async (req, res) => {
  const { sessionId, phoneNumber, networkCode, serviceCode, text } = req.body;
  logger.info(`USSD request: ${phoneNumber} text="${text}"`);
  try {
    const reponse = await ussdService.traiterRequete(
      sessionId, phoneNumber, networkCode, serviceCode, text
    );
    res.set('Content-Type', 'text/plain');
    res.send(reponse);
  } catch (err) {
    logger.error('Erreur USSD route:', err);
    res.set('Content-Type', 'text/plain');
    res.send('END Erreur technique. Réessayez plus tard.');
  }
});

module.exports = router;
