const africastalking = require('africastalking');
const sgMail = require('@sendgrid/mail');
const axios = require('axios');
const admin = require('firebase-admin');
const { pool } = require('../../config/database');
const logger = require('../utils/logger');

// ── INIT SERVICES ─────────────────────────────────────
const AT = africastalking({
  apiKey: process.env.AT_API_KEY,
  username: process.env.AT_USERNAME || 'sandbox',
});
const sms = AT.SMS;

sgMail.setApiKey(process.env.SENDGRID_API_KEY);

// Firebase Admin
if (!admin.apps.length && process.env.FIREBASE_PROJECT_ID) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    }),
  });
}

// ── MESSAGES MULTILINGUES ─────────────────────────────
const MESSAGES = {
  rappel_cotisation: {
    fr: (nom, montant, tontine) => `Bonjour ${nom} ! Votre cotisation de ${montant} F pour "${tontine}" est due. Payez maintenant sur Tontine Africa.`,
    moore: (nom, montant, tontine) => `Aw laafi ${nom} ! F cotisation ${montant} F tontine "${tontine}" pʋgẽ yaa sɩda. Tontine Africa zugu f kõ.`,
    dioula: (nom, montant, tontine) => `I ni sogoma ${nom} ! I ka wari ${montant} F bɔ tontine "${tontine}" kama. Tontine Africa kan i ka sara.`,
    en: (nom, montant, tontine) => `Hello ${nom}! Your contribution of ${montant} for "${tontine}" is due. Pay now on Tontine Africa.`,
    wolof: (nom, montant, tontine) => `Salut ${nom}! Sa cotisation ${montant} F pour "${tontine}" dafa des. Fay ci Tontine Africa.`,
  },
  retard_paiement: {
    fr: (nom, montant, tontine) => `⚠️ ${nom}, vous avez un retard de paiement de ${montant} F pour "${tontine}". Régularisez au plus vite.`,
    moore: (nom, montant, tontine) => `⚠️ ${nom}, f cotisation ${montant} F tontine "${tontine}" la yɩɩr. Maneg f kõ.`,
    dioula: (nom, montant, tontine) => `⚠️ ${nom}, i ka wari ${montant} F tontine "${tontine}" ma bɔra. Hali joona i ka sara.`,
    en: (nom, montant, tontine) => `⚠️ ${nom}, you have a late payment of ${montant} for "${tontine}". Please pay immediately.`,
  },
  paiement_confirme: {
    fr: (nom, montant, tontine) => `✅ Paiement confirmé ! ${montant} F reçu pour "${tontine}". Merci ${nom} !`,
    moore: (nom, montant, tontine) => `✅ Paiement sɩnga ! ${montant} F tontine "${tontine}" pʋgẽ. Barka ${nom} !`,
    dioula: (nom, montant, tontine) => `✅ Sarali ka kɛ sɛbɛn ! ${montant} F tontine "${tontine}" kama. Aw ni baara ${nom} !`,
    en: (nom, montant, tontine) => `✅ Payment confirmed! ${montant} received for "${tontine}". Thank you ${nom}!`,
  },
  tour_recu: {
    fr: (nom, montant, tontine) => `🎉 Félicitations ${nom} ! C'est votre tour de recevoir ${montant} F de la tontine "${tontine}" !`,
    moore: (nom, montant, tontine) => `🎉 Barka ${nom} ! Rũnna f yɩɩra ${montant} F tontine "${tontine}" pʋgẽ !`,
    dioula: (nom, montant, tontine) => `🎉 Aw ni ce ${nom} ! Bi i ka wari ${montant} F sɔrɔ tontine "${tontine}" la !`,
    en: (nom, montant, tontine) => `🎉 Congratulations ${nom}! It's your turn to receive ${montant} from "${tontine}"!`,
  },
  nouveau_membre_tontine: {
    fr: (nom, montant, tontine) => `👥 ${nom} a rejoint votre tontine "${tontine}".`,
    moore: (nom, montant, tontine) => `👥 ${nom} kẽnga tontine "${tontine}" pʋgẽ.`,
    dioula: (nom, montant, tontine) => `👥 ${nom} donna tontine "${tontine}" kɔnɔ.`,
    en: (nom, montant, tontine) => `👥 ${nom} joined your tontine "${tontine}".`,
  },
  demande_adhesion: {
    fr: (nom, montant, tontine) => `👤 ${nom} demande à rejoindre votre tontine "${tontine}". Acceptez ou refusez dans l'app.`,
    moore: (nom, montant, tontine) => `👤 ${nom} dat tontine "${tontine}" pʋgẽ kẽng. A sɩd wall a bas.`,
    dioula: (nom, montant, tontine) => `👤 ${nom} b'a fɛ tontine "${tontine}" sɔrɔ. I ka to ka dɔn walima ka ban.`,
    en: (nom, montant, tontine) => `👤 ${nom} wants to join your tontine "${tontine}". Accept or decline in the app.`,
  },
  adhesion_acceptee: {
    fr: (nom, montant, tontine) => `🎉 Votre demande pour rejoindre "${tontine}" a été acceptée ! Bienvenue !`,
    moore: (nom, montant, tontine) => `🎉 F kẽngr tontine "${tontine}" pʋgẽ yaa sɩda ! Aw laafi !`,
    dioula: (nom, montant, tontine) => `🎉 I tontine "${tontine}" kɔnɔ sɔrɔli ye sɛbɛn ! Bisimila !`,
    en: (nom, montant, tontine) => `🎉 Your request to join "${tontine}" has been accepted! Welcome!`,
  },
  invitation_tontine: {
    fr: (nom, montant, tontine) => `💰 Vous êtes invité(e) à rejoindre la tontine "${tontine}". Téléchargez Tontine Africa !`,
    moore: (nom, montant, tontine) => `💰 A bool yãmb tontine "${tontine}" pʋgẽ. Tontine Africa app kẽng !`,
    dioula: (nom, montant, tontine) => `💰 I be wele tontine "${tontine}" kɔnɔ. Tontine Africa app sɔrɔ !`,
    en: (nom, montant, tontine) => `💰 You are invited to join tontine "${tontine}". Download Tontine Africa!`,
  },
};

function getMessage(type, langue, nom, montant, tontine) {
  const msgs = MESSAGES[type];
  if (!msgs) return `Notification Tontine Africa`;
  const fn = msgs[langue] || msgs['fr'];
  return fn ? fn(nom, montant, tontine) : msgs['fr'](nom, montant, tontine);
}

// ── ENVOI SMS ─────────────────────────────────────────
async function envoyerSMS(telephone, message) {
  try {
    if (process.env.AT_USERNAME === 'sandbox') {
      logger.info(`[SMS SANDBOX] → ${telephone}: ${message}`);
      return { success: true, sandbox: true };
    }
    const result = await sms.send({
      to: [telephone],
      message,
      from: process.env.AT_SENDER_ID || 'TONTINE',
    });
    logger.info(`SMS envoyé à ${telephone}`);
    return result;
  } catch (err) {
    logger.error(`Erreur SMS ${telephone}:`, err.message);
    return { success: false, error: err.message };
  }
}

// ── ENVOI WHATSAPP ────────────────────────────────────
async function envoyerWhatsApp(telephone, message) {
  try {
    if (!process.env.WHATSAPP_TOKEN) return { success: false };

    const tel = telephone.startsWith('+') ? telephone.substring(1) : telephone;
    await axios.post(
      `https://graph.facebook.com/v18.0/${process.env.WHATSAPP_PHONE_NUMBER_ID}/messages`,
      {
        messaging_product: 'whatsapp',
        to: tel,
        type: 'text',
        text: { body: message },
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.WHATSAPP_TOKEN}`,
          'Content-Type': 'application/json',
        },
      }
    );
    logger.info(`WhatsApp envoyé à ${telephone}`);
    return { success: true };
  } catch (err) {
    logger.error(`Erreur WhatsApp ${telephone}:`, err.message);
    return { success: false, error: err.message };
  }
}

// ── ENVOI EMAIL ───────────────────────────────────────
async function envoyerEmail(email, sujet, message) {
  try {
    if (!process.env.SENDGRID_API_KEY) return { success: false };

    await sgMail.send({
      to: email,
      from: {
        email: process.env.SENDGRID_FROM_EMAIL,
        name: process.env.SENDGRID_FROM_NAME || 'Tontine Africa',
      },
      subject: sujet,
      text: message,
      html: `<div style="font-family:Arial;padding:20px;background:#f5f5f5">
        <div style="background:white;padding:24px;border-radius:12px;max-width:500px;margin:0 auto">
          <h2 style="color:#1D9E75">💰 Tontine Africa</h2>
          <p>${message}</p>
          <hr style="border:1px solid #eee">
          <p style="color:#888;font-size:12px">Tontine Africa — Épargne solidaire en Afrique</p>
        </div>
      </div>`,
    });
    logger.info(`Email envoyé à ${email}`);
    return { success: true };
  } catch (err) {
    logger.error(`Erreur email ${email}:`, err.message);
    return { success: false };
  }
}

// ── ENVOI PUSH FCM ────────────────────────────────────
async function envoyerPush(fcmToken, titre, message, data = {}) {
  try {
    if (!admin.apps.length || !fcmToken) return { success: false };

    await admin.messaging().send({
      token: fcmToken,
      notification: { title: titre, body: message },
      data: { ...data, click_action: 'FLUTTER_NOTIFICATION_CLICK' },
      android: {
        notification: {
          channelId: 'tontine_channel',
          priority: 'high',
          color: '#1D9E75',
        },
      },
      apns: {
        payload: {
          aps: { badge: 1, sound: 'default' },
        },
      },
    });
    logger.info(`Push envoyé`);
    return { success: true };
  } catch (err) {
    logger.error(`Erreur push:`, err.message);
    return { success: false };
  }
}

// ── NOTIFICATION MEMBRE (tous canaux) ─────────────────
async function notifierMembre(userId, options) {
  try {
    const { rows } = await pool.query(
      'SELECT nom, prenom, telephone, langue, email, fcm_token FROM utilisateurs WHERE id = $1',
      [userId]
    );
    if (!rows[0]) return;

    const u = rows[0];
    const langue = u.langue || 'fr';
    const nom = u.prenom || u.nom;
    const message = getMessage(
      options.type, langue, nom,
      options.montant || '', options.nom_tontine || ''
    );
    const titre = 'Tontine Africa';

    // Sauvegarder en base
    await pool.query(`
      INSERT INTO notifications (utilisateur_id, tontine_id, type, titre, message, canal)
      VALUES ($1, $2, $3, $4, $5, 'push')
    `, [userId, options.tontine_id || null, options.type, titre, message]);

    // Envoyer sur tous les canaux en parallèle
    await Promise.allSettled([
      u.fcm_token ? envoyerPush(u.fcm_token, titre, message, { tontine_id: options.tontine_id || '' }) : null,
      envoyerSMS(u.telephone, message),
      envoyerWhatsApp(u.telephone, message),
      u.email ? envoyerEmail(u.email, titre, message) : null,
    ].filter(Boolean));

    logger.info(`Notification envoyée à ${u.telephone} (${langue})`);
  } catch (err) {
    logger.error('Erreur notifierMembre:', err);
  }
}

// ── NOTIFICATION GROUPE TONTINE ───────────────────────
async function notifierGroupeTontine(tontineId, options) {
  try {
    const { rows } = await pool.query(`
      SELECT u.id FROM membres_tontine mt
      JOIN utilisateurs u ON u.id = mt.utilisateur_id
      WHERE mt.tontine_id = $1 AND mt.est_actif = true
    `, [tontineId]);

    await Promise.allSettled(
      rows.map(r => notifierMembre(r.id, options))
    );
  } catch (err) {
    logger.error('Erreur notifierGroupeTontine:', err);
  }
}

module.exports = {
  envoyerSMS,
  envoyerWhatsApp,
  envoyerEmail,
  envoyerPush,
  notifierMembre,
  notifierGroupeTontine,
  getMessage,
};