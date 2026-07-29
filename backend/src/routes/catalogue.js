const express = require('express');
const router = express.Router();
const { pool } = require('../../config/database');
const { authenticate } = require('../middleware/auth');

router.use(authenticate);

// ── CATALOGUE PUBLIC (membres) ─────────────────────────
// NOUVEAU: cette route n'existait pas — l'app l'appelait depuis
// catalogue_screen.dart, recevait un 404, avalé silencieusement, d'où le
// repli sur des produits d'exemple codés en dur. Ne montre que les
// produits actifs ET validés par un admin (statut='valide').
router.get('/', async (req, res) => {
  try {
    const { categorie = '' } = req.query;
    let where = "WHERE est_actif = true AND statut = 'valide'";
    const params = [];
    if (categorie) { params.push(categorie); where += ` AND categorie = $${params.length}`; }

    const { rows } = await pool.query(
      `SELECT * FROM catalogue_produits ${where} ORDER BY created_at DESC`, params
    );
    res.json({ success: true, data: rows });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;