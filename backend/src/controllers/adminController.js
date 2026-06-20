const { pool } = require('../../config/database');
const logger = require('../utils/logger');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const adminController = {

  async loginAdmin(req, res) {
    try {
      const { email, password } = req.body;
      const { rows } = await pool.query(
        "SELECT * FROM utilisateurs WHERE telephone = $1 AND role = 'admin'",
        [email]
      );
      if (!rows[0]) return res.status(401).json({ error: 'Accès refusé' });

      const valide = await bcrypt.compare(password, rows[0].code_pin);
      if (!valide) return res.status(401).json({ error: 'Mot de passe incorrect' });

      const token = jwt.sign(
        { userId: rows[0].id, role: 'admin' },
        process.env.JWT_SECRET,
        { expiresIn: '1d' }
      );
      res.json({ success: true, token, user: { nom: rows[0].nom, prenom: rows[0].prenom } });
    } catch (err) {
      logger.error('Erreur loginAdmin:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async getStats(req, res) {
    try {
      const [users, tontines, cotisations, retards,
             usersSemaine, tontinesMois,
             transactionsParMois, langues, typesTontines, methodes] = await Promise.all([
        pool.query("SELECT COUNT(*) as total FROM utilisateurs WHERE est_actif = true AND role = 'user'"),
        pool.query("SELECT COUNT(*) as total FROM tontines WHERE statut = 'active'"),
        pool.query("SELECT COALESCE(SUM(montant),0) as total FROM cotisations WHERE statut='paye' AND date_paiement >= date_trunc('month',NOW())"),
        pool.query("SELECT COUNT(*) as total FROM cotisations WHERE statut='en_retard'"),
        pool.query("SELECT COUNT(*) as total FROM utilisateurs WHERE created_at >= NOW() - INTERVAL '7 days' AND role='user'"),
        pool.query("SELECT COUNT(*) as total FROM tontines WHERE created_at >= date_trunc('month',NOW())"),
        pool.query(`
          SELECT to_char(date_trunc('month',date_paiement),'Mon YYYY') as mois,
            COALESCE(SUM(montant),0) as total
          FROM cotisations WHERE statut='paye'
          AND date_paiement >= NOW() - INTERVAL '6 months'
          GROUP BY date_trunc('month',date_paiement)
          ORDER BY date_trunc('month',date_paiement)
        `),
        pool.query("SELECT langue, COUNT(*) as total FROM utilisateurs WHERE role='user' GROUP BY langue"),
        pool.query("SELECT type, COUNT(*) as total FROM tontines GROUP BY type"),
        pool.query("SELECT methode_paiement, COUNT(*) as total FROM cotisations WHERE statut='paye' AND methode_paiement IS NOT NULL GROUP BY methode_paiement"),
      ]);

      res.json({
        success: true,
        data: {
          total_users: parseInt(users.rows[0].total),
          tontines_actives: parseInt(tontines.rows[0].total),
          transactions_mois: parseFloat(cotisations.rows[0].total),
          retards: parseInt(retards.rows[0].total),
          nouveaux_users_semaine: parseInt(usersSemaine.rows[0].total),
          nouvelles_tontines_mois: parseInt(tontinesMois.rows[0].total),
          transactions_par_mois: transactionsParMois.rows,
          langues: langues.rows,
          types_tontines: typesTontines.rows,
          methodes_paiement: methodes.rows,
        }
      });
    } catch (err) {
      logger.error('Erreur getStats:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async getAlerts(req, res) {
    try {
      const [retards, echeances, taux] = await Promise.all([
        pool.query(`
          SELECT u.nom, u.prenom, c.montant, c.date_echeance, t.nom as tontine,
            NOW()::date - c.date_echeance as jours_retard
          FROM cotisations c
          JOIN utilisateurs u ON u.id = c.membre_id
          JOIN tontines t ON t.id = c.tontine_id
          WHERE c.statut = 'en_retard'
          ORDER BY c.date_echeance ASC LIMIT 10
        `),
        pool.query(`
          SELECT t.nom, t.date_fin,
            t.date_fin - NOW()::date as jours_restants
          FROM tontines t
          WHERE t.statut = 'active'
          AND t.date_fin BETWEEN NOW() AND NOW() + INTERVAL '7 days'
        `),
        pool.query(`
          SELECT ROUND(
            COUNT(CASE WHEN statut='paye' THEN 1 END)::numeric /
            NULLIF(COUNT(*),0) * 100, 1
          ) as taux
          FROM cotisations
          WHERE date_echeance >= date_trunc('month', NOW())
        `),
      ]);

      res.json({
        success: true,
        data: {
          retards: retards.rows,
          echeances_proches: echeances.rows,
          taux_paiement: parseFloat(taux.rows[0]?.taux || 0),
        }
      });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async getAllUsers(req, res) {
    try {
      const { page = 1, limit = 20, search = '', statut = '' } = req.query;
      const offset = (page - 1) * limit;
      const params = [];
      let where = "WHERE u.role = 'user'";

      if (search) {
        params.push(`%${search}%`);
        where += ` AND (u.nom ILIKE $${params.length} OR u.prenom ILIKE $${params.length} OR u.telephone ILIKE $${params.length})`;
      }
      if (statut === 'actif') where += ' AND u.est_actif = true';
      if (statut === 'inactif') where += ' AND u.est_actif = false';

      const { rows } = await pool.query(`
        SELECT u.id, u.nom, u.prenom, u.telephone, u.langue,
          u.score_fiabilite, u.est_actif, u.created_at,
          COUNT(DISTINCT mt.tontine_id) as nb_tontines,
          COUNT(DISTINCT CASE WHEN c.statut='en_retard' THEN c.id END) as nb_retards
        FROM utilisateurs u
        LEFT JOIN membres_tontine mt ON mt.utilisateur_id = u.id
        LEFT JOIN cotisations c ON c.membre_id = u.id
        ${where}
        GROUP BY u.id
        ORDER BY u.created_at DESC
        LIMIT $${params.length + 1} OFFSET $${params.length + 2}
      `, [...params, limit, offset]);

      const { rows: count } = await pool.query(
        `SELECT COUNT(*) as total FROM utilisateurs u ${where}`, params
      );

      res.json({ success: true, data: rows, total: parseInt(count[0].total) });
    } catch (err) {
      logger.error('Erreur getAllUsers:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async bloquerUser(req, res) {
    try {
      await pool.query('UPDATE utilisateurs SET est_actif=false WHERE id=$1', [req.params.id]);
      res.json({ success: true, message: 'Utilisateur bloqué' });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async debloquerUser(req, res) {
    try {
      await pool.query('UPDATE utilisateurs SET est_actif=true WHERE id=$1', [req.params.id]);
      res.json({ success: true, message: 'Utilisateur débloqué' });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async getAllTontines(req, res) {
    try {
      const { page = 1, limit = 20, type = '', statut = '' } = req.query;
      const offset = (page - 1) * limit;
      const params = [];
      let where = 'WHERE 1=1';

      if (type) { params.push(type); where += ` AND t.type=$${params.length}`; }
      if (statut) { params.push(statut); where += ` AND t.statut=$${params.length}`; }

      const { rows } = await pool.query(`
        SELECT t.*,
          u.nom as responsable_nom, u.prenom as responsable_prenom,
          COUNT(DISTINCT mt.utilisateur_id) as total_membres,
          COUNT(CASE WHEN c.statut='paye' THEN 1 END) as cotisations_payees,
          COUNT(c.id) as total_cotisations,
          COALESCE(SUM(CASE WHEN c.statut='paye' THEN c.montant END),0) as total_collecte
        FROM tontines t
        LEFT JOIN utilisateurs u ON u.id=t.responsable_id
        LEFT JOIN membres_tontine mt ON mt.tontine_id=t.id
        LEFT JOIN cotisations c ON c.tontine_id=t.id
        ${where}
        GROUP BY t.id, u.nom, u.prenom
        ORDER BY t.created_at DESC
        LIMIT $${params.length+1} OFFSET $${params.length+2}
      `, [...params, limit, offset]);

      const { rows: count } = await pool.query(
        `SELECT COUNT(*) as total FROM tontines t ${where}`, params
      );

      res.json({ success: true, data: rows, total: parseInt(count[0].total) });
    } catch (err) {
      logger.error('Erreur getAllTontines:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async getAllPaiements(req, res) {
    try {
      const { page = 1, limit = 20, methode = '' } = req.query;
      const offset = (page - 1) * limit;
      const params = [];
      let where = 'WHERE c.statut IS NOT NULL';

      if (methode) { params.push(methode); where += ` AND c.methode_paiement=$${params.length}`; }

      const { rows } = await pool.query(`
        SELECT c.id, c.montant, c.statut, c.methode_paiement,
          c.date_paiement, c.reference_transaction, c.date_echeance,
          u.nom, u.prenom, u.telephone,
          t.nom as nom_tontine
        FROM cotisations c
        JOIN utilisateurs u ON u.id=c.membre_id
        JOIN tontines t ON t.id=c.tontine_id
        ${where}
        ORDER BY c.created_at DESC
        LIMIT $${params.length+1} OFFSET $${params.length+2}
      `, [...params, limit, offset]);

      res.json({ success: true, data: rows });
    } catch (err) {
      logger.error('Erreur getAllPaiements:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async getCatalogue(req, res) {
    try {
      const { rows } = await pool.query(
        'SELECT * FROM catalogue_produits ORDER BY created_at DESC'
      );
      res.json({ success: true, data: rows });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async ajouterProduit(req, res) {
    try {
      const { nom, categorie, description, prix, fournisseur_nom,
              fournisseur_contact, livraison_disponible, emoji } = req.body;
      const { rows } = await pool.query(`
        INSERT INTO catalogue_produits
          (nom, categorie, description, prix, fournisseur_nom,
           fournisseur_contact, livraison_disponible, photos)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
        RETURNING *
      `, [nom, categorie, description, prix, fournisseur_nom,
          fournisseur_contact, livraison_disponible || false,
          JSON.stringify([emoji || '📦'])]);
      res.status(201).json({ success: true, data: rows[0] });
    } catch (err) {
      logger.error('Erreur ajouterProduit:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async modifierProduit(req, res) {
    try {
      const { nom, categorie, prix, description, est_actif } = req.body;
      const { rows } = await pool.query(`
        UPDATE catalogue_produits SET
          nom=$1, categorie=$2, prix=$3, description=$4, est_actif=$5
        WHERE id=$6 RETURNING *
      `, [nom, categorie, prix, description, est_actif, req.params.id]);
      res.json({ success: true, data: rows[0] });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async supprimerProduit(req, res) {
    try {
      await pool.query(
        'UPDATE catalogue_produits SET est_actif=false WHERE id=$1',
        [req.params.id]
      );
      res.json({ success: true, message: 'Produit désactivé' });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async getFournisseurs(req, res) {
    try {
      const { rows } = await pool.query(
        'SELECT * FROM fournisseurs ORDER BY created_at DESC'
      );
      res.json({ success: true, data: rows });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async ajouterFournisseur(req, res) {
    try {
      const { nom, categorie, telephone, adresse, livraison_disponible } = req.body;
      const { rows } = await pool.query(`
        INSERT INTO fournisseurs (nom, categorie, telephone, adresse, livraison_disponible)
        VALUES ($1,$2,$3,$4,$5) RETURNING *
      `, [nom, categorie, telephone, adresse, livraison_disponible || false]);
      res.status(201).json({ success: true, data: rows[0] });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async modifierFournisseur(req, res) {
    try {
      const { nom, categorie, telephone, adresse, livraison_disponible, est_actif } = req.body;
      const { rows } = await pool.query(`
        UPDATE fournisseurs SET
          nom=$1, categorie=$2, telephone=$3, adresse=$4,
          livraison_disponible=$5, est_actif=$6
        WHERE id=$7 RETURNING *
      `, [nom, categorie, telephone, adresse, livraison_disponible, est_actif, req.params.id]);
      res.json({ success: true, data: rows[0] });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async envoyerNotificationMasse(req, res) {
    try {
      const { titre, message_fr, message_moore, message_dioula, destinataires, canal } = req.body;
      let query = "SELECT id, langue FROM utilisateurs WHERE est_actif=true AND role='user'";

      if (destinataires === 'retards') {
        query = `SELECT DISTINCT u.id, u.langue FROM utilisateurs u
                 JOIN cotisations c ON c.membre_id=u.id
                 WHERE c.statut='en_retard' AND u.est_actif=true AND u.role='user'`;
      } else if (destinataires === 'responsables') {
        query = `SELECT DISTINCT u.id, u.langue FROM utilisateurs u
                 JOIN tontines t ON t.responsable_id=u.id
                 WHERE u.est_actif=true AND u.role='user'`;
      } else if (destinataires === 'inactifs') {
        query = `SELECT u.id, u.langue FROM utilisateurs u
                 WHERE u.est_actif=true AND u.role='user'
                 AND u.id NOT IN (
                   SELECT DISTINCT membre_id FROM cotisations
                   WHERE date_paiement >= NOW() - INTERVAL '30 days'
                 )`;
      }

      const { rows: users } = await pool.query(query);

      for (const user of users) {
        const message = user.langue === 'moore' ? (message_moore || message_fr)
          : user.langue === 'dioula' ? (message_dioula || message_fr)
          : message_fr;

        await pool.query(`
          INSERT INTO notifications
            (utilisateur_id, type, titre, message, message_moore, message_dioula, canal)
          VALUES ($1,'admin',$2,$3,$4,$5,$6)
        `, [user.id, titre, message, message_moore, message_dioula, canal || 'push']);
      }

      await pool.query(`
        INSERT INTO notifications_admin
          (titre, message_fr, message_moore, message_dioula, destinataires, canal,
           nb_envoyes, envoye_par)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
      `, [titre, message_fr, message_moore, message_dioula, destinataires,
          canal, users.length, req.user.id]);

      res.json({ success: true, message: `Notification envoyée à ${users.length} utilisateurs` });
    } catch (err) {
      logger.error('Erreur envoyerNotification:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },
};

module.exports = adminController;