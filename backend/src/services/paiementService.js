const axios = require('axios');
const { pool } = require('../../config/database');
const notificationService = require('./notificationService');
const logger = require('../utils/logger');

const paiementService = {

  async initierPaiementOrangeMoney(data) {
    const { telephone, montant, cotisation_id, tontine_id, membre_id } = data;
    try {
      const tokenResponse = await axios.post(
        'https://api.orange.com/oauth/v3/token',
        'grant_type=client_credentials',
        {
          headers: {
            Authorization: `Basic ${Buffer.from(
              `${process.env.ORANGE_MONEY_CLIENT_ID}:${process.env.ORANGE_MONEY_CLIENT_SECRET}`
            ).toString('base64')}`,
            'Content-Type': 'application/x-www-form-urlencoded'
          }
        }
      );

      const token = tokenResponse.data.access_token;
      const reference = `TBF-${Date.now()}-${cotisation_id.slice(0, 8)}`;

      const paymentResponse = await axios.post(
        `${process.env.ORANGE_MONEY_BASE_URL}/webpayment`,
        {
          merchant_key: process.env.ORANGE_MONEY_MERCHANT_KEY,
          currency: 'OUV',
          order_id: reference,
          amount: montant,
          return_url: `${process.env.APP_URL}/api/paiements/callback/orange`,
          cancel_url: `${process.env.APP_URL}/api/paiements/annulation`,
          notif_url: `${process.env.APP_URL}/api/paiements/webhook/orange`,
          lang: 'fr',
          reference
        },
        { headers: { Authorization: `Bearer ${token}` } }
      );

      await pool.query(`
        UPDATE cotisations SET
          statut = 'en_cours_paiement',
          reference_transaction = $1,
          methode_paiement = 'orange_money'
        WHERE id = $2
      `, [reference, cotisation_id]);

      logger.info(`Paiement Orange Money initié: ${reference}`);
      return {
        success: true,
        reference,
        payment_url: paymentResponse.data.payment_url,
        pay_token: paymentResponse.data.pay_token
      };

    } catch (err) {
      logger.error('Erreur Orange Money:', err.response?.data || err.message);
      throw new Error('Erreur initialisation paiement Orange Money');
    }
  },

  async initierPaiementMoovMoney(data) {
    const { telephone, montant, cotisation_id } = data;
    try {
      const reference = `TBF-MOOV-${Date.now()}-${cotisation_id.slice(0, 8)}`;

      const response = await axios.post(
        `${process.env.MOOV_MONEY_BASE_URL}/payment/initiate`,
        {
          amount: montant,
          currency: 'XOF',
          subscriber_number: telephone,
          reference,
          description: `Cotisation tontine - Tontine BF`,
          callback_url: `${process.env.APP_URL}/api/paiements/webhook/moov`
        },
        {
          headers: {
            'X-API-Key': process.env.MOOV_MONEY_API_KEY,
            'Content-Type': 'application/json'
          }
        }
      );

      await pool.query(`
        UPDATE cotisations SET
          statut = 'en_cours_paiement',
          reference_transaction = $1,
          methode_paiement = 'moov_money'
        WHERE id = $2
      `, [reference, cotisation_id]);

      logger.info(`Paiement Moov Money initié: ${reference}`);
      return { success: true, reference, ...response.data };

    } catch (err) {
      logger.error('Erreur Moov Money:', err.response?.data || err.message);
      throw new Error('Erreur initialisation paiement Moov Money');
    }
  },

  async confirmerPaiement(reference, statut_operateur) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const { rows } = await client.query(
        'SELECT * FROM cotisations WHERE reference_transaction = $1',
        [reference]
      );

      if (!rows[0]) throw new Error('Transaction non trouvée');
      const cotisation = rows[0];

      if (statut_operateur === 'SUCCESS' || statut_operateur === 'SUCCESSFUL') {
        await client.query(`
          UPDATE cotisations SET
            statut = 'paye',
            date_paiement = NOW()
          WHERE reference_transaction = $1
        `, [reference]);

        await this.mettreAJourScoreFiabilite(cotisation.membre_id, true, client);
        await this.verifierTourSuivant(cotisation.tontine_id, client);

        const { rows: userRows } = await client.query(
          'SELECT nom, prenom, langue FROM utilisateurs WHERE id = $1',
          [cotisation.membre_id]
        );
        const { rows: tontineRows } = await client.query(
          'SELECT nom FROM tontines WHERE id = $1',
          [cotisation.tontine_id]
        );

        await client.query('COMMIT');

        await notificationService.notifierMembre(cotisation.membre_id, {
          type: 'paiement_confirme',
          tontine_id: cotisation.tontine_id,
          nom_tontine: tontineRows[0]?.nom,
          montant: cotisation.montant
        });

        await notificationService.notifierGroupeTontine(cotisation.tontine_id, {
          type: 'membre_a_paye',
          tontine_id: cotisation.tontine_id,
          nom_tontine: tontineRows[0]?.nom,
          nom_membre: `${userRows[0]?.prenom} ${userRows[0]?.nom}`
        });

        logger.info(`Paiement confirmé: ${reference}`);
        return { success: true };

      } else {
        await client.query(
          'UPDATE cotisations SET statut = $1 WHERE reference_transaction = $2',
          ['en_attente', reference]
        );
        await client.query('COMMIT');
        return { success: false, message: 'Paiement échoué ou annulé' };
      }

    } catch (err) {
      await client.query('ROLLBACK');
      logger.error('Erreur confirmerPaiement:', err);
      throw err;
    } finally {
      client.release();
    }
  },

  async mettreAJourScoreFiabilite(userId, paiementATemps, client) {
    const variation = paiementATemps ? 2 : -5;
    await client.query(`
      UPDATE utilisateurs SET
        score_fiabilite = LEAST(100, GREATEST(0, score_fiabilite + $1)),
        updated_at = NOW()
      WHERE id = $2
    `, [variation, userId]);
  },

  async verifierTourSuivant(tontineId, client) {
    const { rows: membres } = await client.query(`
      SELECT mt.utilisateur_id, mt.position_rotation, mt.a_recu,
        COUNT(CASE WHEN c.statut = 'paye' THEN 1 END) as nb_payes,
        COUNT(c.id) as total
      FROM membres_tontine mt
      LEFT JOIN cotisations c ON c.membre_id = mt.utilisateur_id
        AND c.tontine_id = mt.tontine_id
        AND c.periode_numero = (
          SELECT MAX(periode_numero) FROM cotisations WHERE tontine_id = $1 AND statut = 'paye'
        )
      WHERE mt.tontine_id = $1 AND mt.est_actif = true
      GROUP BY mt.utilisateur_id, mt.position_rotation, mt.a_recu
      ORDER BY mt.position_rotation
    `, [tontineId]);

    const tousOntPaye = membres.every(m => parseInt(m.nb_payes) > 0);

    if (tousOntPaye) {
      const prochainBeneficiaire = membres.find(m => !m.a_recu);
      if (prochainBeneficiaire) {
        await client.query(`
          UPDATE membres_tontine SET a_recu = true, date_reception = NOW()
          WHERE tontine_id = $1 AND utilisateur_id = $2
        `, [tontineId, prochainBeneficiaire.utilisateur_id]);

        const { rows: tontineRows } = await client.query(
          'SELECT nom FROM tontines WHERE id = $1', [tontineId]
        );

        await notificationService.notifierMembre(prochainBeneficiaire.utilisateur_id, {
          type: 'tour_prochain',
          tontine_id: tontineId,
          nom_tontine: tontineRows[0]?.nom,
          date: new Date().toLocaleDateString('fr-FR')
        });
      }
    }
  },

  async enregistrerDepotPhysique(data) {
    const { cotisation_id, montant, responsable_id, note } = data;
    try {
      const { rows } = await pool.query(`
        UPDATE cotisations SET
          statut = 'paye',
          date_paiement = NOW(),
          methode_paiement = 'depot_physique',
          reference_transaction = $1
        WHERE id = $2
        RETURNING *
      `, [`DEPOT-${Date.now()}`, cotisation_id]);

      if (rows[0]) {
        await notificationService.notifierMembre(rows[0].membre_id, {
          type: 'paiement_confirme',
          tontine_id: rows[0].tontine_id,
          montant
        });
      }

      return { success: true, data: rows[0] };
    } catch (err) {
      logger.error('Erreur depotPhysique:', err);
      throw err;
    }
  }
};

module.exports = paiementService;
