const africastalking = require('africastalking');
const sgMail = require('@sendgrid/mail');
const axios = require('axios');
const { pool } = require('../../config/database');
const logger = require('../utils/logger');

// Lien temporaire — à remplacer par le vrai lien Play Store une fois l'app publiée.
const LIEN_TELECHARGEMENT = 'https://tontiligdi.com/telecharger';

// ── INIT AFRICA'S TALKING ─────────────────────────────
const AT = africastalking({
  apiKey: process.env.AT_API_KEY || 'sandbox',
  username: process.env.AT_USERNAME || 'sandbox',
});
const sms = AT.SMS;

// ── INIT SENDGRID ─────────────────────────────────────
if (process.env.SENDGRID_API_KEY) {
  sgMail.setApiKey(process.env.SENDGRID_API_KEY);
}

// ── INIT FIREBASE ADMIN ───────────────────────────────
let firebaseAdmin = null;
try {
  const admin = require('firebase-admin');
  if (process.env.FIREBASE_PROJECT_ID) {
    if (!admin.apps || admin.apps.length === 0) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
        }),
      });
      logger.info('Firebase Admin initialisé avec succès');
    }
    firebaseAdmin = admin;
  }
} catch (err) {
  logger.error('Erreur init Firebase Admin:', err.message);
}

// ── MESSAGES MULTILINGUES ─────────────────────────────
const MESSAGES = {
  rappel_cotisation: {
    fr: (nom, montant, tontine) => `Bonjour ${nom} ! Votre cotisation de ${montant} F pour "${tontine}" est due. Payez maintenant sur TontiLigdi.`,
    moore: (nom, montant, tontine) => `Aw laafi ${nom} ! F cotisation ${montant} F tontine "${tontine}" pʋgẽ yaa sɩda. TontiLigdi zugu f kõ.`,
    dioula: (nom, montant, tontine) => `I ni sogoma ${nom} ! I ka wari ${montant} F bɔ tontine "${tontine}" kama. TontiLigdi kan i ka sara.`,
    en: (nom, montant, tontine) => `Hello ${nom}! Your contribution of ${montant} for "${tontine}" is due. Pay now on TontiLigdi.`,
    wolof: (nom, montant, tontine) => `Salut ${nom}! Sa cotisation ${montant} F pour "${tontine}" dafa des. Fay ci TontiLigdi.`,
    bambara: (nom, montant, tontine) => `I ni sogoma ${nom}! I ka wari ${montant} bɔ tontine "${tontine}" kama. TontiLigdi kan i ka sara.`,
  },
  retard_paiement: {
    fr: (nom, montant, tontine) => `⚠️ ${nom}, vous avez un retard de paiement de ${montant} F pour "${tontine}". Régularisez au plus vite.`,
    moore: (nom, montant, tontine) => `⚠️ ${nom}, f cotisation ${montant} F tontine "${tontine}" la yɩɩr. Maneg f kõ.`,
    dioula: (nom, montant, tontine) => `⚠️ ${nom}, i ka wari ${montant} F tontine "${tontine}" ma bɔra. Hali joona i ka sara.`,
    en: (nom, montant, tontine) => `⚠️ ${nom}, you have a late payment of ${montant} for "${tontine}". Please pay immediately.`,
    wolof: (nom, montant, tontine) => `⚠️ ${nom}, am nga retard ci ${montant} F pour "${tontine}". Fay leegi.`,
  },
  paiement_confirme: {
    fr: (nom, montant, tontine) => `✅ Paiement confirmé ! ${montant} F reçu pour "${tontine}". Merci ${nom} !`,
    moore: (nom, montant, tontine) => `✅ Paiement sɩnga ! ${montant} F tontine "${tontine}" pʋgẽ. Barka ${nom} !`,
    dioula: (nom, montant, tontine) => `✅ Sarali ka kɛ sɛbɛn ! ${montant} F tontine "${tontine}" kama. Aw ni baara ${nom} !`,
    en: (nom, montant, tontine) => `✅ Payment confirmed! ${montant} received for "${tontine}". Thank you ${nom}!`,
    wolof: (nom, montant, tontine) => `✅ Paiement confirme ! ${montant} F jot na pour "${tontine}". Jërejëf ${nom} !`,
  },
  tour_recu: {
    fr: (nom, montant, tontine) => `🎉 Félicitations ${nom} ! C'est votre tour de recevoir ${montant} F de la tontine "${tontine}" !`,
    moore: (nom, montant, tontine) => `🎉 Barka ${nom} ! Rũnna f yɩɩra ${montant} F tontine "${tontine}" pʋgẽ !`,
    dioula: (nom, montant, tontine) => `🎉 Aw ni ce ${nom} ! Bi i ka wari ${montant} F sɔrɔ tontine "${tontine}" la !`,
    en: (nom, montant, tontine) => `🎉 Congratulations ${nom}! It's your turn to receive ${montant} from "${tontine}"!`,
    wolof: (nom, montant, tontine) => `🎉 Félicitations ${nom} ! Yow la tour bi di dox ci ${montant} F ci "${tontine}" !`,
  },
  nouveau_membre_tontine: {
    fr: (nom, montant, tontine) => `👥 ${nom} a rejoint votre tontine "${tontine}".`,
    moore: (nom, montant, tontine) => `👥 ${nom} kẽnga tontine "${tontine}" pʋgẽ.`,
    dioula: (nom, montant, tontine) => `👥 ${nom} donna tontine "${tontine}" kɔnɔ.`,
    en: (nom, montant, tontine) => `👥 ${nom} joined your tontine "${tontine}".`,
    wolof: (nom, montant, tontine) => `👥 ${nom} dugge na ci tontine "${tontine}" bi.`,
  },
  demande_adhesion: {
    fr: (nom, montant, tontine) => `👤 ${nom} demande à rejoindre votre tontine "${tontine}". Acceptez ou refusez dans l'app.`,
    moore: (nom, montant, tontine) => `👤 ${nom} dat tontine "${tontine}" pʋgẽ kẽng. A sɩd wall a bas.`,
    dioula: (nom, montant, tontine) => `👤 ${nom} b'a fɛ tontine "${tontine}" sɔrɔ. I ka to ka dɔn walima ka ban.`,
    en: (nom, montant, tontine) => `👤 ${nom} wants to join your tontine "${tontine}". Accept or decline in the app.`,
    wolof: (nom, montant, tontine) => `👤 ${nom} dafa bëgg dugg ci tontine "${tontine}". Acepte walla refusé ci app bi.`,
  },
  adhesion_acceptee: {
    fr: (nom, montant, tontine) => `🎉 Votre demande pour rejoindre "${tontine}" a été acceptée ! Bienvenue !`,
    moore: (nom, montant, tontine) => `🎉 F kẽngr tontine "${tontine}" pʋgẽ yaa sɩda ! Aw laafi !`,
    dioula: (nom, montant, tontine) => `🎉 I tontine "${tontine}" kɔnɔ sɔrɔli ye sɛbɛn ! Bisimila !`,
    en: (nom, montant, tontine) => `🎉 Your request to join "${tontine}" has been accepted! Welcome!`,
    wolof: (nom, montant, tontine) => `🎉 Sa demande pour "${tontine}" accepte na ! Dalal ak jàmm !`,
  },
  adhesion_refusee: {
    fr: (nom, montant, tontine) => `❌ Votre demande pour rejoindre "${tontine}" a été refusée.`,
    moore: (nom, montant, tontine) => `❌ F kẽngr tontine "${tontine}" pʋgẽ ka sɩd ye.`,
    dioula: (nom, montant, tontine) => `❌ I tontine "${tontine}" kɔnɔ sɔrɔli ma kɛ.`,
    en: (nom, montant, tontine) => `❌ Your request to join "${tontine}" has been declined.`,
  },
  invitation_tontine: {
    fr: (nom, montant, tontine) => `👋 Vous êtes invité(e) à rejoindre la tontine "${tontine}". Ouvrez TontiLigdi pour accepter ! ${LIEN_TELECHARGEMENT}`,
    moore: (nom, montant, tontine) => `👋 A bool yãmb tontine "${tontine}" pʋgẽ. Yak TontiLigdi app ! ${LIEN_TELECHARGEMENT}`,
    dioula: (nom, montant, tontine) => `👋 I be wele tontine "${tontine}" kɔnɔ. TontiLigdi app da wuli ! ${LIEN_TELECHARGEMENT}`,
    en: (nom, montant, tontine) => `👋 You are invited to join tontine "${tontine}". Open TontiLigdi to accept! ${LIEN_TELECHARGEMENT}`,
    wolof: (nom, montant, tontine) => `👋 Yow la wele ci tontine "${tontine}". Ubbi TontiLigdi app bi ! ${LIEN_TELECHARGEMENT}`,
  },
  rapport_mensuel: {
    fr: (nom, montant, tontine) => `📊 Rapport mensuel de "${tontine}" : ${montant} F collectés ce mois. Continuez !`,
    moore: (nom, montant, tontine) => `📊 Rapport "${tontine}" : ${montant} F lɛɛba dũnni. Maan !`,
    dioula: (nom, montant, tontine) => `📊 Rapport "${tontine}" : ${montant} F bɔra kalo in na. Taa !`,
    en: (nom, montant, tontine) => `📊 Monthly report for "${tontine}": ${montant} collected this month. Keep it up!`,
  },
  // NOUVEAU: déclaration de paiement USSD reçue — envoyé à l'organisateur
  // ET à l'admin, pour qu'ils sachent qu'une vérification est attendue.
  declaration_paiement_recue: {
    fr: (nom, montant, tontine) => `📲 ${nom} déclare avoir payé ${montant} F pour "${tontine}" (via USSD). Vérifiez le SMS Orange/Moov Money reçu et validez dans l'app.`,
    en: (nom, montant, tontine) => `📲 ${nom} declared a payment of ${montant} for "${tontine}" (via USSD). Check the Orange/Moov Money SMS received and validate in the app.`,
  },
  // NOUVEAU: rappel automatique si une déclaration reste sans suite
  rappel_declaration_attente: {
    fr: (nom, montant, tontine) => `⏰ Rappel : ${nom} a déclaré ${montant} F pour "${tontine}" il y a plus de 24h, toujours pas vérifié. Merci de traiter.`,
    en: (nom, montant, tontine) => `⏰ Reminder: ${nom} declared ${montant} for "${tontine}" over 24h ago, still not verified. Please process.`,
  },
};

function getMessage(type, langue, nom, montant, tontine) {
  const msgs = MESSAGES[type];
  if (!msgs) return `Notification TontiLigdi`;
  const fn = msgs[langue] || msgs['fr'];
  return fn ? fn(nom || '', montant || '', tontine || '') : (msgs['fr'](nom || '', montant || '', tontine || ''));
}

// ── IKODDI (SMS) ───────────────────────────────────────
let ikoddiClient = null;
function getIkoddiClient() {
  if (ikoddiClient !== null) return ikoddiClient;
  if (!process.env.IKODDI_KEY || !process.env.IKODDI_GROUP_ID) {
    ikoddiClient = false;
    return false;
  }
  try {
    const { Ikoddi } = require('ikoddi-client-sdk');
    ikoddiClient = new Ikoddi()
      .withApiKey(process.env.IKODDI_KEY)
      .withGroupId(process.env.IKODDI_GROUP_ID);
    logger.info('Ikoddi initialisé avec succès');
  } catch (err) {
    logger.error('Erreur initialisation Ikoddi, repli sur Africa\'s Talking:', {
      message: err.message,
      name: err.name,
      stack: err.stack,
    });
    ikoddiClient = false;
  }
  return ikoddiClient;
}

// ── ENVOI SMS ──────────────────────────────────────────
async function envoyerSMS(telephone, message) {
  try {
    if (!telephone) return { success: false };

    const client = getIkoddiClient();
    if (client) {
      await client.sendSMS(
        [telephone],
        process.env.IKODDI_SENDER_ID || 'TONTINE',
        message,
        'Notification Tontine'
      );
      logger.info(`SMS envoyé à ${telephone} (Ikoddi)`);
      return { success: true };
    }

    if (process.env.AT_USERNAME === 'sandbox') {
      logger.info(`[SMS SANDBOX] → ${telephone}: ${message}`);
      return { success: true, sandbox: true };
    }
    const result = await sms.send({
      to: [telephone],
      message,
      from: process.env.AT_SENDER_ID || 'TONTINE',
    });
    logger.info(`SMS envoyé à ${telephone} (Africa's Talking)`);
    return result;
  } catch (err) {
    logger.error(`Erreur SMS ${telephone}:`, {
      message: err.message,
      name: err.name,
      response: err.response?.data,
      stack: err.stack,
    });
    return { success: false, error: err.message };
  }
}

// ── ENVOI WHATSAPP ──────────────────────────────────────
async function envoyerWhatsApp(telephone, message) {
  try {
    if (!process.env.WHATSAPP_TOKEN || !telephone) return { success: false };
    const tel = telephone.startsWith('+') ? telephone.substring(1) : telephone;
    await axios.post(
      `https://graph.facebook.com/v18.0/${process.env.WHATSAPP_PHONE_NUMBER_ID}/messages`,
      {
        messaging_product: 'whatsapp',
        to: tel,
        type: 'template',
        template: {
          name: 'notification_tontiligdi',
          language: { code: 'fr' },
          components: [
            {
              type: 'body',
              parameters: [
                { type: 'text', text: message },
              ],
            },
          ],
        },
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
    const detailMeta = err.response?.data?.error;
    logger.error(`Erreur WhatsApp ${telephone}:`, detailMeta || err.message);
    return { success: false, error: detailMeta?.message || err.message };
  }
}

// ── ENVOI EMAIL ───────────────────────────────────────
async function envoyerEmail(email, sujet, message) {
  try {
    if (!process.env.SENDGRID_API_KEY || !email) return { success: false };
    await sgMail.send({
      to: email,
      from: {
        email: process.env.SENDGRID_FROM_EMAIL || 'noreply@tontiligdi.com',
        name: process.env.SENDGRID_FROM_NAME || 'TontiLigdi',
      },
      subject: sujet,
      text: message,
      html: `
        <div style="font-family:Arial;padding:20px;background:#f5f5f5">
          <div style="background:white;padding:24px;border-radius:12px;max-width:500px;margin:0 auto">
            <div style="text-align:center;margin-bottom:20px">
              <h2 style="color:#1D9E75;margin:0">💰 TontiLigdi</h2>
              <p style="color:#888;font-size:12px;margin:4px 0">Épargne solidaire en Afrique</p>
            </div>
            <p style="font-size:15px;line-height:1.6;color:#333">${message}</p>
            <hr style="border:1px solid #eee;margin:20px 0">
            <p style="color:#888;font-size:11px;text-align:center">
              TontiLigdi — Burkina Faso, Mali, Sénégal, Côte d'Ivoire et plus
            </p>
          </div>
        </div>
      `,
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
    if (!firebaseAdmin || !fcmToken) return { success: false };
    const stringData = {};
    Object.keys(data).forEach(k => { stringData[k] = String(data[k] || ''); });
    await firebaseAdmin.messaging().send({
      token: fcmToken,
      notification: { title: titre, body: message },
      data: { ...stringData, click_action: 'FLUTTER_NOTIFICATION_CLICK' },
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
    if (!userId) return;
    const { rows } = await pool.query(
      'SELECT nom, prenom, telephone, langue, email, fcm_token FROM utilisateurs WHERE id = $1',
      [userId]
    );
    if (!rows[0]) return;

    const u = rows[0];
    const langue = u.langue || 'fr';
    // FIX: certains messages concernent un tiers (ex: "X demande à
    // rejoindre VOTRE tontine") — le nom affiché n'est alors pas celui du
    // destinataire mais celui fourni explicitement par l'appelant. Sans
    // précision, on retombe sur le nom du destinataire (comportement
    // historique, correct pour rappel_cotisation, tour_recu, etc.).
    const nom = options.nom_acteur || (u.prenom || u.nom || '');
    // NOUVEAU: message_override permet d'envoyer un texte entièrement
    // personnalisé (ex: confirmation de paiement détaillée avec solde
    // avant/après) sans forcer le contenu dans le format rigide à 3
    // paramètres de getMessage(). N'affecte aucun appel existant — ils ne
    // passent jamais ce champ, donc leur comportement reste identique.
    const message = options.message_override || getMessage(
      options.type, langue, nom,
      options.montant || '', options.nom_tontine || ''
    );
    const titre = 'TontiLigdi';

    try {
      await pool.query(`
        INSERT INTO notifications (utilisateur_id, tontine_id, type, titre, message, canal)
        VALUES ($1, $2, $3, $4, $5, 'push')
      `, [userId, options.tontine_id || null, options.type, titre, message]);
    } catch (dbErr) {
      logger.error('Erreur sauvegarde notification:', dbErr.message);
    }

    const canaux = [
      envoyerSMS(u.telephone, message),
      envoyerWhatsApp(u.telephone, message),
    ];
    if (u.fcm_token) canaux.push(envoyerPush(u.fcm_token, titre, message, { tontine_id: options.tontine_id || '' }));
    if (u.email) canaux.push(envoyerEmail(u.email, titre, message));

    await Promise.allSettled(canaux);
    logger.info(`Notification envoyée à ${u.telephone} (${langue})`);
  } catch (err) {
    logger.error('Erreur notifierMembre:', err.message);
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
    await Promise.allSettled(rows.map(r => notifierMembre(r.id, options)));
  } catch (err) {
    logger.error('Erreur notifierGroupeTontine:', err.message);
  }
}

// NOUVEAU: notifie tous les comptes administrateurs (role = 'admin').
async function notifierTousLesAdmins(options) {
  try {
    const { rows } = await pool.query(
      `SELECT id FROM utilisateurs WHERE role = 'admin'`
    );
    await Promise.allSettled(rows.map(r => notifierMembre(r.id, options)));
  } catch (err) {
    logger.error('Erreur notifierTousLesAdmins:', err.message);
  }
}

// NOUVEAU (FIX BUG CRITIQUE): cette fonction était appelée depuis
// cronJobs.js chaque jour à 8h mais n'existait nulle part — le rappel
// quotidien de cotisation échouait silencieusement depuis le début.
async function envoyerRappelsCotisations() {
  try {
    const { rows } = await pool.query(`
      SELECT c.id, c.montant, c.membre_id, c.tontine_id, t.nom as nom_tontine
      FROM cotisations c
      JOIN tontines t ON t.id = c.tontine_id
      WHERE c.statut IN ('en_attente', 'partiel')
        AND c.date_echeance BETWEEN NOW() AND NOW() + INTERVAL '3 days'
    `);

    for (const c of rows) {
      await notifierMembre(c.membre_id, {
        type: 'rappel_cotisation',
        tontine_id: c.tontine_id,
        nom_tontine: c.nom_tontine,
        montant: c.montant,
      });
    }
    logger.info(`${rows.length} rappels de cotisation envoyés`);
  } catch (err) {
    logger.error('Erreur envoyerRappelsCotisations:', err.message);
  }
}

// NOUVEAU (FIX BUG CRITIQUE): même problème que ci-dessus — appelée depuis
// cronJobs.js chaque minuit, mais n'existait pas. Les cotisations en retard
// n'étaient probablement jamais marquées automatiquement.
async function marquerRetards() {
  try {
    const { rows } = await pool.query(`
      UPDATE cotisations SET statut = 'en_retard'
      WHERE statut IN ('en_attente', 'partiel')
        AND date_echeance < NOW()
      RETURNING id, membre_id, tontine_id, montant
    `);

    for (const c of rows) {
      const { rows: [t] } = await pool.query('SELECT nom FROM tontines WHERE id = $1', [c.tontine_id]);
      await notifierMembre(c.membre_id, {
        type: 'retard_paiement',
        tontine_id: c.tontine_id,
        nom_tontine: t?.nom || '',
        montant: c.montant,
      });
    }
    logger.info(`${rows.length} cotisations marquées en retard`);
  } catch (err) {
    logger.error('Erreur marquerRetards:', err.message);
  }
}

// ── NOTIFICATION PARLER (vocal) ───────────────────────
function parlerMultilingue({ fr, moore, dioula, en }) {
  return { fr, moore, dioula, en };
}

module.exports = {
  envoyerSMS,
  envoyerWhatsApp,
  envoyerEmail,
  envoyerPush,
  notifierMembre,
  notifierGroupeTontine,
  notifierTousLesAdmins,
  envoyerRappelsCotisations,
  marquerRetards,
  getMessage,
  parlerMultilingue,
  LIEN_TELECHARGEMENT,
};