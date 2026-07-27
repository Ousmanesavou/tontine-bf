const express = require('express');
const router = express.Router();
const { pool } = require('../../config/database');
const { authenticate } = require('../middleware/auth');

router.use(authenticate);

// ── MES COTISATIONS (toutes tontines confondues) ──────
// NOUVEAU: cette route n'existait nulle part — l'app l'appelait depuis
// tontine_detail_screen.dart, recevait systématiquement un 404, avalé
// silencieusement par un try/catch vide, d'où "Aucune cotisation" affiché
// en permanence, même après actualisation.
router.get('/mes-cotisations', async (req, res) => {
  try {
    const userId = req.user.id;
    const { rows } = await pool.query(`
      SELECT c.*, t.nom as nom_tontine
      FROM cotisations c
      JOIN tontines t ON t.id = c.tontine_id
      WHERE c.membre_id = $1
      ORDER BY c.date_echeance DESC
    `, [userId]);

    res.json({ success: true, data: rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;