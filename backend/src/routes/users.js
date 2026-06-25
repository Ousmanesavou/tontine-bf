const express = require('express');
const router = express.Router();
const { pool } = require('../../config/database');
const { authenticate } = require('../middleware/auth');

router.use(authenticate);

// ── GET MON PROFIL ────────────────────────────────
router.get('/profil', async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT id, nom, prenom, telephone, langue, pays, indicatif,
        photo_profil, score_fiabilite, orange_money_numero,
        moov_money_numero, role, created_at
       FROM utilisateurs WHERE id = $1`,
      [req.user.id]
    );
    if (!rows[0]) return res.status(404).json({ error: 'Utilisateur non trouvé' });
    res.json({ success: true, data: rows[0] });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ── UPDATE MON PROFIL ─────────────────────────────
router.put('/profil', async (req, res) => {
  try {
    const {
      nom, prenom, langue, pays, indicatif,
      photo_profil, photo_url,
      orange_money_numero, moov_money_numero,
    } = req.body;

    // ✅ photo_url OU photo_profil
    const photoFinale = photo_url || photo_profil || null;

    const { rows } = await pool.query(`
      UPDATE utilisateurs SET
        nom = COALESCE($1, nom),
        prenom = COALESCE($2, prenom),
        langue = COALESCE($3, langue),
        pays = COALESCE($4, pays),
        indicatif = COALESCE($5, indicatif),
        photo_profil = COALESCE($6, photo_profil),
        orange_money_numero = COALESCE($7, orange_money_numero),
        moov_money_numero = COALESCE($8, moov_money_numero),
        updated_at = NOW()
      WHERE id = $9
      RETURNING id, nom, prenom, telephone, langue, pays,
        photo_profil, score_fiabilite, orange_money_numero, moov_money_numero
    `, [nom, prenom, langue, pays, indicatif,
        photoFinale,
        orange_money_numero, moov_money_numero,
        req.user.id]);

    res.json({ success: true, data: rows[0] });
  } catch (err) {
    console.error('Erreur update profil:', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ── FCM TOKEN ─────────────────────────────────────
router.post('/fcm-token', async (req, res) => {
  try {
    const { fcm_token } = req.body;
    await pool.query(
      'UPDATE utilisateurs SET fcm_token = $1 WHERE id = $2',
      [fcm_token, req.user.id]
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ── CHANGER PIN ───────────────────────────────────
router.put('/changer-pin', async (req, res) => {
  try {
    const bcrypt = require('bcryptjs');
    const { ancien_pin, nouveau_pin } = req.body;

    const { rows } = await pool.query(
      'SELECT code_pin FROM utilisateurs WHERE id = $1',
      [req.user.id]
    );
    if (!rows[0]) return res.status(404).json({ error: 'Utilisateur non trouvé' });

    const valide = await bcrypt.compare(ancien_pin, rows[0].code_pin);
    if (!valide) return res.status(400).json({ error: 'Ancien PIN incorrect' });

    const newHash = await bcrypt.hash(nouveau_pin, 10);
    await pool.query(
      'UPDATE utilisateurs SET code_pin = $1 WHERE id = $2',
      [newHash, req.user.id]
    );
    res.json({ success: true, message: 'PIN modifié avec succès' });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ── SCORE FIABILITÉ ───────────────────────────────
router.get('/score', async (req, res) => {
  try {
    const { rows } = await pool.query(`
      SELECT u.score_fiabilite,
        COUNT(CASE WHEN c.statut = 'paye' THEN 1 END) as total_payes,
        COUNT(CASE WHEN c.statut = 'en_retard' THEN 1 END) as total_retards,
        COUNT(DISTINCT mt.tontine_id) as total_tontines
      FROM utilisateurs u
      LEFT JOIN cotisations c ON c.membre_id = u.id
      LEFT JOIN membres_tontine mt ON mt.utilisateur_id = u.id
      WHERE u.id = $1
      GROUP BY u.score_fiabilite
    `, [req.user.id]);
    res.json({ success: true, data: rows[0] });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;