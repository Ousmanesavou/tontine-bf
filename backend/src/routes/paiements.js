const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { validateCotisation } = require('../middleware/validation');
const paiementService = require('../services/paiementService');
const { pool } = require('../../config/database');
const logger = require('../utils/logger');

router.use(authenticate);

router.get('/mes-cotisations', async (req, res) => {
  try {
    const { rows } = await pool.query(`
      SELECT c.*, t.nom as nom_tontine, t.periodicite
      FROM cotisations c
      JOIN tontines t ON t.id = c.tontine_id
      WHERE c.membre_id = $1
      ORDER BY c.date_echeance ASC
    `, [req.user.id]);
    res.json({ success: true, data: rows });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

router.post('/payer', validateCotisation, async (req, res) => {
  const { cotisation_id, methode_paiement, telephone_paiement } = req.body;
  try {
    const { rows } = await pool.query(
      'SELECT * FROM cotisations WHERE id = $1 AND membre_id = $2',
      [cotisation_id, req.user.id]
    );

    if (!rows[0]) return res.status(404).json({ error: 'Cotisation non trouvée' });
    if (rows[0].statut === 'paye') return res.status(400).json({ error: 'Déjà payée' });

    const cotisation = rows[0];
    let result;

    if (methode_paiement === 'orange_money') {
      result = await paiementService.initierPaiementOrangeMoney({
        telephone: telephone_paiement || req.user.telephone,
        montant: cotisation.montant,
        cotisation_id,
        tontine_id: cotisation.tontine_id,
        membre_id: req.user.id
      });
    } else if (methode_paiement === 'moov_money') {
      result = await paiementService.initierPaiementMoovMoney({
        telephone: telephone_paiement || req.user.telephone,
        montant: cotisation.montant,
        cotisation_id
      });
    } else {
      return res.status(400).json({ error: 'Méthode de paiement invalide' });
    }

    res.json({ success: true, data: result });
  } catch (err) {
    logger.error('Erreur paiement:', err);
    res.status(500).json({ error: err.message || 'Erreur lors du paiement' });
  }
});

router.post('/webhook/orange', async (req, res) => {
  const { notifToken, status, txnid } = req.body;
  logger.info(`Webhook Orange Money: ${txnid} status=${status}`);
  try {
    await paiementService.confirmerPaiement(txnid, status);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Erreur traitement webhook' });
  }
});

router.post('/webhook/moov', async (req, res) => {
  const { reference, status } = req.body;
  logger.info(`Webhook Moov Money: ${reference} status=${status}`);
  try {
    await paiementService.confirmerPaiement(reference, status === 'SUCCESSFUL' ? 'SUCCESS' : status);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Erreur traitement webhook' });
  }
});

router.post('/depot-physique', async (req, res) => {
  const { cotisation_id, montant } = req.body;
  try {
    const result = await paiementService.enregistrerDepotPhysique({
      cotisation_id,
      montant,
      responsable_id: req.user.id
    });
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;
