const { pool } = require('../../config/database');
const { deleteCache } = require('../../config/redis');
const notificationService = require('../services/notificationService');
const logger = require('../utils/logger');
const { v4: uuidv4 } = require('uuid');
const { appliquerSurplus } = require('../services/cotisationService');
const { LIEN_TELECHARGEMENT } = require('../services/notificationService');

/**
 * Accès en LECTURE : membre actif de la tontine, OU organisateur, OU admin.
 * Centralise ce contrôle pour toutes les routes qui exposent des données
 * de la tontine (détails, membres, cotisations, statistiques, compte
 * virtuel...) — plusieurs de ces routes n'avaient auparavant AUCUNE
 * vérification, exposant des données (dont des numéros de téléphone) à
 * n'importe quel utilisateur authentifié.
 */
async function verifierMembreOuPlus(dbClient, tontineId, userId) {
  const { rows: [acces] } = await dbClient.query(
    `SELECT 1 FROM membres_tontine WHERE tontine_id = $1 AND utilisateur_id = $2 AND est_actif = true
     UNION SELECT 1 FROM tontines WHERE id = $1 AND responsable_id = $2
     UNION SELECT 1 FROM utilisateurs WHERE id = $2 AND role = 'admin'`,
    [tontineId, userId]
  );
  return !!acces;
}

/**
 * Accès en GESTION : organisateur (responsable_id) OU admin uniquement.
 */
async function verifierOrganisateurOuAdmin(dbClient, tontineId, userId) {
  const { rows: [tontine] } = await dbClient.query(
    'SELECT * FROM tontines WHERE id = $1',
    [tontineId]
  );
  if (!tontine) return { tontine: null, autorise: false };
  if (tontine.responsable_id === userId) return { tontine, autorise: true };

  const { rows: [user] } = await dbClient.query(
    'SELECT role FROM utilisateurs WHERE id = $1',
    [userId]
  );
  return { tontine, autorise: user?.role === 'admin' };
}

/**
 * DUPLICATION CONNUE (dette technique à consolider) : cette fonction existe
 * à l identique dans backend/src/routes/paiements.js et
 * backend/src/routes/tontines.js.
 */

/**
 * NOUVEAU : appelée après chaque ajout de membre (création, rejoindre,
 * adhésion acceptée, invitation directe). Ne fait rien tant que le groupe
 * n'a pas atteint nombre_membres. Une fois complet, exactement une fois :
 *   1. Si ordre_rotation = 'tirage_sort' : mélange réellement les positions
 *      (jusqu ici cette valeur n avait aucun effet, l ordre était toujours
 *      celui d inscription, peu importe ce qui était choisi/affiché).
 *   2. Génère les cotisations pour TOUS les membres définitifs.
 *      FIX MAJEUR : auparavant, genererCotisations tournait à la création
 *      de la tontine, où seul l organisateur est membre — tout membre
 *      rejoignant ensuite n avait donc JAMAIS de cotisation générée.
 */
async function finaliserGroupeSiComplet(dbClient, tontineId, tontine) {
  const { rows: [count] } = await dbClient.query(
    'SELECT COUNT(*) as total FROM membres_tontine WHERE tontine_id = $1 AND est_actif = true',
    [tontineId]
  );
  if (parseInt(count.total) !== tontine.nombre_membres) return;

  const { rows: [dejaGenere] } = await dbClient.query(
    'SELECT 1 FROM cotisations WHERE tontine_id = $1 LIMIT 1', [tontineId]
  );
  if (dejaGenere) return;

  if (tontine.ordre_rotation === 'tirage_sort') {
    const { rows: membres } = await dbClient.query(
      'SELECT id FROM membres_tontine WHERE tontine_id = $1 AND est_actif = true',
      [tontineId]
    );
    const melanges = [...membres];
    for (let i = melanges.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [melanges[i], melanges[j]] = [melanges[j], melanges[i]];
    }
    for (let i = 0; i < melanges.length; i++) {
      await dbClient.query(
        'UPDATE membres_tontine SET position_rotation = $1 WHERE id = $2',
        [i + 1, melanges[i].id]
      );
    }
    logger.info(`Tirage au sort effectué pour la tontine ${tontineId}`);
  }

  await genererCotisations(dbClient, tontine);
  logger.info(`Cotisations générées pour la tontine ${tontineId} (groupe complet)`);
}

const tontineController = {

  // ── MES TONTINES ──────────────────────────────────────
  async getMesTontines(req, res) {
    try {
      const { rows } = await pool.query(`
        SELECT t.*, mt.position_rotation, mt.a_recu,
          COUNT(mt2.id) as total_membres,
          SUM(CASE WHEN c.statut = 'paye' THEN 1 ELSE 0 END) as membres_payes_periode_actuelle,
          cv.solde as solde_virtuel,
          CASE
            WHEN t.date_fin IS NULL THEN 99
            ELSE GREATEST(0, EXTRACT(DAY FROM t.date_fin::timestamp - NOW())::int)
          END as jours_restants
        FROM tontines t
        JOIN membres_tontine mt ON mt.tontine_id = t.id AND mt.utilisateur_id = $1 AND mt.est_actif = true
        LEFT JOIN membres_tontine mt2 ON mt2.tontine_id = t.id AND mt2.est_actif = true
        LEFT JOIN cotisations c ON c.tontine_id = t.id AND c.periode_numero = (
          SELECT MIN(periode_numero) FROM cotisations
          WHERE tontine_id = t.id AND statut != 'paye'
        )
        LEFT JOIN comptes_virtuels cv ON cv.tontine_id = t.id
        WHERE t.statut = 'active'
        GROUP BY t.id, mt.position_rotation, mt.a_recu, cv.solde
        ORDER BY t.created_at DESC
      `, [req.user.id]);

      const tontinesAvecCompte = rows.map(t => ({
        ...t,
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

  // ── TONTINES PUBLIQUES ────────────────────────────────
  async getTontinesPubliques(req, res) {
    try {
      const { search = '' } = req.query;
      const userId = req.user.id;

      let where = `WHERE t.statut = 'active'
        AND t.est_publique = true
        AND NOT EXISTS (
          SELECT 1 FROM membres_tontine mt2
          WHERE mt2.tontine_id = t.id
          AND mt2.utilisateur_id = $1
          AND mt2.est_actif = true
        )`;
      const params = [userId];

      if (search) {
        params.push(`%${search}%`);
        where += ` AND (t.nom ILIKE $${params.length} OR u.prenom ILIKE $${params.length} OR u.nom ILIKE $${params.length})`;
      }

      const { rows } = await pool.query(`
        SELECT t.*,
          u.nom as responsable_nom, u.prenom as responsable_prenom,
          u.photo_profil as responsable_photo,
          COUNT(DISTINCT mt.utilisateur_id) as total_membres,
          cv.solde as solde_virtuel,
          false as est_membre,
          EXISTS(
            SELECT 1 FROM adhesions_tontine at2
            WHERE at2.tontine_id = t.id AND at2.demandeur_id = $1
            AND at2.statut = 'en_attente'
          ) as demande_en_attente
        FROM tontines t
        LEFT JOIN utilisateurs u ON u.id = t.responsable_id
        LEFT JOIN membres_tontine mt ON mt.tontine_id = t.id AND mt.est_actif = true
        LEFT JOIN comptes_virtuels cv ON cv.tontine_id = t.id
        ${where}
        GROUP BY t.id, u.nom, u.prenom, u.photo_profil, cv.solde
        ORDER BY t.created_at DESC
      `, params);

      res.json({ success: true, data: rows });
    } catch (err) {
      logger.error('Erreur getTontinesPubliques:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── CRÉER TONTINE ─────────────────────────────────────
  async creerTontine(req, res) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const {
        nom, type, description, montant_cotisation, periodicite,
        periodicite_jours, nombre_membres, date_debut,
        ordre_rotation, produit_catalogue_id,
        est_publique, mode_gestion, medias,
        photo_tontine, devise, pays,
        orange_money_numero, moov_money_numero,
        mtn_numero, wave_numero,
      } = req.body;

      const estPublique = est_publique || false;
      const modeGestionFinal = mode_gestion === 'gere' ? 'gere' : 'direct';
      const mediasArray = Array.isArray(medias) ? medias : [];
      const premierePhoto = mediasArray.find(m => m.type === 'image');
      const photoTontineFinal = photo_tontine || premierePhoto?.url || null;

      const date_fin = calculerDateFin(
        date_debut, periodicite, periodicite_jours, nombre_membres
      );

      const { rows } = await client.query(`
        INSERT INTO tontines (nom, type, description, montant_cotisation, periodicite,
          periodicite_jours, nombre_membres, date_debut, date_fin, ordre_rotation,
          responsable_id, produit_catalogue_id, est_publique, photo_tontine, medias, mode_gestion)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16)
        RETURNING *
      `, [nom, type, description, montant_cotisation, periodicite,
          periodicite_jours || 1, nombre_membres, date_debut, date_fin,
          ordre_rotation || 'tirage_sort', req.user.id,
          produit_catalogue_id || null,
          estPublique,
          photoTontineFinal,
          JSON.stringify(mediasArray),
          modeGestionFinal]);

      const tontine = rows[0];

      await client.query(`
        INSERT INTO membres_tontine (tontine_id, utilisateur_id, position_rotation)
        VALUES ($1, $2, 1)
      `, [tontine.id, req.user.id]);

      const identifiants = {
        orange_money: orange_money_numero || null,
        moov_money: moov_money_numero || null,
        mtn: mtn_numero || null,
        wave: wave_numero || null,
      };

      await client.query(`
        INSERT INTO comptes_virtuels (tontine_id, identifiants, numero_compte)
        VALUES ($1, $2, $3)
      `, [tontine.id, JSON.stringify(identifiants),
          `CV-${Date.now()}`]);

      // FIX: ne génère plus les cotisations ici aveuglément (auparavant
      // couvrait uniquement l organisateur, seul membre présent à cet
      // instant) — délègue à finaliserGroupeSiComplet, qui ne le fera que
      // lorsque le groupe sera réellement complet.
      await finaliserGroupeSiComplet(client, tontine.id, tontine);

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

  // ── DÉTAIL TONTINE ────────────────────────────────────
  async getTontine(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      const autorise = await verifierMembreOuPlus(pool, id, userId);
      if (!autorise) return res.status(403).json({ error: 'Accès refusé' });

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
          cv.id as compte_virtuel_id,
          CASE
            WHEN t.date_fin IS NULL THEN 99
            ELSE GREATEST(0, EXTRACT(DAY FROM t.date_fin::timestamp - NOW())::int)
          END as jours_restants
        FROM tontines t
        LEFT JOIN membres_tontine mt ON mt.tontine_id = t.id AND mt.est_actif = true
        LEFT JOIN utilisateurs u ON u.id = mt.utilisateur_id
        LEFT JOIN comptes_virtuels cv ON cv.tontine_id = t.id
        WHERE t.id = $1
        GROUP BY t.id, cv.solde, cv.total_depots, cv.total_retraits, cv.id
      `, [id]);

      if (!rows[0]) return res.status(404).json({ error: 'Tontine non trouvée' });

      const tontine = {
        ...rows[0],
        prochain_beneficiaire: rows[0].membres?.find(m => !m.a_recu),
        periode_terminee: rows[0].date_fin
          ? new Date() > new Date(rows[0].date_fin)
          : false,
      };

      res.json({ success: true, data: tontine });
    } catch (err) {
      logger.error('Erreur getTontine:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── MODIFIER TONTINE ──────────────────────────────────
  async modifierTontine(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;
      const { nom, description, est_publique, photo_tontine } = req.body;
      const estPublique = est_publique !== undefined ? est_publique : null;

      const { tontine, autorise } = await verifierOrganisateurOuAdmin(pool, id, userId);
      if (!tontine) return res.status(404).json({ error: 'Tontine non trouvée' });
      if (!autorise) return res.status(403).json({ error: 'Accès refusé' });

      const { rows } = await pool.query(`
        UPDATE tontines SET
          nom = COALESCE($1, nom),
          description = COALESCE($2, description),
          est_publique = COALESCE($3, est_publique),
          photo_tontine = COALESCE($4, photo_tontine),
          updated_at = NOW()
        WHERE id = $5
        RETURNING *
      `, [nom, description, estPublique, photo_tontine, id]);

      res.json({ success: true, data: rows[0] });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── SUPPRIMER TONTINE ─────────────────────────────────
  async supprimerTontine(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      const { tontine, autorise } = await verifierOrganisateurOuAdmin(pool, id, userId);
      if (!tontine) return res.status(404).json({ error: 'Tontine non trouvée' });
      if (!autorise) return res.status(403).json({ error: 'Accès refusé' });

      await pool.query(
        "UPDATE tontines SET statut = 'annulee' WHERE id = $1",
        [id]
      );
      res.json({ success: true, message: 'Tontine annulée' });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── INVITER MEMBRE ────────────────────────────────────
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
        const msg = `Vous êtes invité(e) à rejoindre la tontine "${tontineRows[0].nom}" sur TontiLigdi ! Téléchargez l'app : ${LIEN_TELECHARGEMENT}`;
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

      await finaliserGroupeSiComplet(pool, tontine_id, tontineRows[0]);

      await notificationService.notifierMembre(user.id, {
        type: 'invitation_tontine',
        tontine_id,
        nom_tontine: tontineRows[0].nom,
        montant: `${req.user.prenom} ${req.user.nom}`,
      });

      // NOUVEAU: décision produit — tout membre peut inviter, mais
      // l'organisateur est informé pour garder une visibilité sur qui
      // rejoint son groupe (sauf s'il est lui-même l'inviteur).
      if (req.user.id !== tontineRows[0].responsable_id) {
        await notificationService.notifierMembre(tontineRows[0].responsable_id, {
          type: 'nouveau_membre_tontine',
          tontine_id,
          nom_tontine: tontineRows[0].nom,
          nom_acteur: `${user.prenom} ${user.nom} (invité par ${req.user.prenom})`,
        });
      }

      res.json({ success: true, message: 'Membre invité avec succès' });
    } catch (err) {
      logger.error('Erreur inviterMembre:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── REJOINDRE TONTINE ─────────────────────────────────
  async rejoindreTontine(req, res) {
    try {
      const tontine_id = req.params.id;
      const { rows: tontine } = await pool.query(
        'SELECT * FROM tontines WHERE id = $1', [tontine_id]
      );
      if (!tontine[0])
        return res.status(404).json({ error: 'Tontine non trouvée' });

      if (!tontine[0].est_publique) {
        return res.status(403).json({
          error: 'Cette tontine est privée — utilisez la demande d adhésion'
        });
      }

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

      // FIX: voir finaliserGroupeSiComplet — corrige le trou de cotisations
      // jamais générées pour les membres rejoignant après la création.
      await finaliserGroupeSiComplet(pool, tontine_id, tontine[0]);

      await notificationService.notifierMembre(tontine[0].responsable_id, {
        type: 'nouveau_membre_tontine',
        tontine_id,
        nom_tontine: tontine[0].nom,
        nom_acteur: `${req.user.prenom} ${req.user.nom}`,
      });

      res.json({ success: true, message: 'Vous avez rejoint la tontine !' });
    } catch (err) {
      logger.error('Erreur rejoindreTontine:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── DEMANDER ADHÉSION ─────────────────────────────────
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
        nom_acteur: `${req.user.prenom} ${req.user.nom}`,
      });

      res.json({ success: true, message: 'Demande envoyée au responsable' });
    } catch (err) {
      logger.error('Erreur demanderAdhesion:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── MES DEMANDES ──────────────────────────────────────
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

  // ── ACCEPTER ADHÉSION ─────────────────────────────────
  async accepterAdhesion(req, res) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const { adhesionId } = req.params;
      const userId = req.user.id;

      const { rows: adhesion } = await client.query(
        'SELECT * FROM adhesions_tontine WHERE id = $1', [adhesionId]
      );
      if (!adhesion[0]) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Demande non trouvée' });
      }

      const { tontine, autorise } = await verifierOrganisateurOuAdmin(client, adhesion[0].tontine_id, userId);
      if (!autorise) {
        await client.query('ROLLBACK');
        return res.status(403).json({ error: 'Accès refusé' });
      }

      const { rows: existant } = await client.query(
        'SELECT id FROM membres_tontine WHERE tontine_id = $1 AND utilisateur_id = $2',
        [adhesion[0].tontine_id, adhesion[0].demandeur_id]
      );

      if (existant[0]) {
        await client.query(
          'UPDATE membres_tontine SET est_actif = true WHERE id = $1',
          [existant[0].id]
        );
      } else {
        const { rows: count } = await client.query(
          'SELECT COUNT(*) as total FROM membres_tontine WHERE tontine_id = $1 AND est_actif = true',
          [adhesion[0].tontine_id]
        );

        if (parseInt(count[0].total) >= tontine.nombre_membres) {
          await client.query('ROLLBACK');
          return res.status(400).json({ error: 'Le groupe est complet' });
        }

        const position = parseInt(count[0].total) + 1;
        await client.query(
          'INSERT INTO membres_tontine (tontine_id, utilisateur_id, position_rotation) VALUES ($1,$2,$3)',
          [adhesion[0].tontine_id, adhesion[0].demandeur_id, position]
        );
      }

      // FIX: voir finaliserGroupeSiComplet — même trou de cotisations
      // jamais générées, ici pour le circuit demande/acceptation.
      await finaliserGroupeSiComplet(client, adhesion[0].tontine_id, tontine);

      await client.query(
        "UPDATE adhesions_tontine SET statut = 'accepte', updated_at = NOW() WHERE id = $1",
        [adhesionId]
      );

      await client.query('COMMIT');

      await notificationService.notifierMembre(adhesion[0].demandeur_id, {
        type: 'adhesion_acceptee',
        tontine_id: adhesion[0].tontine_id,
        nom_tontine: tontine.nom,
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

  // ── REFUSER ADHÉSION ──────────────────────────────────
  async refuserAdhesion(req, res) {
    try {
      const { adhesionId } = req.params;
      const { motif } = req.body;
      const userId = req.user.id;

      const { rows: [adhesion] } = await pool.query(
        `SELECT at.*, t.nom as tontine_nom FROM adhesions_tontine at
         JOIN tontines t ON t.id = at.tontine_id
         WHERE at.id = $1`, [adhesionId]
      );
      if (!adhesion) return res.status(404).json({ error: 'Demande non trouvée' });

      const { autorise } = await verifierOrganisateurOuAdmin(pool, adhesion.tontine_id, userId);
      if (!autorise) return res.status(403).json({ error: 'Accès refusé' });

      await pool.query(
        "UPDATE adhesions_tontine SET statut = 'refuse', updated_at = NOW() WHERE id = $1",
        [adhesionId]
      );

      // NOUVEAU: le demandeur n'était jamais notifié d'un refus, contrairement
      // à accepterAdhesion qui le fait déjà.
      await notificationService.notifierMembre(adhesion.demandeur_id, {
        type: 'adhesion_refusee',
        tontine_id: adhesion.tontine_id,
        nom_tontine: `${adhesion.tontine_nom}${motif ? ` (${motif})` : ''}`,
      });

      res.json({ success: true, message: 'Demande refusée' });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── RETIRER MEMBRE ────────────────────────────────────
  async retirerMembre(req, res) {
    try {
      const { id, membreId } = req.params;
      const userId = req.user.id;

      const { autorise } = await verifierOrganisateurOuAdmin(pool, id, userId);
      if (!autorise) return res.status(403).json({ error: 'Accès refusé' });

      await pool.query(
        'UPDATE membres_tontine SET est_actif = false WHERE tontine_id = $1 AND utilisateur_id = $2',
        [id, membreId]
      );
      res.json({ success: true, message: 'Membre retiré' });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── COMPTE VIRTUEL ────────────────────────────────────
  async getCompteVirtuel(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      const autorise = await verifierMembreOuPlus(pool, id, userId);
      if (!autorise) return res.status(403).json({ error: 'Accès refusé' });

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
          CASE
            WHEN t.date_fin IS NULL THEN false
            ELSE NOW() > t.date_fin
          END as periode_terminee
        FROM comptes_virtuels cv
        JOIN tontines t ON t.id = cv.tontine_id
        WHERE cv.tontine_id = $1
      `, [id]);

      if (rows.length === 0)
        return res.status(404).json({ error: 'Compte virtuel non trouvé' });

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

      const { rows: monDepot } = await pool.query(`
        SELECT COALESCE(SUM(montant), 0) as mon_total
        FROM transactions_virtuelles
        WHERE compte_virtuel_id = $1 AND utilisateur_id = $2 AND type = 'depot' AND statut = 'confirme'
      `, [rows[0].id, userId]);

      const { rows: numerosToeeg } = await pool.query(
        `SELECT operateur, numero FROM numeros_reception_toeeg WHERE actif = true ORDER BY operateur`
      );
      const numeroMobileMoneyAffiche = numerosToeeg.length
        ? numerosToeeg.map(n => `${n.operateur}: ${n.numero}`).join(' / ')
        : '';
      res.json({
        success: true,
        data: {
          ...rows[0],
          transactions,
          mon_depot_total: parseFloat(monDepot[0].mon_total),
          numero_mobile_money: numeroMobileMoneyAffiche,
        }
      });
    } catch (err) {
      logger.error('Erreur getCompteVirtuel:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── EFFECTUER DÉPÔT ───────────────────────────────────
  async effectuerDepot(req, res) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const { id } = req.params;
      const { montant, methode_paiement, telephone_paiement, reference_externe } = req.body;
      const userId = req.user.id;

      if (!montant || parseFloat(montant) <= 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Montant invalide' });
      }

      const { rows: membre } = await client.query(
        'SELECT id FROM membres_tontine WHERE tontine_id = $1 AND utilisateur_id = $2 AND est_actif = true',
        [id, userId]
      );
      if (membre.length === 0) {
        await client.query('ROLLBACK');
        return res.status(403).json({ error: 'Vous n\'êtes pas membre de cette tontine' });
      }

      const { rows: cv } = await client.query(
        'SELECT id, solde FROM comptes_virtuels WHERE tontine_id = $1', [id]
      );
      if (cv.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Compte virtuel non trouvé' });
      }

      const { rows: [infoMembre] } = await client.query(
        'SELECT prenom, nom FROM utilisateurs WHERE id = $1', [userId]
      );

      const { rows: [cotisationCible] } = await client.query(
        `SELECT * FROM cotisations
         WHERE tontine_id = $1 AND membre_id = $2
         AND (
           (statut = 'en_attente' AND capture_url IS NULL)
           OR statut = 'rejete'
           OR statut = 'partiel'
         )
         ORDER BY periode_numero ASC
         LIMIT 1`,
        [id, userId]
      );

      const montantF = parseFloat(montant);
      let cotisationTouchee = null;
      let surplus = 0;
      let nouveauStatutCotisation = null;

      if (cotisationCible) {
        const montantDu = parseFloat(cotisationCible.montant);
        const dejaPaye = parseFloat(cotisationCible.montant_paye) || 0;
        const cumul = dejaPaye + montantF;
        nouveauStatutCotisation = cumul >= montantDu ? 'paye' : 'partiel';
        const montantPayeFinal = Math.min(cumul, montantDu);
        surplus = Math.max(0, cumul - montantDu);

        const { rows: [cotUpdate] } = await client.query(
          `UPDATE cotisations SET statut = $1, montant_paye = $2, methode_paiement = $3,
           date_paiement = CASE WHEN $1 = 'paye' THEN NOW() ELSE date_paiement END
           WHERE id = $4 RETURNING *`,
          [nouveauStatutCotisation, montantPayeFinal, methode_paiement, cotisationCible.id]
        );
        cotisationTouchee = cotUpdate;
      }

      const { rows: transaction } = await client.query(`
        INSERT INTO transactions_virtuelles
          (compte_virtuel_id, utilisateur_id, tontine_id, membre_id, cotisation_id,
           type, montant, methode_paiement, telephone_paiement, reference_externe,
           statut, description)
        VALUES ($1, $2, $3, $2, $4, 'depot', $5, $6, $7, $8, 'confirme', 'Dépôt manuel')
        RETURNING *
      `, [cv[0].id, userId, id, cotisationTouchee?.id || null, montantF, methode_paiement,
          telephone_paiement, reference_externe || null]);

      await client.query(
        'UPDATE comptes_virtuels SET solde = solde + $1, total_depots = total_depots + $1, updated_at = NOW() WHERE id = $2',
        [montantF, cv[0].id]
      );

      let surplusNonAffecte = 0;
      if (surplus > 0 && cotisationCible) {
        surplusNonAffecte = await appliquerSurplus(
          client, id, userId,
          { prenom: infoMembre?.prenom || '', nom_membre: infoMembre?.nom || '' },
          surplus, cotisationCible.periode_numero
        );
      }

      await client.query('COMMIT');

      const { rows: tontine } = await pool.query(
        'SELECT nom FROM tontines WHERE id = $1', [id]
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
        data: transaction[0],
        cotisationStatut: nouveauStatutCotisation,
        surplus,
        surplusNonAffecte,
      });
    } catch (err) {
      await client.query('ROLLBACK');
      logger.error('Erreur dépôt:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    } finally {
      client.release();
    }
  },

  // ── INITIER RETRAIT ───────────────────────────────────
  async initierRetrait(req, res) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const { id } = req.params;
      const { montant, methode_retrait, telephone_retrait, motif } = req.body;
      const userId = req.user.id;

      const { rows: tontine } = await client.query(
        'SELECT * FROM tontines WHERE id = $1', [id]
      );
      if (tontine.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Tontine non trouvée' });
      }

      let autorise = tontine[0].responsable_id === userId;
      if (!autorise) {
        const { rows: [user] } = await client.query(
          'SELECT role FROM utilisateurs WHERE id = $1', [userId]
        );
        autorise = user?.role === 'admin';
      }
      if (!autorise) {
        await client.query('ROLLBACK');
        return res.status(403).json({
          error: 'Seul l organisateur ou un administrateur peut initier un retrait'
        });
      }

      if (tontine[0].date_fin) {
        const maintenant = new Date();
        const dateFin = new Date(tontine[0].date_fin);
        if (maintenant < dateFin) {
          await client.query('ROLLBACK');
          return res.status(400).json({
            error: `Retrait impossible avant la fin de la période (${dateFin.toLocaleDateString()})`
          });
        }
      }

      const { rows: cv } = await client.query(
        'SELECT * FROM comptes_virtuels WHERE tontine_id = $1 FOR UPDATE', [id]
      );
      if (cv.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Compte virtuel non trouvé' });
      }

      if (parseFloat(cv[0].solde) < parseFloat(montant)) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Solde insuffisant' });
      }

      const { rows: retraitEnCours } = await client.query(`
        SELECT id FROM transactions_virtuelles
        WHERE compte_virtuel_id = $1 AND type = 'retrait' AND statut = 'en_attente_vote'
      `, [cv[0].id]);
      if (retraitEnCours.length > 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Un retrait est déjà en cours de vote' });
      }

      const { rows: retrait } = await client.query(`
        INSERT INTO transactions_virtuelles
          (compte_virtuel_id, utilisateur_id, tontine_id, membre_id, type, montant,
           methode_paiement, telephone_paiement, statut, description)
        VALUES ($1, $2, $3, $2, 'retrait', $4, $5, $6, 'en_attente_vote', $7)
        RETURNING *
      `, [cv[0].id, userId, id, montant, methode_retrait, telephone_retrait,
          motif || 'Retrait fin de période']);

      const { rows: membres } = await client.query(
        'SELECT utilisateur_id FROM membres_tontine WHERE tontine_id = $1 AND est_actif = true AND utilisateur_id != $2',
        [id, userId]
      );

      await client.query('COMMIT');

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
      await client.query('ROLLBACK');
      logger.error('Erreur initierRetrait:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    } finally {
      client.release();
    }
  },

  // ── VOTER RETRAIT ─────────────────────────────────────
  async initierPaiementTour(req, res) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const { id } = req.params;
      const userId = req.user.id;

      const { rows: tontine } = await client.query(
        'SELECT * FROM tontines WHERE id = $1', [id]
      );
      if (tontine.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Tontine non trouvée' });
      }

      let autorise = tontine[0].responsable_id === userId;
      if (!autorise) {
        const { rows: [user] } = await client.query(
          'SELECT role FROM utilisateurs WHERE id = $1', [userId]
        );
        autorise = user?.role === 'admin';
      }
      if (!autorise) {
        await client.query('ROLLBACK');
        return res.status(403).json({
          error: 'Seul l organisateur ou un administrateur peut initier un paiement de tour'
        });
      }

      const { rows: [prochain] } = await client.query(
        `SELECT mt.*, u.prenom, u.nom
         FROM membres_tontine mt
         JOIN utilisateurs u ON u.id = mt.utilisateur_id
         WHERE mt.tontine_id = $1 AND mt.est_actif = true AND mt.a_recu = false
         ORDER BY mt.position_rotation ASC LIMIT 1`,
        [id]
      );
      if (!prochain) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Tous les membres actifs ont déjà reçu leur tour' });
      }

      const montantAttendu = parseFloat(tontine[0].montant_cotisation) * tontine[0].nombre_membres;

      const { rows: cv } = await client.query(
        'SELECT * FROM comptes_virtuels WHERE tontine_id = $1 FOR UPDATE', [id]
      );
      if (cv.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Compte virtuel non trouvé' });
      }

      const soldeDisponible = parseFloat(cv[0].solde) || 0;
      if (soldeDisponible < montantAttendu) {
        await client.query('ROLLBACK');
        return res.status(400).json({
          error: `Solde insuffisant pour ce tour : ${soldeDisponible} F disponibles, ${montantAttendu} F requis`
        });
      }

      const { rows: retraitEnCours } = await client.query(`
        SELECT id FROM transactions_virtuelles
        WHERE compte_virtuel_id = $1 AND type = 'retrait' AND statut = 'en_attente_vote'
      `, [cv[0].id]);
      if (retraitEnCours.length > 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Un retrait est déjà en cours de vote' });
      }

      const { rows: retrait } = await client.query(`
        INSERT INTO transactions_virtuelles
          (compte_virtuel_id, utilisateur_id, tontine_id, membre_id, type, montant,
           statut, description, est_tour_paiement)
        VALUES ($1, $2, $3, $4, 'retrait', $5, 'en_attente_vote', $6, true)
        RETURNING *
      `, [cv[0].id, userId, id, prochain.utilisateur_id, montantAttendu,
          `Tour de ${prochain.prenom} ${prochain.nom} (position ${prochain.position_rotation})`]);

      const { rows: membres } = await client.query(
        'SELECT utilisateur_id FROM membres_tontine WHERE tontine_id = $1 AND est_actif = true AND utilisateur_id != $2',
        [id, prochain.utilisateur_id]
      );

      await client.query('COMMIT');

      for (const m of membres) {
        await notificationService.notifierMembre(m.utilisateur_id, {
          type: 'rappel_cotisation',
          nom_tontine: tontine[0].nom,
          montant: `${montantAttendu} F - VOTE POUR LE TOUR DE ${prochain.prenom.toUpperCase()} REQUIS`,
          tontine_id: id,
        });
      }

      res.json({
        success: true,
        message: `Paiement du tour de ${prochain.prenom} ${prochain.nom} initié. ${membres.length} membre(s) doivent voter.`,
        data: retrait[0]
      });
    } catch (err) {
      await client.query('ROLLBACK');
      logger.error('Erreur initierPaiementTour:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    } finally {
      client.release();
    }
  },

  async voterRetrait(req, res) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const { id, retraitId } = req.params;
      const { vote } = req.body;
      const userId = req.user.id;

      const { rows: membre } = await client.query(
        'SELECT id FROM membres_tontine WHERE tontine_id = $1 AND utilisateur_id = $2 AND est_actif = true',
        [id, userId]
      );
      if (membre.length === 0) {
        await client.query('ROLLBACK');
        return res.status(403).json({ error: 'Accès refusé' });
      }

      const { rows: retrait } = await client.query(
        "SELECT * FROM transactions_virtuelles WHERE id = $1 AND statut = 'en_attente_vote'",
        [retraitId]
      );
      if (retrait.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Demande de retrait non trouvée' });
      }

      if (retrait[0].utilisateur_id === userId) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Vous ne pouvez pas voter pour votre propre demande' });
      }

      const { rows: dejaVote } = await client.query(
        'SELECT id FROM votes_retrait WHERE transaction_id = $1 AND utilisateur_id = $2',
        [retraitId, userId]
      );
      if (dejaVote.length > 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Vous avez déjà voté' });
      }

      await client.query(
        'INSERT INTO votes_retrait (transaction_id, compte_virtuel_id, utilisateur_id, vote) VALUES ($1,$2,$3,$4)',
        [retraitId, retrait[0].compte_virtuel_id, userId, vote]
      );

      const { rows: stats } = await client.query(`
        SELECT
          COUNT(*) FILTER (WHERE vr.vote = 'oui') as votes_oui,
          COUNT(*) FILTER (WHERE vr.vote = 'non') as votes_non,
          COUNT(*) as total_votes,
          (SELECT COUNT(*) FROM membres_tontine
           WHERE tontine_id = $1 AND est_actif = true) - 1 as membres_votants
        FROM votes_retrait vr WHERE vr.transaction_id = $2
      `, [id, retraitId]);

      const { votes_oui, votes_non, membres_votants } = stats[0];
      const { rows: tontine } = await client.query(
        'SELECT nom FROM tontines WHERE id = $1', [id]
      );

      if (vote === 'non') {
        await client.query(
          "UPDATE transactions_virtuelles SET statut = 'refuse' WHERE id = $1",
          [retraitId]
        );
        await client.query('COMMIT');
        await notificationService.notifierGroupeTontine(id, {
          type: 'retard_paiement',
          nom_tontine: tontine[0]?.nom,
          montant: 'Retrait refusé par un membre',
          tontine_id: id,
        });
        return res.json({ success: true, message: 'Retrait refusé.', approuve: false, statut: 'refuse' });
      }

      if (parseInt(votes_oui) >= parseInt(membres_votants)) {
        await client.query(
          "UPDATE transactions_virtuelles SET statut = 'approuve' WHERE id = $1",
          [retraitId]
        );
        await client.query(
          'UPDATE comptes_virtuels SET solde = solde - $1, total_retraits = total_retraits + $1, updated_at = NOW() WHERE id = $2',
          [retrait[0].montant, retrait[0].compte_virtuel_id]
        );

        if (retrait[0].est_tour_paiement) {
          await client.query(
            'UPDATE membres_tontine SET a_recu = true, date_reception = NOW() WHERE tontine_id = $1 AND utilisateur_id = $2',
            [id, retrait[0].membre_id]
          );
        }
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

  // ── TRANSACTIONS ──────────────────────────────────────
  async getTransactions(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      const autorise = await verifierMembreOuPlus(pool, id, userId);
      if (!autorise) return res.status(403).json({ error: 'Accès refusé' });

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

  // ── STATISTIQUES ──────────────────────────────────────
  async getStatistiques(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      const autorise = await verifierMembreOuPlus(pool, id, userId);
      if (!autorise) return res.status(403).json({ error: 'Accès refusé' });

      const { rows } = await pool.query(`
        SELECT
          COUNT(c.id) as total_cotisations,
          SUM(CASE WHEN c.statut IN ('paye', 'partiel') THEN c.montant_paye ELSE 0 END) as montant_collecte,
          SUM(CASE WHEN c.statut IN ('en_attente', 'partiel') THEN c.montant - COALESCE(c.montant_paye, 0) ELSE 0 END) as montant_attendu,
          COUNT(CASE WHEN c.statut = 'en_retard' THEN 1 END) as cotisations_en_retard,
          COUNT(CASE WHEN c.statut = 'partiel' THEN 1 END) as cotisations_partielles,
          AVG(u.score_fiabilite) as score_moyen_groupe,
          cv.solde as solde_virtuel,
          cv.total_depots,
          cv.total_retraits
        FROM cotisations c
        JOIN utilisateurs u ON u.id = c.membre_id
        LEFT JOIN comptes_virtuels cv ON cv.tontine_id = c.tontine_id
        WHERE c.tontine_id = $1
        GROUP BY cv.solde, cv.total_depots, cv.total_retraits
      `, [id]);
      res.json({ success: true, data: rows[0] });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── COTISATIONS ───────────────────────────────────────
  async getCotisations(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      const autorise = await verifierMembreOuPlus(pool, id, userId);
      if (!autorise) return res.status(403).json({ error: 'Accès refusé' });

      const { rows } = await pool.query(`
        SELECT c.*, u.nom, u.prenom, u.telephone
        FROM cotisations c
        JOIN utilisateurs u ON u.id = c.membre_id
        WHERE c.tontine_id = $1
        ORDER BY c.periode_numero DESC, c.date_echeance DESC
      `, [id]);
      res.json({ success: true, data: rows });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── MEMBRES ───────────────────────────────────────────
  async getMembres(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      const autorise = await verifierMembreOuPlus(pool, id, userId);
      if (!autorise) return res.status(403).json({ error: 'Accès refusé' });

      const { rows } = await pool.query(`
        SELECT u.id, u.nom, u.prenom, u.telephone, u.score_fiabilite,
          u.photo_profil, mt.position_rotation, mt.a_recu, mt.date_reception,
          COUNT(CASE WHEN c.statut = 'paye' THEN 1 END) as total_paiements,
          COUNT(CASE WHEN c.statut = 'partiel' THEN 1 END) as total_partiels,
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
      `, [id]);
      res.json({ success: true, data: rows });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  // ── EMPRUNTS ──────────────────────────────────────────
  async demanderEmprunt(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;
      const { montant, date_echeance } = req.body;

      const { rows: membre } = await pool.query(
        'SELECT id FROM membres_tontine WHERE tontine_id = $1 AND utilisateur_id = $2 AND est_actif = true',
        [id, userId]
      );
      if (membre.length === 0) {
        return res.status(403).json({ error: 'Vous n\'êtes pas membre de cette tontine' });
      }

      const { rows } = await pool.query(`
        INSERT INTO emprunts (tontine_id, emprunteur_id, montant, date_echeance, montant_rembourse, statut)
        VALUES ($1,$2,$3,$4,0,'en_attente') RETURNING *
      `, [id, userId, montant, date_echeance]);
      res.status(201).json({ success: true, data: rows[0] });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async voterEmprunt(req, res) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const { id, empruntId } = req.params;
      const userId = req.user.id;
      const { vote } = req.body;

      const { rows: membre } = await client.query(
        'SELECT id FROM membres_tontine WHERE tontine_id = $1 AND utilisateur_id = $2 AND est_actif = true',
        [id, userId]
      );
      if (membre.length === 0) {
        await client.query('ROLLBACK');
        return res.status(403).json({ error: 'Accès refusé' });
      }

      const { rows } = await client.query(
        'SELECT * FROM emprunts WHERE id = $1', [empruntId]
      );
      if (!rows[0]) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Emprunt non trouvé' });
      }

      if (rows[0].emprunteur_id === userId) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Vous ne pouvez pas voter pour votre propre demande' });
      }

      if (rows[0].statut !== 'en_attente') {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Cet emprunt n est plus en attente de vote' });
      }

      const approuves = rows[0].approuve_par || [];

      if (approuves.some(v => v.userId === userId)) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Vous avez déjà voté' });
      }

      const newApprouves = [...approuves, { userId, vote, date: new Date() }];

      const { rows: [{ count: nbMembresActifs }] } = await client.query(
        'SELECT COUNT(*) FROM membres_tontine WHERE tontine_id = $1 AND est_actif = true AND utilisateur_id != $2',
        [id, rows[0].emprunteur_id]
      );
      const votesOui = newApprouves.filter(v => v.vote === 'oui').length;
      const votesNon = newApprouves.filter(v => v.vote === 'non').length;
      const seuilMajorite = Math.floor(parseInt(nbMembresActifs) / 2) + 1;

      let nouveauStatut = 'en_attente';
      let fondsInsuffisants = false;

      if (votesOui >= seuilMajorite) {
        // FIX: vérifie enfin que le compte virtuel a réellement les fonds
        // avant d'approuver — jusqu'ici un emprunt approuvé ne touchait
        // jamais au solde réel, qui restait affiché comme "disponible"
        // alors qu'une partie était en réalité prêtée.
        const { rows: [cv] } = await client.query(
          'SELECT * FROM comptes_virtuels WHERE tontine_id = $1 FOR UPDATE', [id]
        );
        const soldeDisponible = parseFloat(cv?.solde) || 0;
        const montantEmprunt = parseFloat(rows[0].montant);

        if (soldeDisponible >= montantEmprunt) {
          nouveauStatut = 'approuve';

          await client.query(
            'UPDATE comptes_virtuels SET solde = solde - $1, updated_at = NOW() WHERE id = $2',
            [montantEmprunt, cv.id]
          );

          const { rows: [emprunteur] } = await client.query(
            'SELECT prenom, nom FROM utilisateurs WHERE id = $1', [rows[0].emprunteur_id]
          );

          await client.query(
            `INSERT INTO transactions_virtuelles
              (tontine_id, compte_virtuel_id, type, montant, membre_id, utilisateur_id,
               description, solde_avant, solde_apres)
             VALUES ($1,$2,'retrait',$3,$4,$4,$5,$6,$7)`,
            [id, cv.id, montantEmprunt, rows[0].emprunteur_id,
             `Emprunt accordé à ${emprunteur?.prenom || ''} ${emprunteur?.nom || ''}`,
             soldeDisponible, soldeDisponible - montantEmprunt]
          );
        } else {
          fondsInsuffisants = true;
        }
      } else if (votesNon >= seuilMajorite) {
        nouveauStatut = 'refuse';
      }

      await client.query(
        'UPDATE emprunts SET approuve_par = $1, statut = $2 WHERE id = $3',
        [JSON.stringify(newApprouves), nouveauStatut, empruntId]
      );

      await client.query('COMMIT');

      res.json({
        success: true,
        message: nouveauStatut === 'approuve' ? 'Emprunt approuvé et décaissé !'
          : fondsInsuffisants ? 'Majorité atteinte, mais le solde de la tontine est insuffisant pour décaisser cet emprunt.'
          : nouveauStatut === 'refuse' ? 'Emprunt refusé.'
          : `Vote enregistré. ${votesOui}/${seuilMajorite} votes pour requis.`,
        statut: nouveauStatut,
        votesOui,
        votesNon,
        seuilMajorite,
        fondsInsuffisants,
      });
    } catch (err) {
      await client.query('ROLLBACK');
      logger.error('Erreur voterEmprunt:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    } finally {
      client.release();
    }
  },
async rembourserEmprunt(req, res) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const { empruntId } = req.params;
      const { montant } = req.body;
      const userId = req.user.id;
      const montantF = parseFloat(montant);

      if (!montantF || montantF <= 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Montant invalide' });
      }

      const { rows: [emprunt] } = await client.query(
        'SELECT * FROM emprunts WHERE id = $1', [empruntId]
      );
      if (!emprunt) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Emprunt non trouvé' });
      }

      // FIX: aucune vérification d'accès auparavant — n'importe quel
      // utilisateur authentifié pouvait rembourser n'importe quel emprunt.
      const { rows: membre } = await client.query(
        'SELECT id FROM membres_tontine WHERE tontine_id = $1 AND utilisateur_id = $2 AND est_actif = true',
        [emprunt.tontine_id, userId]
      );
      if (membre.length === 0) {
        await client.query('ROLLBACK');
        return res.status(403).json({ error: 'Vous n\'êtes pas membre de cette tontine' });
      }

      if (emprunt.statut !== 'approuve') {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Cet emprunt n\'est pas en cours (non approuvé ou déjà remboursé)' });
      }

      const nouveauMontantRembourse = (parseFloat(emprunt.montant_rembourse) || 0) + montantF;
      const nouveauStatut = nouveauMontantRembourse >= parseFloat(emprunt.montant) ? 'rembourse' : 'approuve';

      const { rows: [empruntMaj] } = await client.query(
        `UPDATE emprunts SET montant_rembourse = $1, statut = $2 WHERE id = $3 RETURNING *`,
        [nouveauMontantRembourse, nouveauStatut, empruntId]
      );

      // FIX: crédite enfin le remboursement au solde réel — jusqu'ici
      // jamais connecté, le solde affiché ne reflétait jamais les
      // remboursements d'emprunts.
      const { rows: [cv] } = await client.query(
        'SELECT * FROM comptes_virtuels WHERE tontine_id = $1 FOR UPDATE', [emprunt.tontine_id]
      );
      const soldeAvant = parseFloat(cv?.solde) || 0;

      await client.query(
        'UPDATE comptes_virtuels SET solde = solde + $1, total_depots = total_depots + $1, updated_at = NOW() WHERE id = $2',
        [montantF, cv.id]
      );

      const { rows: [emprunteur] } = await client.query(
        'SELECT prenom, nom FROM utilisateurs WHERE id = $1', [emprunt.emprunteur_id]
      );

      await client.query(
        `INSERT INTO transactions_virtuelles
          (tontine_id, compte_virtuel_id, type, montant, membre_id, utilisateur_id,
           description, solde_avant, solde_apres)
         VALUES ($1,$2,'depot',$3,$4,$4,$5,$6,$7)`,
        [emprunt.tontine_id, cv.id, montantF, emprunt.emprunteur_id,
         `Remboursement emprunt de ${emprunteur?.prenom || ''} ${emprunteur?.nom || ''}`,
         soldeAvant, soldeAvant + montantF]
      );

      await client.query('COMMIT');

      res.json({ success: true, data: empruntMaj, statut: nouveauStatut });
    } catch (err) {
      await client.query('ROLLBACK');
      logger.error('Erreur rembourserEmprunt:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    } finally {
      client.release();
    }
  },

  // ── RAPPORT ───────────────────────────────────────────
  async genererRapport(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      const autorise = await verifierMembreOuPlus(pool, id, userId);
      if (!autorise) return res.status(403).json({ error: 'Accès refusé' });

      const [tontine, membres, cotisations, compteVirtuel] = await Promise.all([
        pool.query('SELECT * FROM tontines WHERE id = $1', [id]),
        pool.query(`
          SELECT u.nom, u.prenom, u.photo_profil, mt.position_rotation, mt.a_recu
          FROM membres_tontine mt
          JOIN utilisateurs u ON u.id = mt.utilisateur_id
          WHERE mt.tontine_id = $1
        `, [id]),
        pool.query(
          'SELECT * FROM cotisations WHERE tontine_id = $1 ORDER BY periode_numero, date_echeance',
          [id]
        ),
        pool.query(
          'SELECT * FROM comptes_virtuels WHERE tontine_id = $1', [id]
        )
      ]);

      const rapport = {
        tontine: tontine.rows[0],
        membres: membres.rows,
        cotisations: cotisations.rows,
        compte_virtuel: compteVirtuel.rows[0] || null,
        resume: {
          total_collecte: cotisations.rows
            .filter(c => c.statut === 'paye' || c.statut === 'partiel')
            .reduce((sum, c) => sum + (parseFloat(c.montant_paye) || 0), 0),
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

  async confirmerDeclarationUSSD(req, res) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const { declarationId } = req.params;
      const userId = req.user.id;

      const { rows: [decl] } = await client.query(
        'SELECT * FROM declarations_paiement_ussd WHERE id = $1', [declarationId]
      );
      if (!decl) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Déclaration non trouvée' });
      }
      if (decl.statut !== 'en_attente_verification') {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Cette déclaration a déjà été traitée' });
      }

      const { rows: [tontineCheck] } = await client.query(
        'SELECT responsable_id FROM tontines WHERE id = $1', [decl.tontine_id]
      );
      const { rows: [userCheck] } = await client.query(
        'SELECT role FROM utilisateurs WHERE id = $1', [userId]
      );
      const autorise = tontineCheck?.responsable_id === userId || userCheck?.role === 'admin';
      if (!autorise) {
        await client.query('ROLLBACK');
        return res.status(403).json({ error: 'Accès refusé' });
      }

      const { rows: [cot] } = await client.query(
        'SELECT * FROM cotisations WHERE id = $1', [decl.cotisation_id]
      );
      if (!cot) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Cotisation non trouvée' });
      }

      const montantDu = parseFloat(cot.montant);
      const dejaPaye = parseFloat(cot.montant_paye) || 0;
      const montantDeclare = parseFloat(decl.montant_declare);
      const cumul = dejaPaye + montantDeclare;
      const nouveauStatut = cumul >= montantDu ? 'paye' : 'partiel';
      const montantPayeFinal = Math.min(cumul, montantDu);

      const datePaiementValue = nouveauStatut === 'paye' ? new Date() : null;

      await client.query(`
        UPDATE cotisations SET statut = $1, montant_paye = $2,
        date_paiement = COALESCE($3, date_paiement)
        WHERE id = $4
      `, [nouveauStatut, montantPayeFinal, datePaiementValue, cot.id]);

      const { rows: [cvAvant] } = await client.query(
        'SELECT * FROM comptes_virtuels WHERE tontine_id = $1', [decl.tontine_id]
      );
      const soldeAvant = parseFloat(cvAvant?.solde) || 0;
      const soldeApres = soldeAvant + montantDeclare;

      await client.query(`
        INSERT INTO comptes_virtuels (tontine_id, solde, total_depots)
        VALUES ($1, $2, $2)
        ON CONFLICT (tontine_id)
        DO UPDATE SET solde = comptes_virtuels.solde + $2,
                      total_depots = COALESCE(comptes_virtuels.total_depots, 0) + $2,
                      updated_at = NOW()
      `, [decl.tontine_id, montantDeclare]);

      const { rows: [cvApres] } = await client.query(
        'SELECT id FROM comptes_virtuels WHERE tontine_id = $1', [decl.tontine_id]
      );

      await client.query(`
        INSERT INTO transactions_virtuelles
          (compte_virtuel_id, utilisateur_id, tontine_id, membre_id, cotisation_id,
           solde_avant, solde_apres, type, montant, statut, description)
        VALUES ($1, $2, $3, $2, $4, $5, $6, 'depot', $7, 'confirme', 'Paiement confirmé (déclaration USSD)')
      `, [cvApres?.id, decl.membre_id, decl.tontine_id, cot.id, soldeAvant, soldeApres, montantDeclare]);

      await client.query(`
        UPDATE declarations_paiement_ussd
        SET statut = 'confirme', traite_le = NOW(), traite_par = $1
        WHERE id = $2
      `, [userId, declarationId]);

      await client.query('COMMIT');

      const { rows: [tontine] } = await pool.query('SELECT nom FROM tontines WHERE id = $1', [decl.tontine_id]);

      const messageDetaille = `✅ Paiement confirmé pour "${tontine?.nom}" !\nMontant ajouté: ${montantDeclare}F\nSolde tontine avant: ${soldeAvant}F\nSolde tontine après: ${soldeApres}F\nMerci !`;

      await notificationService.notifierMembre(decl.membre_id, {
        type: 'paiement_confirme',
        tontine_id: decl.tontine_id,
        message_override: messageDetaille,
      });

      await notificationService.notifierGroupeTontine(decl.tontine_id, {
        type: 'paiement_confirme',
        nom_tontine: tontine?.nom,
        montant: montantDeclare.toString(),
        tontine_id: decl.tontine_id,
      });

      res.json({ success: true, message: 'Paiement confirmé', nouveauStatut, soldeAvant, soldeApres });
    } catch (err) {
      await client.query('ROLLBACK');
      logger.error('Erreur confirmerDeclarationUSSD:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    } finally {
      client.release();
    }
  },

  async rejeterDeclarationUSSD(req, res) {
    try {
      const { declarationId } = req.params;
      const { motif } = req.body;
      const userId = req.user.id;

      const { rows: [decl] } = await pool.query(
        'SELECT * FROM declarations_paiement_ussd WHERE id = $1', [declarationId]
      );
      if (!decl) return res.status(404).json({ error: 'Déclaration non trouvée' });
      if (decl.statut !== 'en_attente_verification') {
        return res.status(400).json({ error: 'Cette déclaration a déjà été traitée' });
      }

      const { rows: [tontineCheck] } = await pool.query(
        'SELECT responsable_id FROM tontines WHERE id = $1', [decl.tontine_id]
      );
      const { rows: [userCheck] } = await pool.query(
        'SELECT role FROM utilisateurs WHERE id = $1', [userId]
      );
      const autorise = tontineCheck?.responsable_id === userId || userCheck?.role === 'admin';
      if (!autorise) return res.status(403).json({ error: 'Accès refusé' });

      await pool.query(`
        UPDATE declarations_paiement_ussd
        SET statut = 'rejete', traite_le = NOW(), traite_par = $1
        WHERE id = $2
      `, [userId, declarationId]);

      const { rows: [tontine] } = await pool.query('SELECT nom FROM tontines WHERE id = $1', [decl.tontine_id]);
      const messageRejet = `❌ Votre déclaration de paiement de ${decl.montant_declare}F pour "${tontine?.nom}" n'a pas pu être confirmée${motif ? ` (${motif})` : ''}. Contactez l'organisateur.`;

      await notificationService.notifierMembre(decl.membre_id, {
        type: 'declaration_rejetee',
        tontine_id: decl.tontine_id,
        message_override: messageRejet,
      });

      res.json({ success: true, message: 'Déclaration rejetée' });
    } catch (err) {
      logger.error('Erreur rejeterDeclarationUSSD:', err);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async getDeclarationsEnAttente(req, res) {
    try {
      const { tontineId } = req.params;
      const userId = req.user.id;

      const { rows: [tontineCheck] } = await pool.query(
        'SELECT responsable_id FROM tontines WHERE id = $1', [tontineId]
      );
      const { rows: [userCheck] } = await pool.query(
        'SELECT role FROM utilisateurs WHERE id = $1', [userId]
      );
      const autorise = tontineCheck?.responsable_id === userId || userCheck?.role === 'admin';
      if (!autorise) return res.status(403).json({ error: 'Accès refusé' });

      const { rows } = await pool.query(`
        SELECT d.*, u.prenom, u.nom, u.telephone
        FROM declarations_paiement_ussd d
        JOIN utilisateurs u ON u.id = d.membre_id
        WHERE d.tontine_id = $1 AND d.statut = 'en_attente_verification'
        ORDER BY d.created_at ASC
      `, [tontineId]);

      res.json({ success: true, data: rows });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },
};

// ── FONCTIONS UTILITAIRES ──────────────────────────────
function calculerJoursRestants(tontine) {
  if (!tontine.date_fin) return 99;
  const dateFin = new Date(tontine.date_fin);
  const maintenant = new Date();
  return Math.max(0, Math.floor((dateFin - maintenant) / (1000 * 60 * 60 * 24)));
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
