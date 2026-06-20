const { pool } = require('../../config/database');
const logger = require('../utils/logger');

const MENUS = {
  fr: {
    accueil: `CON Bienvenue sur Tontine BF\n1. Mes tontines\n2. Mon solde\n3. Payer cotisation\n4. Mon tour\n5. Aide`,
    mes_tontines: `CON Vos tontines actives:`,
    aucune_tontine: `END Vous n'avez pas de tontine active.`,
    payer_demande: `CON Entrez le numéro de votre tontine:`,
    confirmation_paiement: (montant, tontine) =>
      `CON Payer ${montant}F pour "${tontine}"?\n1. Confirmer\n2. Annuler`,
    paiement_lance: `END Paiement initié. Vous allez recevoir une demande Orange Money ou Moov Money.`,
    erreur: `END Une erreur est survenue. Réessayez.`,
    aide: `END Aide Tontine BF:\n- Cotisation: payez à temps\n- Mon tour: voyez quand vous recevez\nAppel: +226 XX XX XX XX`
  },
  moore: {
    accueil: `CON Tontine BF pʋgẽ\n1. M tontines\n2. M laafi\n3. Cotisation laf\n4. M yɩɩr\n5. Sõsg`,
    mes_tontines: `CON Yãmb tontines:`,
    aucune_tontine: `END Yãmb ka tontine ye.`,
    paiement_lance: `END Paiement sɩngame. Orange Money wall Moov Money na wa.`,
    erreur: `END Bõn-yoodo n wa. Meg tɩ lɛɛg.`
  },
  dioula: {
    accueil: `CON Tontine BF kɔnɔ\n1. N tontines\n2. N kɛnɛya\n3. Musaka sara\n4. N sira\n5. Dɛmɛ`,
    mes_tontines: `CON I tontines:`,
    aucune_tontine: `END I tontine tɛ yen.`,
    paiement_lance: `END Sarali daminɛna. Orange Money walima Moov Money bɛna na.`,
    erreur: `END Fili dɔ ye. A to an ka a lajɛ.`
  }
};

const ussdService = {

  async traiterRequete(sessionId, phoneNumber, networkCode, serviceCode, text) {
    try {
      const telephone = phoneNumber.replace('+', '');
      const { rows } = await pool.query(
        'SELECT * FROM utilisateurs WHERE telephone = $1', [telephone]
      );

      const user = rows[0];
      const langue = user?.langue || 'fr';
      const menu = MENUS[langue] || MENUS.fr;
      const inputs = text ? text.split('*') : [];
      const niveau = inputs.length;

      logger.info(`USSD: ${telephone} niveau ${niveau} input "${text}"`);

      if (niveau === 0 || text === '') {
        return menu.accueil;
      }

      if (!user) {
        return `END Numéro non reconnu. Inscrivez-vous sur l'app Tontine BF.`;
      }

      const choix1 = inputs[0];

      if (choix1 === '1') {
        return await this.afficherMesTontines(user, inputs, menu, langue);
      }

      if (choix1 === '2') {
        return await this.afficherSolde(user, menu);
      }

      if (choix1 === '3') {
        return await this.gererPaiement(user, inputs, menu);
      }

      if (choix1 === '4') {
        return await this.afficherMonTour(user, menu);
      }

      if (choix1 === '5') {
        return menu.aide;
      }

      return menu.erreur;

    } catch (err) {
      logger.error('Erreur USSD:', err);
      return `END Erreur technique. Réessayez.`;
    }
  },

  async afficherMesTontines(user, inputs, menu, langue) {
    const { rows: tontines } = await pool.query(`
      SELECT t.nom, t.montant_cotisation, mt.a_recu,
        (SELECT COUNT(*) FROM cotisations c
         WHERE c.tontine_id = t.id AND c.membre_id = $1 AND c.statut = 'en_attente'
         AND c.date_echeance <= NOW() + INTERVAL '2 days') as cotisation_urgente
      FROM tontines t
      JOIN membres_tontine mt ON mt.tontine_id = t.id AND mt.utilisateur_id = $1
      WHERE t.statut = 'active'
      LIMIT 5
    `, [user.id]);

    if (!tontines.length) return menu.aucune_tontine;

    if (inputs.length === 1) {
      let reponse = menu.mes_tontines + '\n';
      tontines.forEach((t, i) => {
        const urgence = t.cotisation_urgente > 0 ? ' ⚠️' : '';
        reponse += `${i + 1}. ${t.nom}${urgence}\n`;
      });
      return `CON ${reponse.trim()}`;
    }

    const choix = parseInt(inputs[1]) - 1;
    if (tontines[choix]) {
      const t = tontines[choix];
      return `END ${t.nom}\nCotisation: ${t.montant_cotisation}F\nStatut: ${t.a_recu ? 'Reçu ✓' : 'En attente'}`;
    }

    return menu.erreur;
  },

  async afficherSolde(user, menu) {
    const { rows } = await pool.query(`
      SELECT
        COUNT(CASE WHEN c.statut = 'paye' THEN 1 END) as nb_payes,
        COUNT(CASE WHEN c.statut = 'en_attente' THEN 1 END) as nb_attente,
        SUM(CASE WHEN c.statut = 'en_attente' AND c.date_echeance <= NOW() + INTERVAL '7 days'
          THEN c.montant ELSE 0 END) as montant_urgent
      FROM cotisations c
      WHERE c.membre_id = $1
    `, [user.id]);

    const s = rows[0];
    return `END ${user.prenom} ${user.nom}\nPaiements: ${s.nb_payes} effectués\nEn attente: ${s.nb_attente}\nÀ payer bientôt: ${s.montant_urgent || 0}F`;
  },

  async gererPaiement(user, inputs, menu) {
    if (inputs.length === 1) {
      const { rows: tontines } = await pool.query(`
        SELECT t.id, t.nom, c.montant, c.id as cotisation_id
        FROM cotisations c
        JOIN tontines t ON t.id = c.tontine_id
        WHERE c.membre_id = $1 AND c.statut = 'en_attente'
        ORDER BY c.date_echeance ASC
        LIMIT 5
      `, [user.id]);

      if (!tontines.length) return `END Aucune cotisation en attente.`;

      let reponse = `CON Cotisations à payer:\n`;
      tontines.forEach((t, i) => {
        reponse += `${i + 1}. ${t.nom} - ${t.montant}F\n`;
      });
      return reponse.trim();
    }

    if (inputs.length === 2) {
      const { rows: cotisations } = await pool.query(`
        SELECT c.*, t.nom as nom_tontine
        FROM cotisations c
        JOIN tontines t ON t.id = c.tontine_id
        WHERE c.membre_id = $1 AND c.statut = 'en_attente'
        ORDER BY c.date_echeance ASC
        LIMIT 5
      `, [user.id]);

      const choix = parseInt(inputs[1]) - 1;
      if (cotisations[choix]) {
        const c = cotisations[choix];
        return menu.confirmation_paiement
          ? menu.confirmation_paiement(c.montant, c.nom_tontine)
          : `CON Payer ${c.montant}F pour "${c.nom_tontine}"?\n1. Oui\n2. Non`;
      }
    }

    if (inputs.length === 3 && inputs[2] === '1') {
      return menu.paiement_lance;
    }

    return `END Paiement annulé.`;
  },

  async afficherMonTour(user, menu) {
    const { rows } = await pool.query(`
      SELECT t.nom, mt.position_rotation, mt.a_recu,
        (SELECT COUNT(*) FROM membres_tontine mt2
         WHERE mt2.tontine_id = t.id AND mt2.a_recu = true) as membres_recus
      FROM membres_tontine mt
      JOIN tontines t ON t.id = mt.tontine_id
      WHERE mt.utilisateur_id = $1 AND t.statut = 'active'
    `, [user.id]);

    if (!rows.length) return `END Pas de tontine active.`;

    let reponse = '';
    rows.forEach(r => {
      const restant = r.position_rotation - r.membres_recus;
      if (r.a_recu) {
        reponse += `${r.nom}: Déjà reçu ✓\n`;
      } else {
        reponse += `${r.nom}: ${restant} tour(s) avant vous\n`;
      }
    });

    return `END Vos tours:\n${reponse.trim()}`;
  }
};

module.exports = ussdService;
