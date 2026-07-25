const { pool } = require('../../config/database');
const notificationService = require('./notificationService');
const logger = require('../utils/logger');

const MENUS = {
  fr: {
    accueil: `CON Bienvenue sur TontiLigdi\n1. Mes tontines\n2. Mon solde\n3. Payer cotisation\n4. Mon tour\n5. Aide`,
    mes_tontines: `CON Vos tontines actives:`,
    aucune_tontine: `END Vous n'avez pas de tontine active.`,
    choix_operateur: (nom, restant) =>
      `CON Cotisation "${nom}": ${restant}F restant.\nVous avez payé avec:`,
    montant_demande: (nom, restant) =>
      `CON Cotisation "${nom}": ${restant}F restant.\nEntrez le montant que vous avez envoyé:`,
    montant_invalide: `END Montant invalide. Recommencez.`,
    declaration_enregistree: (numero) =>
      `END Déclaration enregistrée !\nTransférez maintenant le SMS reçu au ${numero}.\nL'organisateur vérifiera et validera.`,
    aucun_moyen_paiement: `END Aucun moyen de paiement configuré actuellement. Contactez le support.`,
    erreur: `END Une erreur est survenue. Réessayez.`,
    aide: `END Aide TontiLigdi:\n- Cotisation: payez à temps\n- Mon tour: voyez quand vous recevez\nAppel: +226 XX XX XX XX`,
    non_inscrit: `END Ce numéro n'est pas encore enregistré sur TontiLigdi.\nDemandez à la personne qui vous a invité de vérifier votre numéro, ou téléchargez l'app pour créer votre compte.`
  },
  moore: {
    accueil: `CON TontiLigdi pʋgẽ\n1. M tontines\n2. M laafi\n3. Cotisation laf\n4. M yɩɩr\n5. Sõsg`,
    mes_tontines: `CON Yãmb tontines:`,
    aucune_tontine: `END Yãmb ka tontine ye.`,
    montant_invalide: `END Ligdi ka zemsg ye. Le sɩng.`,
    declaration_enregistree: (numero) =>
      `END Gãneg pʋgẽ! Tʋm SMS ning f sẽn deeg wã ${numero}. Taoor soab na n ges-a.`,
    erreur: `END Bõn-yoodo n wa. Meg tɩ lɛɛg.`,
    aide: `END Sõng TontiLigdi:\n- Cotisation: yaool n yao\nCall: +226 XX XX XX XX`,
    non_inscrit: `END Tele wã ka be TontiLigdi pʋgẽ ye. Bool ned sẽn bool-a wã, wall f rɩk aplikasiõ wã.`
  },
  dioula: {
    accueil: `CON TontiLigdi kɔnɔ\n1. N tontines\n2. N kɛnɛya\n3. Musaka sara\n4. N sira\n5. Dɛmɛ`,
    mes_tontines: `CON I tontines:`,
    aucune_tontine: `END I tontine tɛ yen.`,
    montant_invalide: `END Wari nimɔrɔ tɛ bɛn. Segin a la.`,
    declaration_enregistree: (numero) =>
      `END A sɛbɛnnen! I ka SMS min sɔrɔ, o don ${numero} la. Ɲɛmɔgɔ bɛna a lajɛ.`,
    erreur: `END Fili dɔ ye. A to an ka a lajɛ.`,
    aide: `END TontiLigdi dɛmɛ:\n- Musaka: a sara joona\nCall: +226 XX XX XX XX`,
    non_inscrit: `END Nimɔrɔ in tɛ sɛbɛnnen TontiLigdi la. I ka mɔgɔ min ye i wele, o ɲininka, walima ka application ta.`
  }
};

const ussdService = {

  async traiterRequete(sessionId, phoneNumber, networkCode, serviceCode, text) {
    try {
      const telephone = phoneNumber; // conserve le "+", cohérent avec le stockage en base
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
        return menu.non_inscrit;
      }

      const choix1 = inputs[0];

      if (choix1 === '1') return await this.afficherMesTontines(user, inputs, menu);
      if (choix1 === '2') return await this.afficherSolde(user, menu);
      if (choix1 === '3') return await this.gererPaiement(user, inputs, menu);
      if (choix1 === '4') return await this.afficherMonTour(user, menu);
      if (choix1 === '5') return menu.aide || MENUS.fr.aide;

      return menu.erreur;

    } catch (err) {
      logger.error('Erreur USSD:', err);
      return `END Erreur technique. Réessayez.`;
    }
  },

  async afficherMesTontines(user, inputs, menu) {
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
        COUNT(CASE WHEN c.statut IN ('en_attente', 'partiel') THEN 1 END) as nb_attente,
        SUM(CASE WHEN c.statut IN ('en_attente', 'partiel') AND c.date_echeance <= NOW() + INTERVAL '7 days'
          THEN c.montant - COALESCE(c.montant_paye, 0) ELSE 0 END) as montant_urgent
      FROM cotisations c
      WHERE c.membre_id = $1
    `, [user.id]);

    const s = rows[0];
    return `END ${user.prenom} ${user.nom}\nPaiements: ${s.nb_payes} effectués\nEn attente: ${s.nb_attente}\nÀ payer bientôt: ${s.montant_urgent || 0}F`;
  },

  // NOUVEAU: le numéro à payer n'est plus celui de l'organisateur — il est
  // désormais centralisé sur les numéros de réception de Toeeg Digital
  // (table numeros_reception_toeeg), lus dynamiquement à chaque appel.
  // Avec un seul opérateur actif (Orange Money aujourd'hui), le flux saute
  // directement à la saisie du montant. Dès que Moov/Telecel seront
  // ajoutés dans cette table, le menu de choix d'opérateur s'active tout
  // seul, sans qu'il soit nécessaire de retoucher ce code.
  async gererPaiement(user, inputs, menu) {
    const { rows: cotisations } = await pool.query(`
      SELECT c.id as cotisation_id, c.montant, c.montant_paye, c.tontine_id, t.nom
      FROM cotisations c
      JOIN tontines t ON t.id = c.tontine_id
      WHERE c.membre_id = $1 AND c.statut IN ('en_attente', 'partiel', 'rejete')
      ORDER BY c.periode_numero ASC
      LIMIT 5
    `, [user.id]);

    if (!cotisations.length) return `END Aucune cotisation en attente.`;

    if (inputs.length === 1) {
      let reponse = `CON Cotisations à payer:\n`;
      cotisations.forEach((c, i) => {
        const restant = c.montant - (parseFloat(c.montant_paye) || 0);
        reponse += `${i + 1}. ${c.nom} - ${restant}F\n`;
      });
      return reponse.trim();
    }

    const choix = parseInt(inputs[1]) - 1;
    const c = cotisations[choix];
    if (!c) return menu.erreur;
    const restant = c.montant - (parseFloat(c.montant_paye) || 0);

    const { rows: operateurs } = await pool.query(
      `SELECT operateur, numero FROM numeros_reception_toeeg WHERE actif = true ORDER BY operateur`
    );
    if (!operateurs.length) return menu.aucun_moyen_paiement || MENUS.fr.aucun_moyen_paiement;

    // ── Cas simple: un seul opérateur actif (situation actuelle) ──
    if (operateurs.length === 1) {
      if (inputs.length === 2) {
        const fn = menu.montant_demande || MENUS.fr.montant_demande;
        return fn(c.nom, restant);
      }
      if (inputs.length === 3) {
        return await this._finaliserDeclaration(user, c, inputs[2], operateurs[0]);
      }
      return menu.erreur;
    }

    // ── Cas multi-opérateurs (dès que Moov/Telecel seront ajoutés) ──
    if (inputs.length === 2) {
      let reponse = (menu.choix_operateur || MENUS.fr.choix_operateur)(c.nom, restant) + '\n';
      operateurs.forEach((op, i) => { reponse += `${i + 1}. ${op.operateur}\n`; });
      return reponse.trim();
    }
    if (inputs.length === 3) {
      const opChoisi = operateurs[parseInt(inputs[2]) - 1];
      if (!opChoisi) return menu.erreur;
      const fn = menu.montant_demande || MENUS.fr.montant_demande;
      return fn(c.nom, restant);
    }
    if (inputs.length === 4) {
      const opChoisi = operateurs[parseInt(inputs[2]) - 1];
      if (!opChoisi) return menu.erreur;
      return await this._finaliserDeclaration(user, c, inputs[3], opChoisi);
    }

    return menu.erreur;
  },

  async _finaliserDeclaration(user, c, montantStr, operateurChoisi) {
    const langue = user?.langue || 'fr';
    const menu = MENUS[langue] || MENUS.fr;
    const montant = parseFloat(montantStr);
    if (isNaN(montant) || montant <= 0) {
      return menu.montant_invalide || MENUS.fr.montant_invalide;
    }

    await pool.query(`
      INSERT INTO declarations_paiement_ussd
        (cotisation_id, membre_id, tontine_id, montant_declare)
      VALUES ($1, $2, $3, $4)
    `, [c.cotisation_id, user.id, c.tontine_id, montant]);

    const { rows: [tontine] } = await pool.query(
      'SELECT responsable_id FROM tontines WHERE id = $1', [c.tontine_id]
    );
    const nomComplet = `${user.prenom || ''} ${user.nom || ''}`.trim();

    const messageOverride = notificationService.getMessage(
      'declaration_paiement_recue', 'fr', nomComplet, montant, c.nom
    );
    const notifOptions = {
      type: 'declaration_paiement_recue',
      tontine_id: c.tontine_id,
      montant: montant,
      message_override: messageOverride,
    };

    if (tontine?.responsable_id) {
      await notificationService.notifierMembre(tontine.responsable_id, notifOptions);
    }
    await notificationService.notifierTousLesAdmins(notifOptions);

    const fn = menu.declaration_enregistree || MENUS.fr.declaration_enregistree;
    return fn(operateurChoisi.numero);
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