const { pool } = require('../../config/database');
const { deleteCache } = require('../../config/redis');
const notificationService = require('../services/notificationService');
const logger = require('../utils/logger');
const { v4: uuidv4 } = require('uuid');
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
  // FIX: est_admin n'existe pas comme colonne — le statut admin passe par
  // role = 'admin' (confirmé via information_schema.columns).
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
 * Pour les actions de modération/gestion (modifier, supprimer, accepter/
 * refuser une adhésion, retirer un membre, initier un retrait...).
 * Renvoie aussi la tontine chargée pour éviter une requête séparée.
 */
async function verifierOrganisateurOuAdmin(dbClient, tontineId, userId) {
  const { rows: [tontine] } = await dbClient.query(
    'SELECT * FROM tontines WHERE id = $1',
    [tontineId]
  );
  if (!tontine) return { tontine: null, autorise: false };
  if (tontine.responsable_id === userId) return { tontine, autorise: true };

  // FIX: même correction — role = 'admin' au lieu de est_admin (inexistant).
  const { rows: [user] } = await dbClient.query(
    'SELECT role FROM utilisateurs WHERE id = $1',
    [userId]
  );
  return { tontine, autorise: user?.role === 'admin' };
}

/**
 * DUPLICATION CONNUE (dette technique à consolider) : cette fonction existe
 * à l identique dans backend/src/routes/paiements.js et
 * backend/src/routes/tontines.js. Trois copies de la même logique de
 * paiement par tranche / report de surplus — à extraire dans un service
 * partagé (ex: cotisationService.js) importé par les trois fichiers dès
 * que ce lot de correctifs sera testé et stabilisé.
 */
async function appliquerSurplus(client, tontineId, membreId, membreInfo, surplusInitial, periodeDepart) {
  let surplus = surplusInitial;
  let derniereDeriode = periodeDepart;

  while (surplus > 0) {
    const { rows: [prochaine] } = await client.query(
      `SELECT * FROM cotisations
       WHERE tontine_id = $1 AND membre_id = $2
       AND (
         (statut = 'en_attente' AND capture_url IS NULL)
         OR statut = 'partiel'
       )
       AND periode_numero > $3
       ORDER BY periode_numero ASC
       LIMIT 1`,
      [tontineId, membreId, derniereDeriode]
    );

    if (!prochaine) break;

    const montantDu = parseFloat(prochaine.montant);
    const dejaPaye = parseFloat(prochaine.montant_paye) || 0;
    const restant = montantDu - dejaPaye;
    const aAppliquer = Math.min(surplus, restant);
    const cumul = dejaPaye + aAppliquer;
    const nouveauStatut = cumul >= montantDu ? 'paye' : 'partiel';

    await client.query(
      `UPDATE cotisations SET statut = $1, montant_paye = $2,
       date_paiement = CASE WHEN $1 = 'paye' THEN NOW() ELSE date_paiement END
       WHERE id = $3`,
      [nouveauStatut, Math.min(cumul, montantDu), prochaine.id]
    );

    await client.query(
      `INSERT INTO comptes_virtuels (tontine_id, solde, total_depots)
       VALUES ($1, $2, $2)
       ON CONFLICT (tontine_id)
       DO UPDATE SET solde = comptes_virtuels.solde + $2,
                     total_depots = COALESCE(comptes_virtuels.total_depots, 0) + $2,
                     updated_at = NOW()`,
      [tontineId, aAppliquer]
    );

    await client.query(
      `INSERT INTO transactions_virtuelles (
        tontine_id, type, montant, membre_id, utilisateur_id, cotisation_id, description
      ) VALUES ($1, 'depot', $2, $3, $3, $4, $5)`,
      [tontineId, aAppliquer, membreId, prochaine.id,
       `Surplus reporté (période ${derniereDeriode} → ${prochaine.periode_numero}) - ${membreInfo.prenom} ${membreInfo.nom_membre}`]
    );

    surplus -= aAppliquer;
    derniereDeriode = prochaine.periode_numero;
  }

  return surplus;
}

const tontineController = {

  // ── MES TONTINES ──────────────────────────────────────
  async getMesTontines(req, res) {
    try {
      // FIX: le calcul de "période actuelle" se basait sur
      // MAX(periode_numero) — la DERNIÈRE période du cycle complet, presque
      // toujours encore 'en_attente' jusqu à la toute fin de la tontine.
      // Le pourcentage de complétion affiché était donc quasi toujours 0%.
      // On prend maintenant la période la plus ANCIENNE pas encore soldée
      // (MIN parmi les statuts != 'paye'), qui représente la vraie période
      // "en cours" de collecte.
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
        AND (t.est_public = true OR t.est_publique = true)
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
        est_publique, est_public,
        photo_tontine, devise, pays,
        orange_money_numero, moov_money_numero,
        mtn_numero, wave_numero,
      } = req.body;

      const estPublique = est_publique || est_public || false;

      const date_fin = calculerDateFin(
        date_debut, periodicite, periodicite_jours, nombre_membres
      );

      const { rows } = await client.query(`
        INSERT INTO tontines (nom, type, description, montant_cotisation, periodicite,
          periodicite_jours, nombre_membres, date_debut, date_fin, ordre_rotation,
          responsable_id, produit_catalogue_id, est_publique, est_public, photo_tontine)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)
        RETURNING *
      `, [nom, type, description, montant_cotisation, periodicite,
          periodicite_jours || 1, nombre_membres, date_debut, date_fin,
          ordre_rotation || 'tirage_sort', req.user.id,
          produit_catalogue_id || null,
          estPublique, estPublique,
          photo_tontine || null]);

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

  // ── DÉTAIL TONTINE ────────────────────────────────────
  async getTontine(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      // FIX: aucune vérification d accès auparavant — n importe quel
      // utilisateur authentifié pouvait voir la liste complète des membres
      // (dont leurs numéros de téléphone) et le solde de n importe quelle
      // tontine, y compris privée.
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
      const { nom, description, est_publique, est_public, photo_tontine } = req.body;
      const estPublique = est_publique !== undefined ? est_publique
        : est_public !== undefined ? est_public : null;

      // FIX: seul responsable_id était vérifié (dans le WHERE de l UPDATE
      // lui-même) — pas d accès admin, et un échec silencieux (pas de ligne
      // modifiée = message d erreur générique sans distinction du cas).
      const { tontine, autorise } = await verifierOrganisateurOuAdmin(pool, id, userId);
      if (!tontine) return res.status(404).json({ error: 'Tontine non trouvée' });
      if (!autorise) return res.status(403).json({ error: 'Accès refusé' });

      const { rows } = await pool.query(`
        UPDATE tontines SET
          nom = COALESCE($1, nom),
          description = COALESCE($2, description),
          est_publique = COALESCE($3, est_publique),
          est_public = COALESCE($3, est_public),
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

      // FIX: même gap d accès admin que modifierTontine.
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
  // NOTE: aucune restriction sur qui peut inviter (pas seulement
  // l organisateur) — laissé tel quel intentionnellement, car ambigu si
  // c est voulu (un membre invite ses proches) ou pas. À clarifier si besoin.
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

  // ── REJOINDRE TONTINE ─────────────────────────────────
  async rejoindreTontine(req, res) {
    try {
      const tontine_id = req.params.id;
      const { rows: tontine } = await pool.query(
        'SELECT * FROM tontines WHERE id = $1', [tontine_id]
      );
      if (!tontine[0])
        return res.status(404).json({ error: 'Tontine non trouvée' });

      // FIX: aucune vérification que la tontine est publique — n importe
      // qui pouvait rejoindre directement une tontine PRIVÉE, contournant
      // entièrement le circuit demande/validation (demanderAdhesion).
      if (!(tontine[0].est_publique || tontine[0].est_public)) {
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
        montant: `${req.user.prenom} ${req.user.nom}`,
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

      // FIX MAJEUR: aucune vérification que le demandeur est bien
      // l organisateur (ou un admin) de la tontine concernée par CETTE
      // adhésion — n importe quel utilisateur authentifié pouvait accepter
      // n importe quelle demande d adhésion sur n importe quelle tontine,
      // ajoutant des membres sans le consentement de l organisateur.
      const { tontine, autorise } = await verifierOrganisateurOuAdmin(client, adhesion[0].tontine_id, userId);
      if (!autorise) {
        await client.query('ROLLBACK');
        return res.status(403).json({ error: 'Accès refusé' });
      }

      // FIX: si une ligne existe déjà (membre actif, ou ancien membre exclu
      // dont la ligne persiste avec est_actif=false), l'INSERT plantait sur
      // la contrainte unique (tontine_id, utilisateur_id). On réactive
      // l'existant au lieu d'en créer un doublon.
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
      const userId = req.user.id;

      const { rows: [adhesion] } = await pool.query(
        'SELECT * FROM adhesions_tontine WHERE id = $1', [adhesionId]
      );
      if (!adhesion) return res.status(404).json({ error: 'Demande non trouvée' });

      // FIX: même faille que accepterAdhesion — aucune vérification que le
      // demandeur est organisateur/admin de la tontine concernée.
      const { autorise } = await verifierOrganisateurOuAdmin(pool, adhesion.tontine_id, userId);
      if (!autorise) return res.status(403).json({ error: 'Accès refusé' });

      await pool.query(
        "UPDATE adhesions_tontine SET statut = 'refuse', updated_at = NOW() WHERE id = $1",
        [adhesionId]
      );
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

      // FIX: aucune vérification d accès — n importe qui pouvait retirer
      // n importe quel membre de n importe quelle tontine.
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

      // FIX: n autorisait que les membres — un organisateur/admin externe
      // à la liste des membres actifs ne pouvait pas consulter le compte.
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

      // FIX: cherche la période éligible (même règle que /paiements/soumettre)
      // au lieu de flipper aveuglément la plus ancienne 'en_attente' à
      // 'paye' peu importe le montant réellement déposé — désormais aligné
      // sur le suivi montant_paye / paiement par tranche.
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

      // FIX: seul responsable_id était vérifié — ajout de l accès admin.
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

      // FIX: SELECT ... FOR UPDATE pour verrouiller la ligne pendant la
      // vérification du solde — évite que deux retraits initiés en même
      // temps passent tous les deux la vérification sur un solde périmé.
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
    try {
      const { id, empruntId } = req.params;
      const userId = req.user.id;
      const { vote } = req.body;

      const { rows: membre } = await pool.query(
        'SELECT id FROM membres_tontine WHERE tontine_id = $1 AND utilisateur_id = $2 AND est_actif = true',
        [id, userId]
      );
      if (membre.length === 0) {
        return res.status(403).json({ error: 'Accès refusé' });
      }

      const { rows } = await pool.query(
        'SELECT * FROM emprunts WHERE id = $1', [empruntId]
      );
      if (!rows[0])
        return res.status(404).json({ error: 'Emprunt non trouvé' });

      if (rows[0].emprunteur_id === userId) {
        return res.status(400).json({ error: 'Vous ne pouvez pas voter pour votre propre demande' });
      }

      if (rows[0].statut !== 'en_attente') {
        return res.status(400).json({ error: 'Cet emprunt n est plus en attente de vote' });
      }

      const approuves = rows[0].approuve_par || [];

      if (approuves.some(v => v.userId === userId)) {
        return res.status(400).json({ error: 'Vous avez déjà voté' });
      }

      const newApprouves = [...approuves, { userId, vote, date: new Date() }];

      const { rows: [{ count: nbMembresActifs }] } = await pool.query(
        'SELECT COUNT(*) FROM membres_tontine WHERE tontine_id = $1 AND est_actif = true AND utilisateur_id != $2',
        [id, rows[0].emprunteur_id]
      );
      const votesOui = newApprouves.filter(v => v.vote === 'oui').length;
      const votesNon = newApprouves.filter(v => v.vote === 'non').length;
      const seuilMajorite = Math.floor(parseInt(nbMembresActifs) / 2) + 1;

      let nouveauStatut = 'en_attente';
      if (votesOui >= seuilMajorite) nouveauStatut = 'approuve';
      else if (votesNon >= seuilMajorite) nouveauStatut = 'refuse';

      await pool.query(
        'UPDATE emprunts SET approuve_par = $1, statut = $2 WHERE id = $3',
        [JSON.stringify(newApprouves), nouveauStatut, empruntId]
      );

      res.json({
        success: true,
        message: nouveauStatut === 'approuve' ? 'Emprunt approuvé !'
          : nouveauStatut === 'refuse' ? 'Emprunt refusé.'
          : `Vote enregistré. ${votesOui}/${seuilMajorite} votes pour requis.`,
        statut: nouveauStatut,
        votesOui,
        votesNon,
        seuilMajorite,
      });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  async rembourserEmprunt(req, res) {
    try {
      const { montant } = req.body;
      const { rows } = await pool.query(`
        UPDATE emprunts SET
          montant_rembourse = COALESCE(montant_rembourse, 0) + $1,
          statut = CASE WHEN COALESCE(montant_rembourse, 0) + $1 >= montant THEN 'rembourse' ELSE statut END
        WHERE id = $2 RETURNING *
      `, [montant, req.params.empruntId]);
      res.json({ success: true, data: rows[0] });
    } catch (err) {
      res.status(500).json({ error: 'Erreur serveur' });
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