const { pool } = require('../../config/database');
const logger = require('../utils/logger');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const notificationService = require('../services/notificationService');

const adminController = {

  // ── LOGIN ─────────────────────────────────────────────
  async loginAdmin(req, res) {
    try {
      const { email, password } = req.body;
      const { rows } = await pool.query(
        "SELECT * FROM utilisateurs WHERE (telephone=$1 OR email=$1) AND role='admin'",
        [email]
      );
      if (!rows[0]) return res.status(401).json({ error: 'Accès refusé' });

      const valide = await bcrypt.compare(password, rows[0].code_pin);
      if (!valide) return res.status(401).json({ error: 'Mot de passe incorrect' });

      const token = jwt.sign(
        { userId: rows[0].id, role: 'admin' },
        process.env.JWT_SECRET,
        { expiresIn: '8h' }
      );
      res.json({
        success: true, token,
        user: { id: rows[0].id, nom: rows[0].nom, prenom: rows[0].prenom, role: rows[0].role }
      });
    } catch (err) {
      logger.error('Erreur loginAdmin:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── STATS ─────────────────────────────────────────────
  async getStats(req, res) {
    try {
      const [
        users, tontines, cotisations, retards,
        usersSemaine, tontinesMois,
        transactionsParMois, langues, typesTontines, methodes,
        volumeVirtuel, retraitsEnAttente, commercantsActifs, paysActifs
      ] = await Promise.all([
        pool.query("SELECT COUNT(*) as total FROM utilisateurs WHERE est_actif=true AND role='user'"),
        pool.query("SELECT COUNT(*) as total FROM tontines WHERE statut='active'"),
        pool.query("SELECT COALESCE(SUM(montant),0) as total FROM cotisations WHERE statut='paye' AND date_paiement>=date_trunc('month',NOW())"),
        pool.query("SELECT COUNT(*) as total FROM cotisations WHERE statut='en_retard'"),
        pool.query("SELECT COUNT(*) as total FROM utilisateurs WHERE created_at>=NOW()-INTERVAL '7 days' AND role='user'"),
        pool.query("SELECT COUNT(*) as total FROM tontines WHERE created_at>=date_trunc('month',NOW())"),
        pool.query(`
          SELECT to_char(date_trunc('month',COALESCE(tv.created_at,c.date_paiement)),'Mon YYYY') as mois,
            COALESCE(SUM(COALESCE(tv.montant,c.montant)),0) as total,
            COUNT(*) as nb_transactions
          FROM cotisations c
          LEFT JOIN transactions_virtuelles tv ON tv.created_at=c.date_paiement
          WHERE c.statut='paye' AND c.date_paiement>=NOW()-INTERVAL '6 months'
          GROUP BY date_trunc('month',COALESCE(tv.created_at,c.date_paiement))
          ORDER BY date_trunc('month',COALESCE(tv.created_at,c.date_paiement))
        `),
        pool.query("SELECT langue, COUNT(*) as total FROM utilisateurs WHERE role='user' GROUP BY langue ORDER BY total DESC"),
        pool.query("SELECT type, COUNT(*) as total FROM tontines GROUP BY type ORDER BY total DESC"),
        pool.query("SELECT methode_paiement, COUNT(*) as total FROM cotisations WHERE statut='paye' AND methode_paiement IS NOT NULL GROUP BY methode_paiement"),
        pool.query("SELECT COALESCE(SUM(solde),0) as total FROM comptes_virtuels"),
        pool.query("SELECT COUNT(*) as total FROM transactions_virtuelles WHERE type='retrait' AND statut='approuve'"),
        pool.query("SELECT COUNT(*) as total FROM commercants WHERE statut='valide'"),
        pool.query("SELECT COUNT(DISTINCT pays) as total FROM utilisateurs WHERE pays IS NOT NULL AND role='user'"),
      ]);

      // Stats par pays
      const { rows: parPays } = await pool.query(
        "SELECT COALESCE(pays,'BF') as pays, COUNT(*) as total FROM utilisateurs WHERE role='user' GROUP BY pays ORDER BY total DESC LIMIT 10"
      );

      res.json({
        success: true,
        data: {
          total_users: parseInt(users.rows[0].total),
          tontines_actives: parseInt(tontines.rows[0].total),
          transactions_mois: parseFloat(cotisations.rows[0].total),
          retards: parseInt(retards.rows[0].total),
          nouveaux_users_semaine: parseInt(usersSemaine.rows[0].total),
          nouvelles_tontines_mois: parseInt(tontinesMois.rows[0].total),
          volume_virtuel_total: parseFloat(volumeVirtuel.rows[0].total),
          retraits_en_attente: parseInt(retraitsEnAttente.rows[0].total),
          commercants_actifs: parseInt(commercantsActifs.rows[0].total),
          pays_actifs: parseInt(paysActifs.rows[0].total),
          transactions_par_mois: transactionsParMois.rows,
          langues: langues.rows,
          types_tontines: typesTontines.rows,
          methodes_paiement: methodes.rows,
          par_pays: parPays,
        }
      });
    } catch (err) {
      logger.error('Erreur getStats:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── ALERTES ───────────────────────────────────────────
  async getAlerts(req, res) {
    try {
      const [retards, echeances, taux, retraitsAttente, commercantsAttente] = await Promise.all([
        pool.query(`
          SELECT u.nom, u.prenom, c.montant, c.date_echeance, t.nom as tontine,
            EXTRACT(DAY FROM NOW()-c.date_echeance::timestamp)::int as jours_retard
          FROM cotisations c
          JOIN utilisateurs u ON u.id=c.membre_id
          JOIN tontines t ON t.id=c.tontine_id
          WHERE c.statut='en_retard'
          ORDER BY c.date_echeance ASC LIMIT 10
        `),
        pool.query(`
          SELECT t.nom, t.date_fin,
            EXTRACT(DAY FROM t.date_fin::timestamp-NOW())::int as jours_restants
          FROM tontines t
          WHERE t.statut='active'
          AND t.date_fin BETWEEN NOW() AND NOW()+INTERVAL '7 days'
        `),
        pool.query(`
          SELECT ROUND(
            COUNT(CASE WHEN statut='paye' THEN 1 END)::numeric /
            NULLIF(COUNT(*),0)*100, 1
          ) as taux,
          COUNT(CASE WHEN statut='paye' THEN 1 END) as cotisations_payees
          FROM cotisations
          WHERE date_echeance>=date_trunc('month',NOW())
        `),
        pool.query("SELECT COUNT(*) as total FROM transactions_virtuelles WHERE type='retrait' AND statut='approuve'"),
        pool.query("SELECT COUNT(*) as total FROM commercants WHERE statut='en_attente'"),
      ]);

      res.json({
        success: true,
        data: {
          retards: retards.rows,
          echeances_proches: echeances.rows,
          taux_paiement: parseFloat(taux.rows[0]?.taux || 0),
          cotisations_payees: parseInt(taux.rows[0]?.cotisations_payees || 0),
          retraits_en_attente: parseInt(retraitsAttente.rows[0].total),
          commercants_en_attente: parseInt(commercantsAttente.rows[0].total),
        }
      });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── UTILISATEURS ──────────────────────────────────────
  async getAllUsers(req, res) {
    try {
      const { page=1, limit=20, search='', statut='', pays='' } = req.query;
      const offset = (page-1)*limit;
      const params = [];
      let where = "WHERE u.role='user'";

      if (search) {
        params.push(`%${search}%`);
        where += ` AND (u.nom ILIKE $${params.length} OR u.prenom ILIKE $${params.length} OR u.telephone ILIKE $${params.length})`;
      }
      if (statut === 'actif') where += ' AND u.est_actif=true AND (u.est_bloque IS NULL OR u.est_bloque=false)';
      if (statut === 'inactif') where += ' AND u.est_actif=false';
      if (statut === 'bloque') where += ' AND u.est_bloque=true';
      if (pays) { params.push(pays); where += ` AND u.pays=$${params.length}`; }

      const { rows } = await pool.query(`
        SELECT u.id, u.nom, u.prenom, u.telephone, u.langue, u.pays,
          u.score_fiabilite, u.est_actif, u.est_bloque, u.email, u.created_at,
          COUNT(DISTINCT mt.tontine_id) as nb_tontines,
          COUNT(DISTINCT CASE WHEN c.statut='en_retard' THEN c.id END) as nb_retards
        FROM utilisateurs u
        LEFT JOIN membres_tontine mt ON mt.utilisateur_id=u.id AND mt.est_actif=true
        LEFT JOIN cotisations c ON c.membre_id=u.id
        ${where}
        GROUP BY u.id
        ORDER BY u.created_at DESC
        LIMIT $${params.length+1} OFFSET $${params.length+2}
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

  async getUserDetail(req, res) {
    try {
      const { rows } = await pool.query(`
        SELECT u.*,
          json_agg(DISTINCT jsonb_build_object(
            'id', t.id, 'nom', t.nom, 'type', t.type, 'statut', t.statut,
            'montant_cotisation', t.montant_cotisation
          )) FILTER (WHERE t.id IS NOT NULL) as tontines
        FROM utilisateurs u
        LEFT JOIN membres_tontine mt ON mt.utilisateur_id=u.id AND mt.est_actif=true
        LEFT JOIN tontines t ON t.id=mt.tontine_id
        WHERE u.id=$1
        GROUP BY u.id
      `, [req.params.id]);

      if (!rows[0]) return res.status(404).json({ error: 'Utilisateur non trouvé' });
      res.json({ success: true, data: rows[0] });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async bloquerUser(req, res) {
    try {
      await pool.query(
        'UPDATE utilisateurs SET est_actif=false, est_bloque=true WHERE id=$1',
        [req.params.id]
      );
      res.json({ success: true, message: 'Utilisateur bloqué' });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async debloquerUser(req, res) {
    try {
      await pool.query(
        'UPDATE utilisateurs SET est_actif=true, est_bloque=false WHERE id=$1',
        [req.params.id]
      );
      res.json({ success: true, message: 'Utilisateur débloqué' });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── TONTINES ──────────────────────────────────────────
  async getAllTontines(req, res) {
    try {
      const { page=1, limit=20, type='', statut='', search='' } = req.query;
      const offset = (page-1)*limit;
      const params = [];
      let where = 'WHERE 1=1';

      if (type) { params.push(type); where += ` AND t.type=$${params.length}`; }
      if (statut) { params.push(statut); where += ` AND t.statut=$${params.length}`; }
      if (search) {
        params.push(`%${search}%`);
        where += ` AND (t.nom ILIKE $${params.length} OR u.nom ILIKE $${params.length})`;
      }

      const { rows } = await pool.query(`
        SELECT t.*,
          u.nom as responsable_nom, u.prenom as responsable_prenom,
          COUNT(DISTINCT mt.utilisateur_id) as total_membres,
          COUNT(CASE WHEN c.statut='paye' THEN 1 END) as cotisations_payees,
          COUNT(c.id) as total_cotisations,
          COALESCE(SUM(CASE WHEN c.statut='paye' THEN c.montant END),0) as total_collecte,
          cv.solde as solde_virtuel
        FROM tontines t
        LEFT JOIN utilisateurs u ON u.id=t.responsable_id
        LEFT JOIN membres_tontine mt ON mt.tontine_id=t.id AND mt.est_actif=true
        LEFT JOIN cotisations c ON c.tontine_id=t.id
        LEFT JOIN comptes_virtuels cv ON cv.tontine_id=t.id
        ${where}
        GROUP BY t.id, u.nom, u.prenom, cv.solde
        ORDER BY t.created_at DESC
        LIMIT $${params.length+1} OFFSET $${params.length+2}
      `, [...params, limit, offset]);

      const { rows: count } = await pool.query(
        `SELECT COUNT(*) as total FROM tontines t LEFT JOIN utilisateurs u ON u.id=t.responsable_id ${where}`, params
      );

      res.json({ success: true, data: rows, total: parseInt(count[0].total) });
    } catch (err) {
      logger.error('Erreur getAllTontines:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async getTontineDetail(req, res) {
    try {
      const { rows } = await pool.query(`
        SELECT t.*, u.nom as responsable_nom, u.prenom as responsable_prenom,
          cv.solde as solde_virtuel, cv.total_depots, cv.total_retraits
        FROM tontines t
        LEFT JOIN utilisateurs u ON u.id=t.responsable_id
        LEFT JOIN comptes_virtuels cv ON cv.tontine_id=t.id
        WHERE t.id=$1
      `, [req.params.id]);
      if (!rows[0]) return res.status(404).json({ error: 'Tontine non trouvée' });
      res.json({ success: true, data: rows[0] });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async suspendreTontine(req, res) {
    try {
      await pool.query("UPDATE tontines SET statut='suspendue' WHERE id=$1", [req.params.id]);
      res.json({ success: true, message: 'Tontine suspendue' });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async reactiverTontine(req, res) {
    try {
      await pool.query("UPDATE tontines SET statut='active' WHERE id=$1", [req.params.id]);
      res.json({ success: true, message: 'Tontine réactivée' });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── COMPTES VIRTUELS ──────────────────────────────────
  async getAllComptesVirtuels(req, res) {
    try {
      const { page=1, limit=15, search='' } = req.query;
      const offset = (page-1)*limit;
      const params = [];
      let where = 'WHERE 1=1';

      if (search) {
        params.push(`%${search}%`);
        where += ` AND t.nom ILIKE $${params.length}`;
      }

      const { rows } = await pool.query(`
        SELECT cv.*,
          t.nom as tontine_nom, t.date_fin, t.statut as tontine_statut,
          t.responsable_id,
          u.prenom as responsable_prenom, u.nom as responsable_nom,
          COUNT(DISTINCT mt.utilisateur_id) as nb_membres
        FROM comptes_virtuels cv
        JOIN tontines t ON t.id=cv.tontine_id
        LEFT JOIN utilisateurs u ON u.id=t.responsable_id
        LEFT JOIN membres_tontine mt ON mt.tontine_id=t.id AND mt.est_actif=true
        ${where}
        GROUP BY cv.id, t.nom, t.date_fin, t.statut, t.responsable_id, u.prenom, u.nom
        ORDER BY cv.solde DESC
        LIMIT $${params.length+1} OFFSET $${params.length+2}
      `, [...params, limit, offset]);

      const { rows: count } = await pool.query(
        `SELECT COUNT(*) as total FROM comptes_virtuels cv JOIN tontines t ON t.id=cv.tontine_id ${where}`, params
      );

      res.json({ success: true, data: rows, total: parseInt(count[0].total) });
    } catch (err) {
      logger.error('Erreur getAllComptesVirtuels:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async getCompteVirtuelDetail(req, res) {
    try {
      const { rows } = await pool.query(`
        SELECT cv.*, t.nom as tontine_nom, t.date_fin,
          u.prenom as responsable_prenom, u.nom as responsable_nom
        FROM comptes_virtuels cv
        JOIN tontines t ON t.id=cv.tontine_id
        LEFT JOIN utilisateurs u ON u.id=t.responsable_id
        WHERE cv.id=$1
      `, [req.params.id]);
      if (!rows[0]) return res.status(404).json({ error: 'Compte non trouvé' });
      res.json({ success: true, data: rows[0] });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async getTransactionsCompte(req, res) {
    try {
      const { rows } = await pool.query(`
        SELECT tv.*, u.prenom, u.nom, u.telephone
        FROM transactions_virtuelles tv
        LEFT JOIN utilisateurs u ON u.id=tv.utilisateur_id
        WHERE tv.compte_virtuel_id=$1
        ORDER BY tv.created_at DESC
      `, [req.params.id]);
      res.json({ success: true, data: rows });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── RETRAITS ──────────────────────────────────────────
  async getAllRetraits(req, res) {
    try {
      const { statut='', page=1, limit=20 } = req.query;
      const offset = (page-1)*limit;
      const params = [];
      let where = "WHERE tv.type='retrait'";

      if (statut) { params.push(statut); where += ` AND tv.statut=$${params.length}`; }

      const { rows } = await pool.query(`
        SELECT tv.*,
          u.prenom, u.nom, u.telephone,
          t.nom as tontine_nom,
          cv.solde as solde_compte,
          (SELECT json_agg(json_build_object(
            'utilisateur_id', vr.utilisateur_id,
            'vote', vr.vote,
            'prenom', u2.prenom, 'nom', u2.nom,
            'created_at', vr.created_at
          )) FROM votes_retrait vr
           JOIN utilisateurs u2 ON u2.id=vr.utilisateur_id
           WHERE vr.transaction_id=tv.id) as votes
        FROM transactions_virtuelles tv
        JOIN utilisateurs u ON u.id=tv.utilisateur_id
        JOIN comptes_virtuels cv ON cv.id=tv.compte_virtuel_id
        JOIN tontines t ON t.id=cv.tontine_id
        ${where}
        ORDER BY tv.created_at DESC
        LIMIT $${params.length+1} OFFSET $${params.length+2}
      `, [...params, limit, offset]);

      const { rows: count } = await pool.query(
        `SELECT COUNT(*) as total FROM transactions_virtuelles tv ${where}`, params
      );

      res.json({ success: true, data: rows, total: parseInt(count[0].total) });
    } catch (err) {
      logger.error('Erreur getAllRetraits:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async getRetraitDetail(req, res) {
    try {
      const { rows } = await pool.query(`
        SELECT tv.*,
          u.prenom, u.nom, u.telephone,
          t.nom as tontine_nom, t.id as tontine_id,
          cv.solde as solde_compte,
          (SELECT json_agg(json_build_object(
            'utilisateur_id', vr.utilisateur_id,
            'vote', vr.vote,
            'prenom', u2.prenom, 'nom', u2.nom,
            'created_at', vr.created_at
          )) FROM votes_retrait vr
           JOIN utilisateurs u2 ON u2.id=vr.utilisateur_id
           WHERE vr.transaction_id=tv.id) as votes
        FROM transactions_virtuelles tv
        JOIN utilisateurs u ON u.id=tv.utilisateur_id
        JOIN comptes_virtuels cv ON cv.id=tv.compte_virtuel_id
        JOIN tontines t ON t.id=cv.tontine_id
        WHERE tv.id=$1
      `, [req.params.id]);
      if (!rows[0]) return res.status(404).json({ error: 'Retrait non trouvé' });
      res.json({ success: true, data: rows[0] });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async validerRetrait(req, res) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const { rows: retrait } = await client.query(
        "SELECT * FROM transactions_virtuelles WHERE id=$1 AND type='retrait' AND statut='approuve'",
        [req.params.id]
      );
      if (!retrait[0]) return res.status(404).json({ error: 'Retrait non trouvé ou déjà traité' });

      // Marquer comme traité par admin
      await client.query(
        "UPDATE transactions_virtuelles SET statut='traite', traite_par=$1, traite_le=NOW() WHERE id=$2",
        [req.user.id, req.params.id]
      );

      // Déduire du solde si pas encore fait
      await client.query(
        'UPDATE comptes_virtuels SET solde=solde-$1, total_retraits=total_retraits+$1 WHERE id=$2',
        [retrait[0].montant, retrait[0].compte_virtuel_id]
      );

      // Récupérer la tontine pour notification
      const { rows: tontine } = await client.query(`
        SELECT t.nom, t.responsable_id FROM tontines t
        JOIN comptes_virtuels cv ON cv.tontine_id=t.id
        WHERE cv.id=$1
      `, [retrait[0].compte_virtuel_id]);

      await client.query('COMMIT');

      // Notifier le créateur
      if (tontine[0]) {
        await notificationService.notifierMembre(tontine[0].responsable_id, {
          type: 'tour_recu',
          nom_tontine: tontine[0].nom,
          montant: retrait[0].montant.toString(),
          tontine_id: tontine[0].id,
        });
      }

      res.json({ success: true, message: 'Retrait validé et traité avec succès' });
    } catch (err) {
      await client.query('ROLLBACK');
      logger.error('Erreur validerRetrait:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    } finally {
      client.release();
    }
  },

  async refuserRetrait(req, res) {
    try {
      const { motif = '' } = req.body;
      const { rows: retrait } = await pool.query(
        "SELECT * FROM transactions_virtuelles WHERE id=$1 AND type='retrait'",
        [req.params.id]
      );
      if (!retrait[0]) return res.status(404).json({ error: 'Retrait non trouvé' });

      await pool.query(
        "UPDATE transactions_virtuelles SET statut='refuse_admin', description=CONCAT(description,' | Refus admin: ',$1) WHERE id=$2",
        [motif, req.params.id]
      );

      // Rembourser le solde si déjà déduit
      if (retrait[0].statut === 'approuve') {
        await pool.query(
          'UPDATE comptes_virtuels SET solde=solde+$1 WHERE id=$2',
          [retrait[0].montant, retrait[0].compte_virtuel_id]
        );
      }

      res.json({ success: true, message: 'Retrait refusé' });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── TRANSACTIONS ──────────────────────────────────────
  async getAllPaiements(req, res) {
    try {
      const { page=1, limit=20, methode='', type='' } = req.query;
      const offset = (page-1)*limit;

      // Transactions virtuelles + cotisations classiques
      const params = [];
      let whereVirtuel = "WHERE 1=1";
      let whereCotisation = "WHERE c.statut IS NOT NULL";

      if (methode) {
        params.push(methode);
        whereVirtuel += ` AND tv.methode_paiement=$${params.length}`;
        whereCotisation += ` AND c.methode_paiement=$${params.length}`;
      }
      if (type === 'depot') whereVirtuel += " AND tv.type='depot'";
      if (type === 'retrait') whereVirtuel += " AND tv.type='retrait'";

      const { rows } = await pool.query(`
        SELECT tv.id::text, tv.montant, tv.type, tv.methode_paiement,
          tv.statut, tv.created_at, tv.telephone_paiement,
          u.nom, u.prenom, u.telephone,
          t.nom as tontine_nom, tv.description
        FROM transactions_virtuelles tv
        JOIN utilisateurs u ON u.id=tv.utilisateur_id
        JOIN comptes_virtuels cv ON cv.id=tv.compte_virtuel_id
        JOIN tontines t ON t.id=cv.tontine_id
        ${whereVirtuel}
        ORDER BY tv.created_at DESC
        LIMIT $${params.length+1} OFFSET $${params.length+2}
      `, [...params, limit, offset]);

      const { rows: count } = await pool.query(
        `SELECT COUNT(*) as total FROM transactions_virtuelles tv ${whereVirtuel}`, params
      );

      res.json({ success: true, data: rows, total: parseInt(count[0].total) });
    } catch (err) {
      logger.error('Erreur getAllPaiements:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async exporterPaiements(req, res) {
    try {
      const { rows } = await pool.query(`
        SELECT tv.id, tv.montant, tv.type, tv.methode_paiement,
          tv.statut, tv.created_at, u.nom, u.prenom, u.telephone, t.nom as tontine
        FROM transactions_virtuelles tv
        JOIN utilisateurs u ON u.id=tv.utilisateur_id
        JOIN comptes_virtuels cv ON cv.id=tv.compte_virtuel_id
        JOIN tontines t ON t.id=cv.tontine_id
        ORDER BY tv.created_at DESC
        LIMIT 10000
      `);

      const csv = [
        ['ID','Montant','Type','Méthode','Statut','Date','Nom','Prénom','Téléphone','Tontine'],
        ...rows.map(r => [r.id,r.montant,r.type,r.methode_paiement,r.statut,
          new Date(r.created_at).toLocaleDateString('fr-FR'),
          r.nom,r.prenom,r.telephone,r.tontine])
      ].map(r => r.join(';')).join('\n');

      res.setHeader('Content-Type','text/csv; charset=utf-8');
      res.setHeader('Content-Disposition','attachment; filename=transactions.csv');
      res.send('\uFEFF'+csv);
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── CATALOGUE ─────────────────────────────────────────
  async getCatalogue(req, res) {
    try {
      const { categorie='' } = req.query;
      let where = 'WHERE est_actif=true';
      const params = [];
      if (categorie) { params.push(categorie); where += ` AND categorie=$${params.length}`; }
      const { rows } = await pool.query(
        `SELECT * FROM catalogue_produits ${where} ORDER BY created_at DESC`, params
      );
      res.json({ success: true, data: rows });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async ajouterProduit(req, res) {
    try {
      const { nom, categorie, description, prix, fournisseur_nom,
              fournisseur_contact, livraison_disponible, emoji, creer_tontine_auto } = req.body;
      const { rows } = await pool.query(`
        INSERT INTO catalogue_produits
          (nom, categorie, description, prix, fournisseur_nom,
           fournisseur_contact, livraison_disponible, photos, emoji)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
        RETURNING *
      `, [nom, categorie, description, prix, fournisseur_nom,
          fournisseur_contact, livraison_disponible||false,
          JSON.stringify([emoji||'📦']), emoji||'📦']);
      res.status(201).json({ success: true, data: rows[0] });
    } catch (err) {
      logger.error('Erreur ajouterProduit:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async modifierProduit(req, res) {
    try {
      const { nom, categorie, prix, description, est_actif, emoji } = req.body;
      const { rows } = await pool.query(`
        UPDATE catalogue_produits SET
          nom=COALESCE($1,nom), categorie=COALESCE($2,categorie),
          prix=COALESCE($3,prix), description=COALESCE($4,description),
          est_actif=COALESCE($5,est_actif), emoji=COALESCE($6,emoji)
        WHERE id=$7 RETURNING *
      `, [nom, categorie, prix, description, est_actif, emoji, req.params.id]);
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

  // ── COMMERÇANTS ───────────────────────────────────────
  async getCommercants(req, res) {
    try {
      const { statut='' } = req.query;
      let where = 'WHERE 1=1';
      const params = [];
      if (statut) { params.push(statut); where += ` AND statut=$${params.length}`; }

      const { rows } = await pool.query(`
        SELECT c.*,
          COUNT(cp.id) as nb_produits
        FROM commercants c
        LEFT JOIN catalogue_produits cp ON cp.commercant_id=c.id AND cp.est_actif=true
        ${where}
        GROUP BY c.id
        ORDER BY c.created_at DESC
      `, params);

      const { rows: count } = await pool.query(
        `SELECT COUNT(*) as total FROM commercants c ${where}`, params
      );

      res.json({ success: true, data: rows, total: parseInt(count[0].total) });
    } catch (err) {
      logger.error('Erreur getCommercants:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async ajouterCommercant(req, res) {
    try {
      const {
        nom, proprietaire, telephone, email, categorie,
        pays, adresse, description, livraison_disponible,
        est_verifie, statut
      } = req.body;

      const { rows } = await pool.query(`
        INSERT INTO commercants
          (nom, proprietaire, telephone, email, categorie,
           pays, adresse, description, livraison_disponible, est_verifie, statut)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
        RETURNING *
      `, [nom, proprietaire, telephone, email, categorie,
          pays||'BF', adresse, description,
          livraison_disponible||false, est_verifie||false,
          statut||'en_attente']);

      res.status(201).json({ success: true, data: rows[0] });
    } catch (err) {
      logger.error('Erreur ajouterCommercant:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async modifierCommercant(req, res) {
    try {
      const { nom, telephone, email, adresse, description,
              livraison_disponible, est_verifie, statut } = req.body;
      const { rows } = await pool.query(`
        UPDATE commercants SET
          nom=COALESCE($1,nom), telephone=COALESCE($2,telephone),
          email=COALESCE($3,email), adresse=COALESCE($4,adresse),
          description=COALESCE($5,description),
          livraison_disponible=COALESCE($6,livraison_disponible),
          est_verifie=COALESCE($7,est_verifie),
          statut=COALESCE($8,statut), updated_at=NOW()
        WHERE id=$9 RETURNING *
      `, [nom, telephone, email, adresse, description,
          livraison_disponible, est_verifie, statut, req.params.id]);
      res.json({ success: true, data: rows[0] });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async validerCommercant(req, res) {
    try {
      const { rows } = await pool.query(`
        UPDATE commercants SET statut='valide', est_verifie=true, updated_at=NOW()
        WHERE id=$1 RETURNING *
      `, [req.params.id]);
      if (!rows[0]) return res.status(404).json({ error: 'Commerçant non trouvé' });

      // Notifier le commerçant si utilisateur lié
      if (rows[0].utilisateur_id) {
        await notificationService.notifierMembre(rows[0].utilisateur_id, {
          type: 'adhesion_acceptee',
          nom_tontine: `Votre compte commerçant "${rows[0].nom}" a été validé !`,
          montant: 'Vous pouvez maintenant publier vos produits.',
          tontine_id: null,
        });
      }

      res.json({ success: true, message: 'Commerçant validé', data: rows[0] });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async refuserCommercant(req, res) {
    try {
      const { motif='' } = req.body;
      await pool.query(
        "UPDATE commercants SET statut='refuse', updated_at=NOW() WHERE id=$1",
        [req.params.id]
      );
      res.json({ success: true, message: 'Commerçant refusé' });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async supprimerCommercant(req, res) {
    try {
      await pool.query('DELETE FROM commercants WHERE id=$1', [req.params.id]);
      res.json({ success: true, message: 'Commerçant supprimé' });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── FOURNISSEURS ──────────────────────────────────────
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
      `, [nom, categorie, telephone, adresse, livraison_disponible||false]);
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

  // ── NOTIFICATIONS ─────────────────────────────────────
  async envoyerNotificationMasse(req, res) {
    try {
      const { titre, message_fr, message_moore, message_dioula,
              message_wolof, message_en, destinataires, canal } = req.body;

      let query = "SELECT id, langue, telephone FROM utilisateurs WHERE est_actif=true AND role='user'";

      if (destinataires === 'retards') {
        query = `SELECT DISTINCT u.id, u.langue, u.telephone FROM utilisateurs u
                 JOIN cotisations c ON c.membre_id=u.id
                 WHERE c.statut='en_retard' AND u.est_actif=true AND u.role='user'`;
      } else if (destinataires === 'responsables') {
        query = `SELECT DISTINCT u.id, u.langue, u.telephone FROM utilisateurs u
                 JOIN tontines t ON t.responsable_id=u.id
                 WHERE u.est_actif=true AND u.role='user'`;
      } else if (destinataires === 'inactifs') {
        query = `SELECT u.id, u.langue, u.telephone FROM utilisateurs u
                 WHERE u.est_actif=true AND u.role='user'
                 AND u.id NOT IN (
                   SELECT DISTINCT membre_id FROM cotisations
                   WHERE date_paiement>=NOW()-INTERVAL '30 days'
                 )`;
      } else if (destinataires === 'nouveaux') {
        query = `SELECT u.id, u.langue, u.telephone FROM utilisateurs u
                 WHERE u.est_actif=true AND u.role='user'
                 AND u.created_at>=NOW()-INTERVAL '7 days'`;
      }

      const { rows: users } = await pool.query(query);

      for (const user of users) {
        const message = user.langue === 'mos' ? (message_moore||message_fr)
          : user.langue === 'bm' ? (message_dioula||message_fr)
          : user.langue === 'wo' ? (message_wolof||message_fr)
          : user.langue === 'en' ? (message_en||message_fr)
          : message_fr;

        await pool.query(`
          INSERT INTO notifications
            (utilisateur_id, type, titre, message, canal)
          VALUES ($1,'admin',$2,$3,$4)
          ON CONFLICT DO NOTHING
        `, [user.id, titre, message, canal||'push']);
      }

      // Historique
      await pool.query(`
        INSERT INTO notifications_admin
          (titre, message_fr, message_moore, message_dioula,
           destinataires, canal, nb_envoyes, envoye_par)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
      `, [titre, message_fr, message_moore, message_dioula,
          destinataires, canal, users.length, req.user.id]);

      res.json({
        success: true,
        message: `Notification envoyée à ${users.length} utilisateurs`,
        nb_envoyes: users.length
      });
    } catch (err) {
      logger.error('Erreur envoyerNotification:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async getHistoriqueNotifications(req, res) {
    try {
      const { rows } = await pool.query(`
        SELECT na.*, u.prenom as envoye_par_prenom, u.nom as envoye_par_nom
        FROM notifications_admin na
        LEFT JOIN utilisateurs u ON u.id=na.envoye_par
        ORDER BY na.created_at DESC
        LIMIT 50
      `);
      res.json({ success: true, data: rows });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── ADMINS & DROITS ───────────────────────────────────
  async getAdmins(req, res) {
    try {
      const { rows } = await pool.query(
        "SELECT id, nom, prenom, telephone, email, role, created_at FROM utilisateurs WHERE role IN ('admin','moderateur','support','financier') ORDER BY created_at DESC"
      );
      res.json({ success: true, data: rows });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async ajouterAdmin(req, res) {
    try {
      const { prenom, nom, email, role, permissions } = req.body;
      const codePin = await bcrypt.hash('Admin2024!', 10);

      const { rows } = await pool.query(`
        INSERT INTO utilisateurs
          (prenom, nom, email, telephone, code_pin, role, langue, permissions)
        VALUES ($1,$2,$3,$4,$5,$6,'fr',$7)
        RETURNING id, nom, prenom, email, role
      `, [prenom, nom, email, email, codePin, role||'moderateur',
          JSON.stringify(permissions||{})]);

      res.status(201).json({
        success: true,
        data: rows[0],
        message: 'Admin créé. Mot de passe initial: Admin2024!'
      });
    } catch (err) {
      logger.error('Erreur ajouterAdmin:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async modifierDroitsAdmin(req, res) {
    try {
      const { role, permissions } = req.body;
      await pool.query(
        'UPDATE utilisateurs SET role=$1, permissions=$2 WHERE id=$3',
        [role, JSON.stringify(permissions), req.params.id]
      );
      res.json({ success: true, message: 'Droits mis à jour' });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async supprimerAdmin(req, res) {
    try {
      await pool.query(
        "UPDATE utilisateurs SET role='user' WHERE id=$1",
        [req.params.id]
      );
      res.json({ success: true, message: 'Droits admin révoqués' });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },
};

module.exports = adminController;