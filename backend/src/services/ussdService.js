const { pool } = require('../../config/database');
const logger = require('../utils/logger');

const MENUS = {
  fr: {
    accueil: `CON Bienvenue sur TontiLigdi\n1. Mes tontines\n2. Mon solde\n3. Payer cotisation\n4. Mon tour\n5. Aide`,
    mes_tontines: `CON Vos tontines actives:`,
    aucune_tontine: `END Vous n'avez pas de tontine active.`,
    payer_demande: `CON Entrez le numéro de votre tontine:`,
    paiement_instructions: (montant, numero) =>
      `CON Envoyez ${montant}F au ${numero} (Orange/Moov Money).\nEnsuite entrez la référence de la transaction:`,
    reference_invalide: `END Référence invalide (trop courte). Recommencez, ou soumettez votre capture directement sur l'app.`,
    reference_enregistree: `END Référence enregistrée. L'organisateur va vérifier et valider votre paiement.`,
    erreur: `END Une erreur est survenue. Réessayez.`,
    aide: `END Aide TontiLigdi:\n- Cotisation: payez à temps\n- Mon tour: voyez quand vous recevez\nAppel: +226 XX XX XX XX`,
    non_inscrit: `END Ce numéro n'est pas encore enregistré sur TontiLigdi.\nDemandez à la personne qui vous a invité de vérifier votre numéro, ou téléchargez l'app pour créer votre compte.`
  },
  moore: {
    accueil: `CON TontiLigdi pʋgẽ\n1. M tontines\n2. M laafi\n3. Cotisation laf\n4. M yɩɩr\n5. Sõsg`,
    mes_tontines: `CON Yãmb tontines:`,
    aucune_tontine: `END Yãmb ka tontine ye.`,
    paiement_instructions: (montant, numero) =>
      `CON Tʋm ${montant}F ${numero} (Orange/Moov Money). Rẽ poore, kɩt referans wã:`,
    reference_invalide: `END Referans ka zemsg ye. Le sɩng.`,
    reference_enregistree: `END Referans gãneg. Taoor soab na n ges-a la sak-a.`,
    erreur: `END Bõn-yoodo n wa. Meg tɩ lɛɛg.`,
    aide: `END Sõng TontiLigdi:\n- Cotisation: yaool n yao\nCall: +226 XX XX XX XX`,
    non_inscrit: `END Tele wã ka be TontiLigdi pʋgẽ ye. Bool ned sẽn bool-a wã, wall f rɩk aplikasiõ wã.`
  },
  dioula: {
    accueil: `CON TontiLigdi kɔnɔ\n1. N tontines\n2. N kɛnɛya\n3. Musaka sara\n4. N sira\n5. Dɛmɛ`,
    mes_tontines: `CON I tontines:`,
    aucune_tontine: `END I tontine tɛ yen.`,
    paiement_instructions: (montant, numero) =>
      `CON Ci ${montant}F ${numero} la (Orange/Moov Money). O kɔfɛ, sɛbɛnni nimɔrɔ don:`,
    reference_invalide: `END Nimɔrɔ tɛ bɛn. Segin a la.`,
    reference_enregistree: `END Nimɔrɔ sɛbɛnnen. Ɲɛmɔgɔ bɛna a lajɛ ka sara sɔrɔ.`,
    erreur: `END Fili dɔ ye. A to an ka a lajɛ.`,
    aide: `END TontiLigdi dɛmɛ:\n- Musaka: a sara joona\nCall: +226 XX XX XX XX`,
    non_inscrit: `END Nimɔrɔ in tɛ sɛbɛnnen TontiLigdi la. I ka mɔgɔ min ye i wele, o ɲininka, walima ka application ta.`
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
      // Langue par défaut 'fr' tant qu'on ne connaît pas l'utilisateur
      // (impossible de lire sa préférence s'il n'est pas encore inscrit).
      const langue = user?.langue || 'fr';
      const menu = MENUS[langue] || MENUS.fr;
      const inputs = text ? text.split('*') : [];
      const niveau = inputs.length;

      logger.info(`USSD: ${telephone} niveau ${niveau} input "${text}"`);

      if (niveau === 0 || text === '') {
        return menu.accueil;
      }

      if (!user) {
        // FIX: message plus honnête qu'avant — "inscrivez-vous sur l'app"
        // n'aide personne qui n'a justement pas de smartphone. On oriente
        // vers la personne qui a invité, en attendant une vraie solution
        // d'inscription via USSD (nécessite un mécanisme de suivi des
        // invitations pour numéros non-inscrits, à construire séparément —
        // voir note dans la réponse accompagnant ce fichier).
        return menu.non_inscrit;
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
        return menu.aide || MENUS.fr.aide;
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
        COUNT(CASE WHEN c.statut IN ('en_attente', 'partiel') THEN 1 END) as nb_attente,
        SUM(CASE WHEN c.statut IN ('en_attente', 'partiel') AND c.date_echeance <= NOW() + INTERVAL '7 days'
          THEN c.montant - COALESCE(c.montant_paye, 0) ELSE 0 END) as montant_urgent
      FROM cotisations c
      WHERE c.membre_id = $1
    `, [user.id]);

    const s = rows[0];
    return `END ${user.prenom} ${user.nom}\nPaiements: ${s.nb_payes} effectués\nEn attente: ${s.nb_attente}\nÀ payer bientôt: ${s.montant_urgent || 0}F`;
  },

  // FIX MAJEUR: l'ancienne version affichait "Paiement initié, vous allez
  // recevoir une demande Orange/Moov Money" sans jamais rien déclencher
  // réellement — un faux message de succès. TontiLigdi ne fonctionne pas
  // en "push-to-pay" (aucune intégration marchande Orange/Moov Money
  // n'existe ailleurs dans le code), mais sur un principe de référence
  // vérifiée manuellement, comme le reste de l'app. Ce flux est maintenant
  // cohérent : on indique le numéro à payer, l'utilisateur paie lui-même
  // depuis son propre menu Mobile Money, puis soumet la référence reçue.
  async gererPaiement(user, inputs, menu) {
    const { rows: cotisations } = await pool.query(`
      SELECT c.id as cotisation_id, c.montant, c.montant_paye, t.nom,
        COALESCE(org.orange_money_numero, org.moov_money_numero) as numero_organisateur
      FROM cotisations c
      JOIN tontines t ON t.id = c.tontine_id
      JOIN utilisateurs org ON org.id = t.responsable_id
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

    if (inputs.length === 2) {
      const restant = c.montant - (parseFloat(c.montant_paye) || 0);
      const numero = c.numero_organisateur || 'indiqué dans l\'app';
      const fn = menu.paiement_instructions || MENUS.fr.paiement_instructions;
      return fn(restant, numero);
    }

    if (inputs.length === 3) {
      const reference = (inputs[2] || '').trim();
      if (reference.length < 4) {
        return menu.reference_invalide || MENUS.fr.reference_invalide;
      }

      // Enregistre la référence et force une validation manuelle par
      // l'organisateur (pas d'image/OCR possible via USSD, donc pas de
      // score IA automatique — cohérent avec le fonctionnement existant
      // pour les cas ambigus).
      await pool.query(`
        UPDATE cotisations SET
          reference_transaction = $1,
          statut = 'en_attente',
          decision_ia = 'VALIDATION_MANUELLE',
          notes = COALESCE(notes || ' | ', '') || 'Référence soumise par USSD le ' || NOW()::text
        WHERE id = $2
      `, [reference, c.cotisation_id]);

      return menu.reference_enregistree || MENUS.fr.reference_enregistree;
    }

    return menu.erreur;
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