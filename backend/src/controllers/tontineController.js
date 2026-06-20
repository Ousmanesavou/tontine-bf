const { pool } = require('../../config/database');
const { deleteCache } = require('../../config/redis');
const notificationService = require('../services/notificationService');
const logger = require('../utils/logger');
const { v4: uuidv4 } = require('uuid');

const tontineController = {

  async getMesTontines(req, res) {
    try {
      const { rows } = await pool.query(`
        SELECT t.*, mt.position_rotation, mt.a_recu,
          COUNT(mt2.id) as total_membres,
          SUM(CASE WHEN c.statut = 'paye' THEN 1 ELSE 0 END) as membres_payes_periode_actuelle
        FROM tontines t
        JOIN membres_tontine mt ON mt.tontine_id = t.id AND mt.utilisateur_id = $1
        LEFT JOIN membres_tontine mt2 ON mt2.tontine_id = t.id AND mt2.est_actif = true
        LEFT JOIN cotisations c ON c.tontine_id = t.id AND c.periode_numero = (
          SELECT COALESCE(MAX(periode_numero), 1) FROM cotisations WHERE tontine_id = t.id
        )
        WHERE t.statut = 'active'
        GROUP BY t.id, mt.position_rotation, mt.a_recu
        ORDER BY t.created_at DESC
      `, [req.user.id]);

      const tontinesAvecCompte = rows.map(t => ({
        ...t,
        jours_restants: calculerJoursRestants(t),
        pourcentage_completion: Math.round((t.membres_payes_periode_actuelle / t.total_membres) * 100)
      }));

      res.json({ success: true, data: tontinesAvecCompte });
    } catch (err) {
      logger.error('Erreur getMesTontines:', err);
      res.status(500).json({ error: 'Erreur lors du chargement des tontines' });
    }
  },

  async creerTontine(req, res) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const {
        nom, type, description, montant_cotisation, periodicite,
        periodicite_jours, nombre_membres, date_debut,
        ordre_rotation, produit_catalogue_id
      } = req.body;

      const date_fin = calculerDateFin(date_debut, periodicite, periodicite_jours, nombre_membres);

      const { rows } = await client.query(`
        INSERT INTO tontines (nom, type, description, montant_cotisation, periodicite,
          periodicite_jours, nombre_membres, date_debut, date_fin, ordre_rotation,
          responsable_id, produit_catalogue_id)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
        RETURNING *
      `, [nom, type, description, montant_cotisation, periodicite,
          periodicite_jours || 1, nombre_membres, date_debut, date_fin,
          ordre_rotation || 'tirage_sort', req.user.id, produit_catalogue_id || null]);

      const tontine = rows[0];

      await client.query(`
        INSERT INTO membres_tontine (tontine_id, utilisateur_id, position_rotation)
        VALUES ($1, $2, 1)
      `, [tontine.id, req.user.id]);

      await genererCotisations(client, tontine);

      await client.query('COMMIT');

      logger.info(`Tontine créée: ${tontine.id} par ${req.user.id}`);
      res.status(201).json({ success: true, data: tontine });

    } catch (err) {
      await client.query('ROLLBACK');
      logger.error('Erreur creerTontine:', err);
      res.status(500).json({ error: 'Erreur lors de la création de la tontine' });
    } finally {
      client.release();
    }
  },

  async getTontine(req, res) {
    try {
      const { rows } = await pool.query(`
        SELECT t.*,
          json_agg(json_build_object(
            'id', u.id, 'nom', u.nom, 'prenom', u.prenom,
            'telephone', u.telephone, 'position', mt.position_rotation,
            'a_recu', mt.a_recu, 'score_fiabilite', u.score_fiabilite
          ) ORDER BY mt.position_rotation) as membres
        FROM tontines t
        LEFT JOIN membres_tontine mt ON mt.tontine_id = t.id AND mt.est_actif = true
        LEFT JOIN utilisateurs u ON u.id = mt.utilisateur_id
        WHERE t.id = $1
        GROUP BY t.id
      `, [req.params.id]);

      if (!rows[0]) return res.status(404).json({ error: 'Tontine non trouvée' });

      const tontine = {
        ...rows[0],
        jours_restants: calculerJoursRestants(rows[0]),
        prochain_beneficiaire: rows[0].membres?.find(m => !m.a_recu)
      };

      res.json({ success: true, data: tontine });
    } catch (err) {
      logger.error('Erreur getTontine:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async inviterMembre(req, res) {
    try {
      const { telephone } = req.body;
      const tontine_id = req.params.id;

      const { rows: userRows } = await pool.query(
        'SELECT * FROM utilisateurs WHERE telephone = $1', [telephone]
      );

      if (!userRows[0]) {
        await notificationService.envoyerSMS(telephone, {
          type: 'invitation_tontine',
          tontine_id,
          langue: 'fr'
        });
        return res.json({ success: true, message: 'Invitation SMS envoyée' });
      }

      const user = userRows[0];
      const { rows: membreRows } = await pool.query(
        'SELECT * FROM membres_tontine WHERE tontine_id = $1 AND utilisateur_id = $2',
        [tontine_id, user.id]
      );

      if (membreRows[0]) {
        return res.status(400).json({ error: 'Cette personne est déjà membre' });
      }

      const { rows: countRows } = await pool.query(
        'SELECT COUNT(*) as total FROM membres_tontine WHERE tontine_id = $1 AND est_actif = true',
        [tontine_id]
      );

      const { rows: tontineRows } = await pool.query(
        'SELECT nombre_membres FROM tontines WHERE id = $1', [tontine_id]
      );

      if (parseInt(countRows[0].total) >= tontineRows[0].nombre_membres) {
        return res.status(400).json({ error: 'Le groupe est complet' });
      }

      const position = parseInt(countRows[0].total) + 1;
      await pool.query(
        'INSERT INTO membres_tontine (tontine_id, utilisateur_id, position_rotation) VALUES ($1,$2,$3)',
        [tontine_id, user.id, position]
      );

      await notificationService.notifierMembre(user.id, {
        type: 'nouveau_membre_tontine',
        tontine_id,
        langue: user.langue
      });

      res.json({ success: true, message: 'Membre invité avec succès' });
    } catch (err) {
      logger.error('Erreur inviterMembre:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async getStatistiques(req, res) {
    try {
      const { rows } = await pool.query(`
        SELECT
          COUNT(c.id) as total_cotisations,
          SUM(CASE WHEN c.statut = 'paye' THEN c.montant ELSE 0 END) as montant_collecte,
          SUM(CASE WHEN c.statut = 'en_attente' THEN c.montant ELSE 0 END) as montant_attendu,
          COUNT(CASE WHEN c.statut = 'en_retard' THEN 1 END) as cotisations_en_retard,
          AVG(u.score_fiabilite) as score_moyen_groupe
        FROM cotisations c
        JOIN utilisateurs u ON u.id = c.membre_id
        WHERE c.tontine_id = $1
      `, [req.params.id]);

      res.json({ success: true, data: rows[0] });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async getCotisations(req, res) {
    try {
      const { rows } = await pool.query(`
        SELECT c.*, u.nom, u.prenom, u.telephone
        FROM cotisations c
        JOIN utilisateurs u ON u.id = c.membre_id
        WHERE c.tontine_id = $1
        ORDER BY c.periode_numero DESC, c.date_echeance DESC
      `, [req.params.id]);

      res.json({ success: true, data: rows });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async getMembres(req, res) {
    try {
      const { rows } = await pool.query(`
        SELECT u.id, u.nom, u.prenom, u.telephone, u.score_fiabilite,
          mt.position_rotation, mt.a_recu, mt.date_reception,
          COUNT(CASE WHEN c.statut = 'paye' THEN 1 END) as total_paiements,
          COUNT(CASE WHEN c.statut = 'en_retard' THEN 1 END) as total_retards
        FROM membres_tontine mt
        JOIN utilisateurs u ON u.id = mt.utilisateur_id
        LEFT JOIN cotisations c ON c.membre_id = u.id AND c.tontine_id = mt.tontine_id
        WHERE mt.tontine_id = $1 AND mt.est_actif = true
        GROUP BY u.id, mt.position_rotation, mt.a_recu, mt.date_reception
        ORDER BY mt.position_rotation
      `, [req.params.id]);

      res.json({ success: true, data: rows });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async demanderEmprunt(req, res) {
    try {
      const { montant, date_echeance, raison } = req.body;
      const { rows } = await pool.query(`
        INSERT INTO emprunts (tontine_id, emprunteur_id, montant, date_echeance)
        VALUES ($1,$2,$3,$4) RETURNING *
      `, [req.params.id, req.user.id, montant, date_echeance]);

      await notificationService.notifierGroupeTontine(req.params.id, {
        type: 'demande_emprunt',
        emprunt_id: rows[0].id,
        montant
      });

      res.status(201).json({ success: true, data: rows[0] });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async genererRapport(req, res) {
    try {
      const [tontine, membres, cotisations] = await Promise.all([
        pool.query('SELECT * FROM tontines WHERE id = $1', [req.params.id]),
        pool.query('SELECT u.nom, u.prenom, mt.position_rotation, mt.a_recu FROM membres_tontine mt JOIN utilisateurs u ON u.id = mt.utilisateur_id WHERE mt.tontine_id = $1', [req.params.id]),
        pool.query('SELECT * FROM cotisations WHERE tontine_id = $1 ORDER BY periode_numero, date_echeance', [req.params.id])
      ]);

      const rapport = {
        tontine: tontine.rows[0],
        membres: membres.rows,
        cotisations: cotisations.rows,
        resume: {
          total_collecte: cotisations.rows.filter(c => c.statut === 'paye').reduce((sum, c) => sum + parseFloat(c.montant), 0),
          taux_paiement: Math.round((cotisations.rows.filter(c => c.statut === 'paye').length / cotisations.rows.length) * 100),
          genere_le: new Date()
        }
      };

      res.json({ success: true, data: rapport });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async modifierTontine(req, res) {
    res.json({ success: true, message: 'Modification en cours de développement' });
  },

  async supprimerTontine(req, res) {
    res.json({ success: true, message: 'Suppression en cours de développement' });
  },

  async rejoindreTontine(req, res) {
    res.json({ success: true, message: 'Rejoindre en cours de développement' });
  },

  async retirerMembre(req, res) {
    res.json({ success: true, message: 'Retrait en cours de développement' });
  },

  async voterEmprunt(req, res) {
    res.json({ success: true, message: 'Vote en cours de développement' });
  },

  async rembourserEmprunt(req, res) {
    res.json({ success: true, message: 'Remboursement en cours de développement' });
  }
};

function calculerJoursRestants(tontine) {
  const prochainePeriode = new Date();
  const debut = new Date(tontine.date_debut);
  const joursEcoules = Math.floor((prochainePeriode - debut) / (1000 * 60 * 60 * 24));
  const jours = tontine.periodicite_jours || 1;
  const periodeActuelle = Math.floor(joursEcoules / jours);
  const prochainePeriodeDate = new Date(debut);
  prochainePeriodeDate.setDate(debut.getDate() + (periodeActuelle + 1) * jours);
  return Math.max(0, Math.floor((prochainePeriodeDate - new Date()) / (1000 * 60 * 60 * 24)));
}

function calculerDateFin(dateDebut, periodicite, periodicitejours, nombreMembres) {
  const debut = new Date(dateDebut);
  const jours = periodicitejours || 1;
  const fin = new Date(debut);
  fin.setDate(debut.getDate() + jours * nombreMembres);
  return fin;
}

async function genererCotisations(client, tontine) {
  const debut = new Date(tontine.date_debut);
  const jours = tontine.periodicite_jours || 1;
  const { rows: membres } = await client.query(
    'SELECT utilisateur_id FROM membres_tontine WHERE tontine_id = $1 ORDER BY position_rotation',
    [tontine.id]
  );
  for (let periode = 1; periode <= tontine.nombre_membres; periode++) {
    const dateEcheance = new Date(debut);
    dateEcheance.setDate(debut.getDate() + jours * (periode - 1));
    for (const membre of membres) {
      await client.query(`
        INSERT INTO cotisations (tontine_id, membre_id, montant, periode_numero, date_echeance)
        VALUES ($1,$2,$3,$4,$5)
      `, [tontine.id, membre.utilisateur_id, tontine.montant_cotisation, periode, dateEcheance]);
    }
  }
}

module.exports = tontineController;
