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
          SUM(CASE WHEN c.statut = 'paye' THEN 1 ELSE 0 END) as membres_payes_periode_actuelle,
          cv.solde as solde_virtuel
        FROM tontines t
        JOIN membres_tontine mt ON mt.tontine_id = t.id AND mt.utilisateur_id = $1
        LEFT JOIN membres_tontine mt2 ON mt2.tontine_id = t.id AND mt2.est_actif = true
        LEFT JOIN cotisations c ON c.tontine_id = t.id AND c.periode_numero = (
          SELECT COALESCE(MAX(periode_numero), 1) FROM cotisations WHERE tontine_id = t.id
        )
        LEFT JOIN comptes_virtuels cv ON cv.tontine_id = t.id
        WHERE t.statut = 'active'
        GROUP BY t.id, mt.position_rotation, mt.a_recu, cv.solde
        ORDER BY t.created_at DESC
      `, [req.user.id]);

      const tontinesAvecCompte = rows.map(t => ({
        ...t,
        jours_restants: calculerJoursRestants(t),
        pourcentage_completion: t.total_membres > 0
          ? Math.round((t.membres_payes_periode_actuelle / t.total_membres) * 100)
          : 0
      }));

      res.json({ success: true, data: tontinesAvecCompte });
    } catch (err) {
      logger.error('Erreur getMesTontines:', err);
      res.status(500).json({ error: 'Erreur lors du chargement des tontines' });
    }
  },

  async getTontinesPubliques(req, res) {
    try {
      const { search = '' } = req.query;
      let where = "WHERE t.statut = 'active' AND t.est_publique = true";
      const params = [];

      if (search) {
        params.push(`%${search}%`);
        where += ` AND t.nom ILIKE $${params.length}`;
      }

      const { rows } = await pool.query(`
        SELECT t.*,
          u.nom as responsable_nom, u.prenom as responsable_prenom,
          u.photo_profil as responsable_photo,
          COUNT(DISTINCT mt.utilisateur_id) as total_membres,
          cv.solde as solde_virtuel,
          EXISTS(
            SELECT 1 FROM membres_tontine mt2
            WHERE mt2.tontine_id = t.id AND mt2.utilisateur_id = $${params.length + 1}
          ) as est_membre,
          EXISTS(
            SELECT 1 FROM adhesions_tontine at2
            WHERE at2.tontine_id = t.id AND at2.demandeur_id = $${params.length + 1}
            AND at2.statut = 'en_attente'
          ) as demande_en_attente
        FROM tontines t
        LEFT JOIN utilisateurs u ON u.id = t.responsable_id
        LEFT JOIN membres_tontine mt ON mt.tontine_id = t.id AND mt.est_actif = true
        LEFT JOIN comptes_virtuels cv ON cv.tontine_id = t.id
        ${where}
        GROUP BY t.id, u.nom, u.prenom, u.photo_profil, cv.solde
        ORDER BY t.created_at DESC
      `, [...params, req.user.id]);

      res.json({ success: true, data: rows });
    } catch (err) {
      logger.error('Erreur getTontinesPubliques:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async creerTontine(req, res) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const {
        nom, type, description, montant_cotisation, periodicite,
        periodicite_jours, nombre_membres, date_debut,
        ordre_rotation, produit_catalogue_id, est_publique,
        photo_tontine, devise, pays,
        orange_money_numero, moov_money_numero,
        mtn_numero, wave_numero,
      } = req.body;

      const date_fin = calculerDateFin(
        date_debut, periodicite, periodicite_jours, nombre_membres
      );

      const { rows } = await client.query(`
        INSERT INTO tontines (nom, type, description, montant_cotisation, periodicite,
          periodicite_jours, nombre_membres, date_debut, date_fin, ordre_rotation,
          responsable_id, produit_catalogue_id, est_publique, photo_tontine)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)
        RETURNING *
      `, [nom, type, description, montant_cotisation, periodicite,
          periodicite_jours || 1, nombre_membres, date_debut, date_fin,
          ordre_rotation || 'tirage_sort', req.user.id,
          produit_catalogue_id || null,
          est_publique || false,
          photo_tontine || null]);

      const tontine = rows[0];

      // Ajouter le créateur comme membre
      await client.query(`
        INSERT INTO membres_tontine (tontine_id, utilisateur_id, position_rotation)
        VALUES ($1, $2, 1)
      `, [tontine.id, req.user.id]);

      // ✅ Créer le compte virtuel automatiquement
      const identifiants = {
        orange_money: orange_money_numero || null,
        moov_money: moov_money_numero || null,
        mtn: mtn_numero || null,
        wave: wave_numero || null,
      };

      await client.query(`
        INSERT INTO comptes_virtuels (tontine_id, identifiants, numero_compte)
        VALUES ($1, $2, $3)
      `, [tontine.id, JSON.stringify(identifiants), `CV-${tontine.id}-${Date.now()}`]);

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
            'a_recu', mt.a_recu, 'score_fiabilite', u.score_fiabilite,
            'photo_profil', u.photo_profil
          ) ORDER BY mt.position_rotation) as membres,
          cv.solde as solde_virtuel,
          cv.total_depots,
          cv.total_retraits,
          cv.id as compte_virtuel_id
        FROM tontines t
        LEFT JOIN membres_tontine mt ON mt.tontine_id = t.id AND mt.est_actif = true
        LEFT JOIN utilisateurs u ON u.id = mt.utilisateur_id
        LEFT JOIN comptes_virtuels cv ON cv.tontine_id = t.id
        WHERE t.id = $1
        GROUP BY t.id, cv.solde, cv.total_depots, cv.total_retraits, cv.id
      `, [req.params.id]);

      if (!rows[0]) return res.status(404).json({ error: 'Tontine non trouvée' });

      const tontine = {
        ...rows[0],
        jours_restants: calculerJoursRestants(rows[0]),
        prochain_beneficiaire: rows[0].membres?.find(m => !m.a_recu),
        periode_terminee: new Date() > new Date(rows[0].date_fin),
      };

      res.json({ success: true, data: tontine });
    } catch (err) {
      logger.error('Erreur getTontine:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async modifierTontine(req, res) {
    try {
      const { nom, description, est_publique, photo_tontine } = req.body;
      const { rows } = await pool.query(`
        UPDATE tontines SET
          nom = COALESCE($1, nom),
          description = COALESCE($2, description),
          est_publique = COALESCE($3, est_publique),
          photo_tontine = COALESCE($4, photo_tontine),
          updated_at = NOW()
        WHERE id = $5 AND responsable_id = $6
        RETURNING *
      `, [nom, description, est_publique, photo_tontine,
          req.params.id, req.user.id]);

      if (!rows[0])
        return res.status(404).json({ error: 'Tontine non trouvée ou accès refusé' });
      res.json({ success: true, data: rows[0] });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async supprimerTontine(req, res) {
    try {
      await pool.query(
        "UPDATE tontines SET statut = 'annulee' WHERE id = $1 AND responsable_id = $2",
        [req.params.id, req.user.id]
      );
      res.json({ success: true, message: 'Tontine annulée' });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async inviterMembre(req, res) {
    try {
      const { telephone } = req.body;
      const tontine_id = req.params.id;

      const { rows: tontineRows } = await pool.query(
        'SELECT * FROM tontines WHERE id = $1', [tontine_id]
      );
      if (!tontineRows[0])
        return res.status(404).json({ error: 'Tontine non trouvée' });

      const { rows: userRows } = await pool.query(
        'SELECT * FROM utilisateurs WHERE telephone = $1', [telephone]
      );

      if (!userRows[0]) {
        const msg = `Vous êtes invité(e) à rejoindre la tontine "${tontineRows[0].nom}". Téléchargez l'app Tontine Africa !`;
        await notificationService.envoyerSMS(telephone, msg);
        return res.json({ success: true, message: 'Invitation SMS envoyée' });
      }

      const user = userRows[0];
      const { rows: membreRows } = await pool.query(
        'SELECT * FROM membres_tontine WHERE tontine_id = $1 AND utilisateur_id = $2',
        [tontine_id, user.id]
      );
      if (membreRows[0])
        return res.status(400).json({ error: 'Cette personne est déjà membre' });

      const { rows: countRows } = await pool.query(
        'SELECT COUNT(*) as total FROM membres_tontine WHERE tontine_id = $1 AND est_actif = true',
        [tontine_id]
      );
      if (parseInt(countRows[0].total) >= tontineRows[0].nombre_membres)
        return res.status(400).json({ error: 'Le groupe est complet' });

      const position = parseInt(countRows[0].total) + 1;
      await pool.query(
        'INSERT INTO membres_tontine (tontine_id, utilisateur_id, position_rotation) VALUES ($1,$2,$3)',
        [tontine_id, user.id, position]
      );

      await notificationService.notifierMembre(user.id, {
        type: 'invitation_tontine',
        tontine_id,
        nom_tontine: tontineRows[0].nom,
        montant: `${req.user.prenom} ${req.user.nom}`,
      });

      res.json({ success: true, message: 'Membre invité avec succès' });
    } catch (err) {
      logger.error('Erreur inviterMembre:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async rejoindreTontine(req, res) {
    try {
      const tontine_id = req.params.id;
      const { rows: tontine } = await pool.query(
        'SELECT * FROM tontines WHERE id = $1', [tontine_id]
      );
      if (!tontine[0])
        return res.status(404).json({ error: 'Tontine non trouvée' });

      const { rows: existing } = await pool.query(
        'SELECT * FROM membres_tontine WHERE tontine_id = $1 AND utilisateur_id = $2',
        [tontine_id, req.user.id]
      );
      if (existing[0])
        return res.status(400).json({ error: 'Vous êtes déjà membre' });

      const { rows: count } = await pool.query(
        'SELECT COUNT(*) as total FROM membres_tontine WHERE tontine_id = $1 AND est_actif = true',
        [tontine_id]
      );
      if (parseInt(count[0].total) >= tontine[0].nombre_membres)
        return res.status(400).json({ error: 'Le groupe est complet' });

      const position = parseInt(count[0].total) + 1;
      await pool.query(
        'INSERT INTO membres_tontine (tontine_id, utilisateur_id, position_rotation) VALUES ($1,$2,$3)',
        [tontine_id, req.user.id, position]
      );

      await notificationService.notifierMembre(tontine[0].responsable_id, {
        type: 'nouveau_membre_tontine',
        tontine_id,
        nom_tontine: tontine[0].nom,
        montant: `${req.user.prenom} ${req.user.nom}`,
      });

      res.json({ success: true, message: 'Vous avez rejoint la tontine !' });
    } catch (err) {
      logger.error('Erreur rejoindreTontine:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async demanderAdhesion(req, res) {
    try {
      const { message } = req.body;
      const tontine_id = req.params.id;

      const { rows: tontine } = await pool.query(
        'SELECT * FROM tontines WHERE id = $1', [tontine_id]
      );
      if (!tontine[0])
        return res.status(404).json({ error: 'Tontine non trouvée' });

      const { rows: existing } = await pool.query(
        'SELECT * FROM membres_tontine WHERE tontine_id = $1 AND utilisateur_id = $2',
        [tontine_id, req.user.id]
      );
      if (existing[0])
        return res.status(400).json({ error: 'Vous êtes déjà membre' });

      await pool.query(`
        INSERT INTO adhesions_tontine (tontine_id, demandeur_id, message)
        VALUES ($1, $2, $3)
        ON CONFLICT (tontine_id, demandeur_id)
        DO UPDATE SET statut = 'en_attente', updated_at = NOW()
      `, [tontine_id, req.user.id, message || '']);

      await notificationService.notifierMembre(tontine[0].responsable_id, {
        type: 'demande_adhesion',
        tontine_id,
        nom_tontine: tontine[0].nom,
        montant: `${req.user.prenom} ${req.user.nom}`,
      });

      res.json({ success: true, message: 'Demande envoyée au responsable' });
    } catch (err) {
      logger.error('Erreur demanderAdhesion:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async getMesDemandes(req, res) {
    try {
      const { rows } = await pool.query(`
        SELECT at.*, t.nom as nom_tontine, t.type, t.montant_cotisation, t.periodicite
        FROM adhesions_tontine at
        JOIN tontines t ON t.id = at.tontine_id
        WHERE at.demandeur_id = $1
        ORDER BY at.created_at DESC
      `, [req.user.id]);
      res.json({ success: true, data: rows });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async accepterAdhesion(req, res) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const { rows: adhesion } = await client.query(
        'SELECT * FROM adhesions_tontine WHERE id = $1', [req.params.adhesionId]
      );
      if (!adhesion[0])
        return res.status(404).json({ error: 'Demande non trouvée' });

      const { rows: count } = await client.query(
        'SELECT COUNT(*) as total FROM membres_tontine WHERE tontine_id = $1 AND est_actif = true',
        [adhesion[0].tontine_id]
      );
      const { rows: tontine } = await client.query(
        'SELECT * FROM tontines WHERE id = $1', [adhesion[0].tontine_id]
      );

      if (parseInt(count[0].total) >= tontine[0].nombre_membres)
        return res.status(400).json({ error: 'Le groupe est complet' });

      const position = parseInt(count[0].total) + 1;
      await client.query(
        'INSERT INTO membres_tontine (tontine_id, utilisateur_id, position_rotation) VALUES ($1,$2,$3)',
        [adhesion[0].tontine_id, adhesion[0].demandeur_id, position]
      );

      await client.query(
        "UPDATE adhesions_tontine SET statut = 'accepte', updated_at = NOW() WHERE id = $1",
        [req.params.adhesionId]
      );

      await client.query('COMMIT');

      await notificationService.notifierMembre(adhesion[0].demandeur_id, {
        type: 'adhesion_acceptee',
        tontine_id: adhesion[0].tontine_id,
        nom_tontine: tontine[0].nom,
      });

      res.json({ success: true, message: 'Membre accepté' });
    } catch (err) {
      await client.query('ROLLBACK');
      logger.error('Erreur accepterAdhesion:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    } finally {
      client.release();
    }
  },

  async refuserAdhesion(req, res) {
    try {
      await pool.query(
        "UPDATE adhesions_tontine SET statut = 'refuse', updated_at = NOW() WHERE id = $1",
        [req.params.adhesionId]
      );
      res.json({ success: true, message: 'Demande refusée' });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async retirerMembre(req, res) {
    try {
      await pool.query(
        'UPDATE membres_tontine SET est_actif = false WHERE tontine_id = $1 AND utilisateur_id = $2',
        [req.params.id, req.params.membreId]
      );
      res.json({ success: true, message: 'Membre retiré' });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── COMPTE VIRTUEL ──────────────────────────────────

  async getCompteVirtuel(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      // Vérifier membre
      const { rows: membre } = await pool.query(
        'SELECT id FROM membres_tontine WHERE tontine_id = $1 AND utilisateur_id = $2 AND est_actif = true',
        [id, userId]
      );
      if (membre.length === 0)
        return res.status(403).json({ error: 'Accès refusé' });

      const { rows } = await pool.query(`
        SELECT cv.*,
          t.nom as tontine_nom, t.date_fin, t.statut as tontine_statut,
          t.responsable_id, t.montant_cotisation, t.periodicite,
          (SELECT COUNT(*) FROM votes_retrait vr
           JOIN transactions_virtuelles tv ON tv.id = vr.transaction_id
           WHERE tv.compte_virtuel_id = cv.id
           AND tv.statut = 'en_attente_vote' AND vr.vote = 'oui') as votes_oui,
          (SELECT COUNT(*) FROM membres_tontine
           WHERE tontine_id = $1 AND est_actif = true) as nb_membres,
          (NOW() > t.date_fin) as periode_terminee
        FROM comptes_virtuels cv
        JOIN tontines t ON t.id = cv.tontine_id
        WHERE cv.tontine_id = $1
      `, [id]);

      if (rows.length === 0)
        return res.status(404).json({ error: 'Compte virtuel non trouvé' });

      // Transactions récentes
      const { rows: transactions } = await pool.query(`
        SELECT tv.*, u.prenom, u.nom,
          (SELECT json_agg(json_build_object(
            'utilisateur_id', vr.utilisateur_id,
            'vote', vr.vote,
            'prenom', u2.prenom,
            'nom', u2.nom
          )) FROM votes_retrait vr
           JOIN utilisateurs u2 ON u2.id = vr.utilisateur_id
           WHERE vr.transaction_id = tv.id) as votes
        FROM transactions_virtuelles tv
        LEFT JOIN utilisateurs u ON u.id = tv.utilisateur_id
        WHERE tv.compte_virtuel_id = $1
        ORDER BY tv.created_at DESC
        LIMIT 30
      `, [rows[0].id]);

      // Mon dépôt total dans cette tontine
      const { rows: monDepot } = await pool.query(`
        SELECT COALESCE(SUM(montant), 0) as mon_total
        FROM transactions_virtuelles
        WHERE compte_virtuel_id = $1 AND utilisateur_id = $2 AND type = 'depot' AND statut = 'confirme'
      `, [rows[0].id, userId]);

      res.json({
        success: true,
        data: {
          ...rows[0],
          transactions,
          mon_depot_total: parseFloat(monDepot[0].mon_total),
        }
      });
    } catch (err) {
      logger.error('Erreur getCompteVirtuel:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async effectuerDepot(req, res) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const { id } = req.params;
      const { montant, methode_paiement, telephone_paiement, reference_externe } = req.body;
      const userId = req.user.id;

      if (!montant || parseFloat(montant) <= 0)
        return res.status(400).json({ error: 'Montant invalide' });

      // Vérifier membre actif
      const { rows: membre } = await client.query(
        'SELECT id FROM membres_tontine WHERE tontine_id = $1 AND utilisateur_id = $2 AND est_actif = true',
        [id, userId]
      );
      if (membre.length === 0)
        return res.status(403).json({ error: 'Vous n\'êtes pas membre de cette tontine' });

      // Récupérer compte virtuel
      const { rows: cv } = await client.query(
        'SELECT id, solde FROM comptes_virtuels WHERE tontine_id = $1',
        [id]
      );
      if (cv.length === 0)
        return res.status(404).json({ error: 'Compte virtuel non trouvé' });

      // Enregistrer la transaction
      const { rows: transaction } = await client.query(`
        INSERT INTO transactions_virtuelles
          (compte_virtuel_id, utilisateur_id, type, montant, methode_paiement,
           telephone_paiement, reference_externe, statut, description)
        VALUES ($1, $2, 'depot', $3, $4, $5, $6, 'confirme', 'Dépôt cotisation')
        RETURNING *
      `, [cv[0].id, userId, montant, methode_paiement,
          telephone_paiement, reference_externe || null]);

      // Mettre à jour le solde
      await client.query(
        'UPDATE comptes_virtuels SET solde = solde + $1, total_depots = total_depots + $1 WHERE id = $2',
        [montant, cv[0].id]
      );

      // Mettre à jour la cotisation
      await client.query(`
        UPDATE cotisations SET statut = 'paye', date_paiement = NOW(),
          methode_paiement = $1
        WHERE tontine_id = $2 AND membre_id = $3 AND statut = 'en_attente'
        ORDER BY date_echeance ASC LIMIT 1
      `, [methode_paiement, id, userId]);

      await client.query('COMMIT');

      // Notifier le groupe
      const { rows: tontine } = await pool.query(
        'SELECT nom FROM tontines WHERE id = $1', [id]
      );
      const { rows: user } = await pool.query(
        'SELECT prenom FROM utilisateurs WHERE id = $1', [userId]
      );

      await notificationService.notifierGroupeTontine(id, {
        type: 'paiement_confirme',
        nom_tontine: tontine[0]?.nom,
        montant: montant.toString(),
        tontine_id: id,
      });

      res.json({
        success: true,
        message: 'Dépôt enregistré avec succès',
        data: transaction[0]
      });
    } catch (err) {
      await client.query('ROLLBACK');
      logger.error('Erreur dépôt:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    } finally {
      client.release();
    }
  },

  async initierRetrait(req, res) {
    try {
      const { id } = req.params;
      const { montant, methode_retrait, telephone_retrait, motif } = req.body;
      const userId = req.user.id;

      // Vérifier créateur
      const { rows: tontine } = await pool.query(
        'SELECT * FROM tontines WHERE id = $1', [id]
      );
      if (tontine.length === 0)
        return res.status(404).json({ error: 'Tontine non trouvée' });

      if (tontine[0].responsable_id !== userId)
        return res.status(403).json({
          error: 'Seul le créateur de la tontine peut initier un retrait'
        });

      // Vérifier période terminée
      const maintenant = new Date();
      const dateFin = new Date(tontine[0].date_fin);
      if (maintenant < dateFin)
        return res.status(400).json({
          error: `Retrait impossible avant la fin de la période (${dateFin.toLocaleDateString()})`
        });

      // Récupérer compte virtuel
      const { rows: cv } = await pool.query(
        'SELECT * FROM comptes_virtuels WHERE tontine_id = $1', [id]
      );
      if (cv.length === 0)
        return res.status(404).json({ error: 'Compte virtuel non trouvé' });

      if (parseFloat(cv[0].solde) < parseFloat(montant))
        return res.status(400).json({ error: 'Solde insuffisant' });

      // Vérifier pas de retrait en attente
      const { rows: retraitEnCours } = await pool.query(`
        SELECT id FROM transactions_virtuelles
        WHERE compte_virtuel_id = $1 AND type = 'retrait' AND statut = 'en_attente_vote'
      `, [cv[0].id]);
      if (retraitEnCours.length > 0)
        return res.status(400).json({
          error: 'Un retrait est déjà en cours de vote'
        });

      // Créer la demande de retrait
      const { rows: retrait } = await pool.query(`
        INSERT INTO transactions_virtuelles
          (compte_virtuel_id, utilisateur_id, type, montant, methode_paiement,
           telephone_paiement, statut, description)
        VALUES ($1, $2, 'retrait', $3, $4, $5, 'en_attente_vote', $6)
        RETURNING *
      `, [cv[0].id, userId, montant, methode_retrait, telephone_retrait,
          motif || 'Retrait fin de période']);

      // Notifier tous les membres pour voter
      const { rows: membres } = await pool.query(
        'SELECT utilisateur_id FROM membres_tontine WHERE tontine_id = $1 AND est_actif = true AND utilisateur_id != $2',
        [id, userId]
      );

      for (const m of membres) {
        await notificationService.notifierMembre(m.utilisateur_id, {
          type: 'rappel_cotisation',
          nom_tontine: tontine[0].nom,
          montant: `${montant} F - VOTE RETRAIT REQUIS`,
          tontine_id: id,
        });
      }

      res.json({
        success: true,
        message: `Demande de retrait créée. ${membres.length} membre(s) doivent voter.`,
        data: retrait[0]
      });
    } catch (err) {
      logger.error('Erreur initierRetrait:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async voterRetrait(req, res) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const { id, retraitId } = req.params;
      const { vote } = req.body; // 'oui' ou 'non'
      const userId = req.user.id;

      // Vérifier membre
      const { rows: membre } = await client.query(
        'SELECT id FROM membres_tontine WHERE tontine_id = $1 AND utilisateur_id = $2 AND est_actif = true',
        [id, userId]
      );
      if (membre.length === 0)
        return res.status(403).json({ error: 'Accès refusé' });

      // Récupérer le retrait
      const { rows: retrait } = await client.query(
        'SELECT * FROM transactions_virtuelles WHERE id = $1 AND statut = \'en_attente_vote\'',
        [retraitId]
      );
      if (retrait.length === 0)
        return res.status(404).json({ error: 'Demande de retrait non trouvée' });

      // Ne pas voter pour sa propre demande
      if (retrait[0].utilisateur_id === userId)
        return res.status(400).json({ error: 'Vous ne pouvez pas voter pour votre propre demande' });

      // Vérifier si déjà voté
      const { rows: dejaVote } = await client.query(
        'SELECT id FROM votes_retrait WHERE transaction_id = $1 AND utilisateur_id = $2',
        [retraitId, userId]
      );
      if (dejaVote.length > 0)
        return res.status(400).json({ error: 'Vous avez déjà voté' });

      // Enregistrer le vote
      await client.query(
        'INSERT INTO votes_retrait (transaction_id, compte_virtuel_id, utilisateur_id, vote) VALUES ($1,$2,$3,$4)',
        [retraitId, retrait[0].compte_virtuel_id, userId, vote]
      );

      // Compter les votes
      const { rows: stats } = await client.query(`
        SELECT
          COUNT(*) FILTER (WHERE vr.vote = 'oui') as votes_oui,
          COUNT(*) FILTER (WHERE vr.vote = 'non') as votes_non,
          COUNT(*) as total_votes,
          (SELECT COUNT(*) FROM membres_tontine
           WHERE tontine_id = $1 AND est_actif = true) - 1 as membres_votants
        FROM votes_retrait vr
        WHERE vr.transaction_id = $2
      `, [id, retraitId]);

      const { votes_oui, votes_non, total_votes, membres_votants } = stats[0];
      const { rows: tontine } = await pool.query(
        'SELECT nom FROM tontines WHERE id = $1', [id]
      );

      // Si quelqu'un vote NON → refuser immédiatement
      if (vote === 'non') {
        await client.query(
          'UPDATE transactions_virtuelles SET statut = \'refuse\' WHERE id = $1',
          [retraitId]
        );
        await client.query('COMMIT');

        await notificationService.notifierGroupeTontine(id, {
          type: 'retard_paiement',
          nom_tontine: tontine[0]?.nom,
          montant: `Retrait refusé par un membre`,
          tontine_id: id,
        });

        return res.json({
          success: true,
          message: 'Retrait refusé.',
          approuve: false,
          statut: 'refuse'
        });
      }

      // Si tous les membres ont voté OUI → approuver
      if (parseInt(votes_oui) >= parseInt(membres_votants)) {
        await client.query(
          'UPDATE transactions_virtuelles SET statut = \'approuve\' WHERE id = $1',
          [retraitId]
        );
        await client.query(
          'UPDATE comptes_virtuels SET solde = solde - $1, total_retraits = total_retraits + $1 WHERE id = $2',
          [retrait[0].montant, retrait[0].compte_virtuel_id]
        );
        await client.query('COMMIT');

        await notificationService.notifierGroupeTontine(id, {
          type: 'tour_recu',
          nom_tontine: tontine[0]?.nom,
          montant: retrait[0].montant.toString(),
          tontine_id: id,
        });

        return res.json({
          success: true,
          message: `Retrait approuvé ! ${retrait[0].montant} F seront transférés.`,
          approuve: true,
          statut: 'approuve'
        });
      }

      await client.query('COMMIT');

      res.json({
        success: true,
        message: `Vote enregistré. ${votes_oui}/${membres_votants} votes pour.`,
        votes_oui: parseInt(votes_oui),
        membres_votants: parseInt(membres_votants),
        approuve: false,
        statut: 'en_attente_vote'
      });
    } catch (err) {
      await client.query('ROLLBACK');
      logger.error('Erreur voterRetrait:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    } finally {
      client.release();
    }
  },

  async getTransactions(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      // Vérifier membre
      const { rows: membre } = await pool.query(
        'SELECT id FROM membres_tontine WHERE tontine_id = $1 AND utilisateur_id = $2 AND est_actif = true',
        [id, userId]
      );
      if (membre.length === 0)
        return res.status(403).json({ error: 'Accès refusé' });

      const { rows: cv } = await pool.query(
        'SELECT id FROM comptes_virtuels WHERE tontine_id = $1', [id]
      );
      if (cv.length === 0)
        return res.status(404).json({ error: 'Compte non trouvé' });

      const { rows } = await pool.query(`
        SELECT tv.*, u.prenom, u.nom, u.telephone,
          (SELECT json_agg(json_build_object(
            'utilisateur_id', vr.utilisateur_id,
            'vote', vr.vote,
            'prenom', u2.prenom,
            'nom', u2.nom,
            'date', vr.created_at
          )) FROM votes_retrait vr
           JOIN utilisateurs u2 ON u2.id = vr.utilisateur_id
           WHERE vr.transaction_id = tv.id) as votes
        FROM transactions_virtuelles tv
        LEFT JOIN utilisateurs u ON u.id = tv.utilisateur_id
        WHERE tv.compte_virtuel_id = $1
        ORDER BY tv.created_at DESC
      `, [cv[0].id]);

      res.json({ success: true, data: rows });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── STATS & RAPPORTS ────────────────────────────────

  async getStatistiques(req, res) {
    try {
      const { rows } = await pool.query(`
        SELECT
          COUNT(c.id) as total_cotisations,
          SUM(CASE WHEN c.statut = 'paye' THEN c.montant ELSE 0 END) as montant_collecte,
          SUM(CASE WHEN c.statut = 'en_attente' THEN c.montant ELSE 0 END) as montant_attendu,
          COUNT(CASE WHEN c.statut = 'en_retard' THEN 1 END) as cotisations_en_retard,
          AVG(u.score_fiabilite) as score_moyen_groupe,
          cv.solde as solde_virtuel,
          cv.total_depots,
          cv.total_retraits
        FROM cotisations c
        JOIN utilisateurs u ON u.id = c.membre_id
        LEFT JOIN comptes_virtuels cv ON cv.tontine_id = c.tontine_id
        WHERE c.tontine_id = $1
        GROUP BY cv.solde, cv.total_depots, cv.total_retraits
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
          u.photo_profil, mt.position_rotation, mt.a_recu, mt.date_reception,
          COUNT(CASE WHEN c.statut = 'paye' THEN 1 END) as total_paiements,
          COUNT(CASE WHEN c.statut = 'en_retard' THEN 1 END) as total_retards,
          COALESCE(SUM(CASE WHEN tv.type = 'depot' AND tv.statut = 'confirme'
            THEN tv.montant ELSE 0 END), 0) as total_depots_virtuel
        FROM membres_tontine mt
        JOIN utilisateurs u ON u.id = mt.utilisateur_id
        LEFT JOIN cotisations c ON c.membre_id = u.id AND c.tontine_id = mt.tontine_id
        LEFT JOIN comptes_virtuels cv ON cv.tontine_id = mt.tontine_id
        LEFT JOIN transactions_virtuelles tv ON tv.compte_virtuel_id = cv.id
          AND tv.utilisateur_id = u.id
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
      const { montant, date_echeance } = req.body;
      const { rows } = await pool.query(`
        INSERT INTO emprunts (tontine_id, emprunteur_id, montant, date_echeance)
        VALUES ($1,$2,$3,$4) RETURNING *
      `, [req.params.id, req.user.id, montant, date_echeance]);

      await notificationService.notifierGroupeTontine(req.params.id, {
        type: 'rappel_cotisation',
        nom_tontine: '',
        montant: `Demande emprunt: ${montant} F`,
        tontine_id: req.params.id,
      });

      res.status(201).json({ success: true, data: rows[0] });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async voterEmprunt(req, res) {
    try {
      const { vote } = req.body;
      const { rows } = await pool.query(
        'SELECT * FROM emprunts WHERE id = $1', [req.params.empruntId]
      );
      if (!rows[0])
        return res.status(404).json({ error: 'Emprunt non trouvé' });

      const approuves = rows[0].approuve_par || [];
      const newApprouves = [
        ...approuves,
        { userId: req.user.id, vote, date: new Date() }
      ];

      await pool.query(
        'UPDATE emprunts SET approuve_par = $1 WHERE id = $2',
        [JSON.stringify(newApprouves), req.params.empruntId]
      );

      res.json({ success: true, message: 'Vote enregistré' });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async rembourserEmprunt(req, res) {
    try {
      const { montant } = req.body;
      const { rows } = await pool.query(`
        UPDATE emprunts SET
          montant_rembourse = montant_rembourse + $1,
          statut = CASE WHEN montant_rembourse + $1 >= montant THEN 'rembourse' ELSE statut END
        WHERE id = $2 RETURNING *
      `, [montant, req.params.empruntId]);
      res.json({ success: true, data: rows[0] });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async genererRapport(req, res) {
    try {
      const [tontine, membres, cotisations, compteVirtuel] = await Promise.all([
        pool.query('SELECT * FROM tontines WHERE id = $1', [req.params.id]),
        pool.query(`
          SELECT u.nom, u.prenom, u.photo_profil, mt.position_rotation, mt.a_recu
          FROM membres_tontine mt
          JOIN utilisateurs u ON u.id = mt.utilisateur_id
          WHERE mt.tontine_id = $1
        `, [req.params.id]),
        pool.query(
          'SELECT * FROM cotisations WHERE tontine_id = $1 ORDER BY periode_numero, date_echeance',
          [req.params.id]
        ),
        pool.query(
          'SELECT * FROM comptes_virtuels WHERE tontine_id = $1',
          [req.params.id]
        )
      ]);

      const rapport = {
        tontine: tontine.rows[0],
        membres: membres.rows,
        cotisations: cotisations.rows,
        compte_virtuel: compteVirtuel.rows[0] || null,
        resume: {
          total_collecte: cotisations.rows
            .filter(c => c.statut === 'paye')
            .reduce((sum, c) => sum + parseFloat(c.montant), 0),
          taux_paiement: cotisations.rows.length > 0
            ? Math.round(
                (cotisations.rows.filter(c => c.statut === 'paye').length /
                cotisations.rows.length) * 100
              )
            : 0,
          solde_virtuel: compteVirtuel.rows[0]?.solde || 0,
          genere_le: new Date()
        }
      };

      res.json({ success: true, data: rapport });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },
};

// ── FONCTIONS UTILITAIRES ──────────────────────────────
function calculerJoursRestants(tontine) {
  const debut = new Date(tontine.date_debut);
  const joursEcoules = Math.floor((new Date() - debut) / (1000 * 60 * 60 * 24));
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