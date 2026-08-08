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

    // NOUVEAU: vérification des déclarations de paiement USSD en attente
    // — toutes les 6h. Rappel à l'organisateur après 24h sans traitement,
    // puis escalade vers organisateur + tous les admins après 48h.
    cron.schedule('0 */6 * * *', async () => {
      logger.info('CRON: Vérification déclarations USSD en attente...');
      await this.verifierDeclarationsEnAttente();
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
        SELECT DISTINCT c.membre_id, c.tontine_id,
          COALESCE(mt.a_recu, false) as a_deja_recu
        FROM cotisations c
        LEFT JOIN membres_tontine mt ON mt.tontine_id = c.tontine_id AND mt.utilisateur_id = c.membre_id
        WHERE c.statut = 'en_retard'
          AND c.date_paiement IS NULL
          AND c.date_echeance >= NOW() - INTERVAL '1 day'
      `);

      for (const row of rows) {
        // FIX: pénalité renforcée si le membre a déjà reçu son tour dans
        // CETTE tontine — un retard après réception est bien plus grave
        // qu'un retard classique, puisque les membres suivants comptent
        // sur ce paiement pour recevoir le leur.
        const penalite = row.a_deja_recu ? 20 : 5;

        await pool.query(`
          UPDATE utilisateurs SET
            score_fiabilite = GREATEST(0, score_fiabilite - $1),
            updated_at = NOW()
          WHERE id = $2
        `, [penalite, row.membre_id]);

        if (row.a_deja_recu) {
          // NOUVEAU: alerte immédiate à l'organisateur et aux autres
          // membres — c'est le risque le plus dangereux d'une tontine
          // tournante (abandon après réception du tour).
          const { rows: [tontine] } = await pool.query(
            'SELECT nom FROM tontines WHERE id = $1', [row.tontine_id]
          );
          const { rows: [membreInfo] } = await pool.query(
            'SELECT prenom, nom FROM utilisateurs WHERE id = $1', [row.membre_id]
          );
          if (tontine) {
            await notificationService.notifierGroupeTontine(row.tontine_id, {
              type: 'retard_paiement',
              nom_tontine: tontine.nom,
              montant: `ALERTE : ${membreInfo?.prenom || ''} ${membreInfo?.nom || ''} a déjà reçu son tour et est maintenant en retard de cotisation`,
              tontine_id: row.tontine_id,
            });
          }
        }
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
  },

  // NOUVEAU
  async verifierDeclarationsEnAttente() {
    try {
      // Palier 1: rappel simple à l'organisateur après 24h
      const { rows: premiereAlerte } = await pool.query(`
        SELECT d.*, t.nom as nom_tontine, t.responsable_id, u.prenom, u.nom
        FROM declarations_paiement_ussd d
        JOIN tontines t ON t.id = d.tontine_id
        JOIN utilisateurs u ON u.id = d.membre_id
        WHERE d.statut = 'en_attente_verification'
          AND d.nombre_alertes = 0
          AND d.created_at < NOW() - INTERVAL '24 hours'
      `);

      for (const d of premiereAlerte) {
        const nomComplet = `${d.prenom || ''} ${d.nom || ''}`.trim();
        const messageOverride = notificationService.getMessage(
          'rappel_declaration_attente', 'fr', nomComplet, d.montant_declare, d.nom_tontine
        );
        await notificationService.notifierMembre(d.responsable_id, {
          type: 'rappel_declaration_attente',
          tontine_id: d.tontine_id,
          message_override: messageOverride,
        });
        await pool.query(`
          UPDATE declarations_paiement_ussd
          SET nombre_alertes = 1, derniere_alerte_envoyee = NOW()
          WHERE id = $1
        `, [d.id]);
      }

      // Palier 2: escalade vers organisateur + TOUS les admins après 48h
      const { rows: escalade } = await pool.query(`
        SELECT d.*, t.nom as nom_tontine, t.responsable_id, u.prenom, u.nom
        FROM declarations_paiement_ussd d
        JOIN tontines t ON t.id = d.tontine_id
        JOIN utilisateurs u ON u.id = d.membre_id
        WHERE d.statut = 'en_attente_verification'
          AND d.nombre_alertes = 1
          AND d.created_at < NOW() - INTERVAL '48 hours'
      `);

      for (const d of escalade) {
        const nomComplet = `${d.prenom || ''} ${d.nom || ''}`.trim();
        const messageOverride = notificationService.getMessage(
          'rappel_declaration_attente', 'fr', nomComplet, d.montant_declare, d.nom_tontine
        );
        const notifOptions = {
          type: 'rappel_declaration_attente',
          tontine_id: d.tontine_id,
          message_override: messageOverride,
        };
        await notificationService.notifierMembre(d.responsable_id, notifOptions);
        await notificationService.notifierTousLesAdmins(notifOptions);
        await pool.query(`
          UPDATE declarations_paiement_ussd
          SET nombre_alertes = 2, derniere_alerte_envoyee = NOW()
          WHERE id = $1
        `, [d.id]);
      }

      logger.info(`Déclarations USSD: ${premiereAlerte.length} rappels 24h, ${escalade.length} escalades 48h`);
    } catch (err) {
      logger.error('Erreur verifierDeclarationsEnAttente:', err.message);
    }
  }
};

module.exports = cronJobs;
