const cron = require('node-cron');
const notificationService = require('./notificationService');
const { pool } = require('../../config/database');
const logger = require('../utils/logger');

const cronJobs = {
  init() {
    // Rappels cotisations - chaque matin à 8h
    cron.schedule('0 8 * * *', async () => {
      logger.info('CRON: Envoi rappels cotisations...');
      await notificationService.envoyerRappelsCotisations();
    });

    // Marquer les retards - chaque jour à minuit
    cron.schedule('0 0 * * *', async () => {
      logger.info('CRON: Marquage des cotisations en retard...');
      await notificationService.marquerRetards();
      await this.mettreAJourScoresMembresEnRetard();
    });

    // Rappel urgent - chaque soir à 18h pour J-1
    cron.schedule('0 18 * * *', async () => {
      logger.info('CRON: Rappels urgents J-1...');
      await this.envoyerRappelsUrgents();
    });

    // Rapport mensuel - 1er de chaque mois à 9h
    cron.schedule('0 9 1 * *', async () => {
      logger.info('CRON: Envoi rapports mensuels...');
      await this.envoyerRapportsMensuels();
    });

    // Nettoyage sessions expirées - chaque dimanche
    cron.schedule('0 2 * * 0', async () => {
      logger.info('CRON: Nettoyage sessions...');
      await this.nettoyerSessionsExpirees();
    });

    logger.info('Jobs cron initialisés avec succès');
  },

  async envoyerRappelsUrgents() {
    try {
      const demain = new Date();
      demain.setDate(demain.getDate() + 1);
      const finDemain = new Date(demain);
      finDemain.setHours(23, 59, 59);

      const { rows } = await pool.query(`
        SELECT c.*, t.nom as nom_tontine, u.id as user_id
        FROM cotisations c
        JOIN tontines t ON t.id = c.tontine_id
        JOIN utilisateurs u ON u.id = c.membre_id
        WHERE c.statut = 'en_attente'
          AND c.date_echeance BETWEEN $1 AND $2
      `, [demain.toISOString().split('T')[0], finDemain.toISOString().split('T')[0]]);

      for (const c of rows) {
        await notificationService.notifierMembre(c.user_id, {
          type: 'rappel_cotisation',
          tontine_id: c.tontine_id,
          nom_tontine: c.nom_tontine,
          montant: c.montant,
          jours_restants: 1
        });
      }
      logger.info(`${rows.length} rappels urgents envoyés`);
    } catch (err) {
      logger.error('Erreur rappels urgents:', err);
    }
  },

  async mettreAJourScoresMembresEnRetard() {
    try {
      const { rows } = await pool.query(`
        SELECT DISTINCT membre_id FROM cotisations
        WHERE statut = 'en_retard'
          AND date_paiement IS NULL
          AND date_echeance >= NOW() - INTERVAL '1 day'
      `);

      for (const { membre_id } of rows) {
        await pool.query(`
          UPDATE utilisateurs SET
            score_fiabilite = GREATEST(0, score_fiabilite - 5),
            updated_at = NOW()
          WHERE id = $1
        `, [membre_id]);
      }
      logger.info(`Scores mis à jour pour ${rows.length} membres en retard`);
    } catch (err) {
      logger.error('Erreur mise à jour scores:', err);
    }
  },

  async envoyerRapportsMensuels() {
    try {
      const { rows: tontines } = await pool.query(`
        SELECT id, nom, responsable_id FROM tontines WHERE statut = 'active'
      `);

      for (const tontine of tontines) {
        const { rows: stats } = await pool.query(`
          SELECT
            COUNT(CASE WHEN c.statut = 'paye' THEN 1 END) as payes,
            COUNT(CASE WHEN c.statut = 'en_retard' THEN 1 END) as retards,
            SUM(CASE WHEN c.statut = 'paye' THEN c.montant ELSE 0 END) as total_collecte
          FROM cotisations c
          WHERE c.tontine_id = $1
            AND EXTRACT(MONTH FROM c.date_paiement) = EXTRACT(MONTH FROM NOW() - INTERVAL '1 month')
        `, [tontine.id]);

        await notificationService.notifierGroupeTontine(tontine.id, {
          type: 'rapport_mensuel',
          tontine_id: tontine.id,
          nom_tontine: tontine.nom,
          stats: stats[0]
        });
      }
      logger.info(`Rapports mensuels envoyés pour ${tontines.length} tontines`);
    } catch (err) {
      logger.error('Erreur rapports mensuels:', err);
    }
  },

  async nettoyerSessionsExpirees() {
    try {
      logger.info('Nettoyage sessions terminé');
    } catch (err) {
      logger.error('Erreur nettoyage:', err);
    }
  }
};

module.exports = cronJobs;
