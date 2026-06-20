const AfricasTalking = require('africastalking');
const axios = require('axios');
const { pool } = require('../../config/database');
const logger = require('../utils/logger');

const AT = AfricasTalking({
  apiKey: process.env.AT_API_KEY,
  username: process.env.AT_USERNAME
});

const sms = AT.SMS;
const voice = AT.VOICE;

const MESSAGES = {
  rappel_cotisation: {
    fr: (nom, montant, tontine, jours) =>
      `Bonjour ${nom} ! Votre cotisation de ${montant}F pour la tontine "${tontine}" est due dans ${jours} jour(s). Payez via Orange Money ou Moov Money.`,
    moore: (nom, montant, tontine, jours) =>
      `${nom}, f tontine "${tontine}" yaa kõ ${montant}F. Doge ${jours} lɛbg. Tɩ na Orange Money wall Moov Money.`,
    dioula: (nom, montant, tontine, jours) =>
      `${nom}, i ka tontine "${tontine}" kɔnɔ musaka ye ${montant}F ye. Tile ${jours} kɔ. O ka san Orange Money walima Moov Money fɛ.`
  },
  paiement_confirme: {
    fr: (nom, montant, tontine) =>
      `✅ ${nom}, votre paiement de ${montant}F pour "${tontine}" est confirmé. Merci !`,
    moore: (nom, montant, tontine) =>
      `✅ ${nom}, f paiement ${montant}F tontine "${tontine}" yaa sɩd. A barka !`,
    dioula: (nom, montant, tontine) =>
      `✅ ${nom}, i ka sarali ${montant}F tontine "${tontine}" ye sɛbɛn. I ni ce !`
  },
  tour_prochain: {
    fr: (nom, tontine, date) =>
      `🎉 ${nom}, c'est bientôt votre tour dans la tontine "${tontine}" ! Date prévue : ${date}.`,
    moore: (nom, tontine, date) =>
      `🎉 ${nom}, f yɩɩr yaa wa tontine "${tontine}" pʋgẽ ! Doge : ${date}.`,
    dioula: (nom, tontine, date) =>
      `🎉 ${nom}, i sisan bɛ se ka tontine "${tontine}" sɔrɔ ! Lɛ : ${date}.`
  },
  cotisation_en_retard: {
    fr: (nom, montant, tontine) =>
      `⚠️ ${nom}, votre cotisation de ${montant}F pour "${tontine}" est en retard. Veuillez régulariser rapidement.`,
    moore: (nom, montant, tontine) =>
      `⚠️ ${nom}, f cotisation ${montant}F tontine "${tontine}" yaa pɩng. Tɩ lɛɛg !`,
    dioula: (nom, montant, tontine) =>
      `⚠️ ${nom}, i ka musaka ${montant}F tontine "${tontine}" kɔsɛbɛ. I ka yen joona !`
  },
  invitation_tontine: {
    fr: (nomTontine, nomResponsable) =>
      `Vous êtes invité(e) à rejoindre la tontine "${nomTontine}" créée par ${nomResponsable}. Téléchargez l'app Tontine BF pour accepter.`,
    moore: (nomTontine, nomResponsable) =>
      `A bool tontine "${nomTontine}" pʋgẽ - ${nomResponsable} n boola yãmb. Tontine BF app dẽeg !`,
    dioula: (nomTontine, nomResponsable) =>
      `An bɛ wele i ka tontine "${nomTontine}" sɔrɔ - ${nomResponsable} ye i wele. Tontine BF app sɔrɔ !`
  }
};

const notificationService = {

  async notifierMembre(userId, options) {
    try {
      const { rows } = await pool.query(
        'SELECT nom, prenom, telephone, langue, type_acces FROM utilisateurs WHERE id = $1',
        [userId]
      );
      if (!rows[0]) return;

      const user = rows[0];
      const langue = user.langue || 'fr';
      const { type } = options;

      const messageTemplate = MESSAGES[type]?.[langue] || MESSAGES[type]?.fr;
      if (!messageTemplate) return;

      const message = messageTemplate(
        `${user.prenom} ${user.nom}`,
        options.montant,
        options.nom_tontine,
        options.jours_restants,
        options.date
      );

      await pool.query(`
        INSERT INTO notifications (utilisateur_id, tontine_id, type, message,
          message_moore, message_dioula, canal)
        VALUES ($1,$2,$3,$4,$5,$6,$7)
      `, [
        userId, options.tontine_id, type, message,
        MESSAGES[type]?.moore?.(user.prenom, options.montant, options.nom_tontine, options.jours_restants),
        MESSAGES[type]?.dioula?.(user.prenom, options.montant, options.nom_tontine, options.jours_restants),
        user.type_acces === 'basic' ? 'sms' : 'push'
      ]);

      if (user.type_acces === 'basic') {
        await this.envoyerSMS(user.telephone, message);
      } else {
        await this.envoyerPushNotification(userId, { title: type, body: message });
        await this.envoyerWhatsApp(user.telephone, message);
      }

    } catch (err) {
      logger.error('Erreur notifierMembre:', err);
    }
  },

  async envoyerSMS(telephone, message) {
    try {
      const result = await sms.send({
        to: [telephone],
        message: typeof message === 'string' ? message : message.fr,
        from: process.env.AT_SENDER_ID || 'TONTINE'
      });
      logger.info(`SMS envoyé à ${telephone}:`, result);
      return result;
    } catch (err) {
      logger.error('Erreur envoi SMS:', err);
    }
  },

  async envoyerVocal(telephone, message, langue = 'fr') {
    try {
      const langueVoice = langue === 'moore' ? 'fr' : langue;
      const result = await voice.call({
        callFrom: process.env.AT_CALLER_ID,
        callTo: [telephone]
      });
      logger.info(`Appel vocal initié vers ${telephone}`);
      return result;
    } catch (err) {
      logger.error('Erreur appel vocal:', err);
    }
  },

  async envoyerWhatsApp(telephone, message) {
    try {
      if (!process.env.WHATSAPP_TOKEN) return;
      const formattedPhone = telephone.replace(/^0/, '226').replace(/\s/g, '');
      await axios.post(
        `https://graph.facebook.com/v17.0/${process.env.WHATSAPP_PHONE_ID}/messages`,
        {
          messaging_product: 'whatsapp',
          to: formattedPhone,
          type: 'text',
          text: { body: message }
        },
        { headers: { Authorization: `Bearer ${process.env.WHATSAPP_TOKEN}` } }
      );
      logger.info(`WhatsApp envoyé à ${telephone}`);
    } catch (err) {
      logger.error('Erreur WhatsApp:', err);
    }
  },

  async envoyerPushNotification(userId, { title, body }) {
    logger.info(`Push notification pour ${userId}: ${title}`);
  },

  async notifierGroupeTontine(tontineId, options) {
    try {
      const { rows } = await pool.query(
        'SELECT utilisateur_id FROM membres_tontine WHERE tontine_id = $1 AND est_actif = true',
        [tontineId]
      );
      await Promise.all(rows.map(m => this.notifierMembre(m.utilisateur_id, options)));
    } catch (err) {
      logger.error('Erreur notifierGroupe:', err);
    }
  },

  async envoyerRappelsCotisations() {
    try {
      const demain = new Date();
      demain.setDate(demain.getDate() + 1);
      const dansDeuxJours = new Date();
      dansDeuxJours.setDate(dansDeuxJours.getDate() + 2);

      const { rows: cotisations } = await pool.query(`
        SELECT c.*, t.nom as nom_tontine, u.nom, u.prenom, u.telephone, u.langue, u.type_acces
        FROM cotisations c
        JOIN tontines t ON t.id = c.tontine_id
        JOIN utilisateurs u ON u.id = c.membre_id
        WHERE c.statut = 'en_attente'
          AND c.date_echeance BETWEEN NOW() AND $1
      `, [dansDeuxJours]);

      for (const cotisation of cotisations) {
        const joursRestants = Math.ceil(
          (new Date(cotisation.date_echeance) - new Date()) / (1000 * 60 * 60 * 24)
        );
        await this.notifierMembre(cotisation.membre_id, {
          type: 'rappel_cotisation',
          tontine_id: cotisation.tontine_id,
          nom_tontine: cotisation.nom_tontine,
          montant: cotisation.montant,
          jours_restants: joursRestants
        });
      }

      logger.info(`${cotisations.length} rappels cotisation envoyés`);
    } catch (err) {
      logger.error('Erreur envoyerRappels:', err);
    }
  },

  async marquerRetards() {
    try {
      const { rowCount } = await pool.query(`
        UPDATE cotisations SET statut = 'en_retard'
        WHERE statut = 'en_attente' AND date_echeance < NOW()
      `);
      logger.info(`${rowCount} cotisations marquées en retard`);
    } catch (err) {
      logger.error('Erreur marquerRetards:', err);
    }
  }
};

module.exports = notificationService;
