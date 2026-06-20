const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { pool } = require('../../config/database');
const notificationService = require('../services/notificationService');
const logger = require('../utils/logger');

const authController = {

  async inscription(req, res) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const { nom, prenom, telephone, code_pin, langue, type_acces,
              orange_money_numero, moov_money_numero } = req.body;

      const { rows: existing } = await client.query(
        'SELECT id FROM utilisateurs WHERE telephone = $1', [telephone]
      );
      if (existing[0]) {
        return res.status(400).json({ error: 'Ce numéro est déjà enregistré' });
      }

      const hashedPin = await bcrypt.hash(code_pin, 10);
      const { rows } = await client.query(`
        INSERT INTO utilisateurs (nom, prenom, telephone, code_pin, langue,
          type_acces, orange_money_numero, moov_money_numero)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
        RETURNING id, nom, prenom, telephone, langue, type_acces, score_fiabilite
      `, [nom, prenom, telephone, hashedPin, langue || 'fr',
          type_acces || 'smartphone', orange_money_numero, moov_money_numero]);

      const user = rows[0];
      const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, {
        expiresIn: process.env.JWT_EXPIRES_IN || '30d'
      });

      await client.query('COMMIT');

      await notificationService.envoyerSMS(telephone, {
        fr: `Bienvenue sur Tontine BF ${prenom} ! Votre compte est créé. Rejoignez ou créez votre première tontine.`,
        moore: `${prenom}, Tontine BF pʋgẽ aw laafi ! F account yaa kẽng. Tontine paalem wall sɩng.`,
        dioula: `${prenom}, i bisimila Tontine BF la ! I ka compte daminɛna. Tontine kelen sɔrɔ.`
      }[langue || 'fr']);

      logger.info(`Nouvel utilisateur inscrit: ${telephone}`);
      res.status(201).json({ success: true, data: { user, token } });

    } catch (err) {
      await client.query('ROLLBACK');
      logger.error('Erreur inscription:', err);
      res.status(500).json({ error: 'Erreur lors de l\'inscription' });
    } finally {
      client.release();
    }
  },

  async connexion(req, res) {
    try {
      const { telephone, code_pin } = req.body;
      const { rows } = await pool.query(
        'SELECT * FROM utilisateurs WHERE telephone = $1 AND est_actif = true', [telephone]
      );

      if (!rows[0]) {
        return res.status(401).json({ error: 'Numéro non trouvé' });
      }

      const user = rows[0];
      const pinValide = await bcrypt.compare(code_pin, user.code_pin);
      if (!pinValide) {
        return res.status(401).json({ error: 'Code PIN incorrect' });
      }

      const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, {
        expiresIn: process.env.JWT_EXPIRES_IN || '30d'
      });

      const { code_pin: _, ...userSafe } = user;
      logger.info(`Connexion: ${telephone}`);
      res.json({ success: true, data: { user: userSafe, token } });

    } catch (err) {
      logger.error('Erreur connexion:', err);
      res.status(500).json({ error: 'Erreur lors de la connexion' });
    }
  },

  async refreshToken(req, res) {
    res.json({ success: true, message: 'Refresh token - à implémenter' });
  },

  async deconnexion(req, res) {
    res.json({ success: true, message: 'Déconnexion réussie' });
  }
};

module.exports = authController;
