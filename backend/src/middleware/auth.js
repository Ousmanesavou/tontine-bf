const jwt = require('jsonwebtoken');
const { pool } = require('../../config/database');

async function authenticate(req, res, next) {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ error: 'Token manquant' });

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const { rows } = await pool.query(
      'SELECT id, nom, prenom, telephone, langue, type_acces, score_fiabilite FROM utilisateurs WHERE id = $1 AND est_actif = true',
      [decoded.userId]
    );

    if (!rows[0]) return res.status(401).json({ error: 'Utilisateur non trouvé' });
    req.user = rows[0];
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Session expirée. Reconnectez-vous.' });
    }
    return res.status(401).json({ error: 'Token invalide' });
  }
}

module.exports = { authenticate };
