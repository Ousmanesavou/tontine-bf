const express = require('express');
const router = express.Router();
const tontineController = require('../controllers/tontineController');
const { authenticate } = require('../middleware/auth');
const { validateTontine } = require('../middleware/validation');
const { pool } = require('../../config/database');
const notificationService = require('../services/notificationService');

router.use(authenticate);

/**
 * Vérifie que l utilisateur est soit l organisateur (responsable_id) soit un
 * administrateur (utilisateurs.role = 'admin') de la tontine donnée.
 * Centralise ce contrôle pour toutes les routes réservées à l organisateur/
 * admin dans ce fichier, au lieu de dupliquer "WHERE responsable_id = $2"
 * partout (ce qui excluait silencieusement les admins auparavant).
 */
async function verifierAccesOrganisateur(dbClient, tontineId, userId) {
  const { rows: [tontine] } = await dbClient.query(
    'SELECT * FROM tontines WHERE id = $1',
    [tontineId]
  );
  if (!tontine) return { tontine: null, autorise: false };

  if (tontine.responsable_id === userId) return { tontine, autorise: true };

  // FIX: est_admin n'existe pas comme colonne — utiliser role = 'admin'.
  const { rows: [user] } = await dbClient.query(
    'SELECT role FROM utilisateurs WHERE id = $1',
    [userId]
  );
  return { tontine, autorise: user?.role === 'admin' };
}

/**
 * DUPLICATION CONNUE (dette technique à consolider) : copie de
 * appliquerSurplus() définie dans backend/src/routes/paiements.js — voir
 * la note à cet endroit pour le contexte.
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
      `UPDATE cotisations SET
        statut = $1,
        montant_paye = $2,
        date_paiement = CASE WHEN $1 = 'paye' THEN NOW() ELSE date_paiement END
       WHERE id = $3`,
      [nouveauStatut, Math.min(cumul, montantDu), prochaine.id]
    );

    const { rows: [compteVirtuel] } = await client.query(
      `INSERT INTO comptes_virtuels (tontine_id, solde, total_depots)
       VALUES ($1, $2, $2)
       ON CONFLICT (tontine_id)
       DO UPDATE SET solde = comptes_virtuels.solde + $2,
                     total_depots = COALESCE(comptes_virtuels.total_depots, 0) + $2,
                     updated_at = NOW()
       RETURNING id`,
      [tontineId, aAppliquer]
    );

    await client.query(
      `INSERT INTO transactions_virtuelles (
        tontine_id, compte_virtuel_id, type, montant, membre_id, utilisateur_id,
        cotisation_id, description, solde_avant, solde_apres
      )
      SELECT $1, $2, 'depot', $3, $4, $5, $6, $7,
             COALESCE(solde, 0) - $3, COALESCE(solde, 0)
      FROM comptes_virtuels WHERE tontine_id = $1`,
      [
        tontineId, compteVirtuel.id, aAppliquer, membreId, membreId, prochaine.id,
        `Surplus reporté (période ${derniereDeriode} → ${prochaine.periode_numero}) - ${membreInfo.prenom} ${membreInfo.nom_membre}`
      ]
    );

    surplus -= aAppliquer;
    derniereDeriode = prochaine.periode_numero;
  }

  return surplus;
}

// ── ROUTES SPÉCIFIQUES AVANT /:id ──────────────────────
router.get('/publiques', tontineController.getTontinesPubliques);
router.get('/adhesions/mes-demandes', tontineController.getMesDemandes);

// ── TONTINES STANDARD ──────────────────────────────────
router.get('/', tontineController.getMesTontines);
router.post('/', validateTontine, tontineController.creerTontine);
router.get('/:id', tontineController.getTontine);
router.put('/:id', tontineController.modifierTontine);
router.delete('/:id', tontineController.supprimerTontine);

// ── MEMBRES ────────────────────────────────────────────
router.get('/:id/membres', tontineController.getMembres);
router.post('/:id/membres/inviter', tontineController.inviterMembre);
router.post('/:id/membres/rejoindre', tontineController.rejoindreTontine);
router.delete('/:id/membres/:membreId', tontineController.retirerMembre);

// ── ADHÉSIONS ──────────────────────────────────────────
router.post('/:id/demander-adhesion', tontineController.demanderAdhesion);
router.put('/adhesions/:adhesionId/accepter', tontineController.accepterAdhesion);
router.put('/adhesions/:adhesionId/refuser', tontineController.refuserAdhesion);

// ── COTISATIONS & STATS ────────────────────────────────
router.get('/:id/cotisations', tontineController.getCotisations);
router.get('/:id/statistiques', tontineController.getStatistiques);
router.get('/:id/rapport', tontineController.genererRapport);

// ── EMPRUNTS ───────────────────────────────────────────
router.post('/:id/emprunts', tontineController.demanderEmprunt);
router.put('/:id/emprunts/:empruntId/voter', tontineController.voterEmprunt);
router.post('/:id/emprunts/:empruntId/rembourser', tontineController.rembourserEmprunt);

// ── COMPTE VIRTUEL ─────────────────────────────────────
router.get('/:id/compte-virtuel', tontineController.getCompteVirtuel);
router.post('/:id/compte-virtuel/depot', tontineController.effectuerDepot);
router.post('/:id/compte-virtuel/retrait/initier', tontineController.initierRetrait);
router.post('/:id/compte-virtuel/retrait/:retraitId/voter', tontineController.voterRetrait);
router.get('/:id/compte-virtuel/transactions', tontineController.getTransactions);

// ── DASHBOARD ORGANISATEUR (+ ADMIN) ───────────────────
router.get('/:id/dashboard', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    console.log('DASHBOARD REQUEST - tontineId:', id, 'userId:', userId);

    // FIX: seul responsable_id était vérifié — un admin ne pouvait jamais
    // accéder au dashboard d une tontine dont il n est pas l organisateur.
    const { tontine, autorise } = await verifierAccesOrganisateur(pool, id, userId);
    if (!tontine) return res.status(404).json({ error: 'Tontine non trouvée' });
    if (!autorise) return res.status(403).json({ error: 'Non autorisé' });

    // Membres avec score et jours de retard
    const { rows: membres } = await pool.query(`
      SELECT u.id, u.nom, u.prenom, u.telephone, u.score_fiabilite,
             mt.position_rotation, mt.a_recu, mt.joined_at,
             CASE
               WHEN EXISTS (
                 SELECT 1 FROM cotisations c
                 WHERE c.tontine_id = $1
                 AND c.membre_id = u.id
                 AND c.statut = 'en_retard'
               ) THEN EXTRACT(DAY FROM NOW() - (
                 SELECT MAX(date_echeance) FROM cotisations
                 WHERE tontine_id = $1 AND membre_id = u.id
                 AND statut = 'en_retard'
               ))::int
               ELSE 0
             END as jours_retard,
             COALESCE((
               SELECT COUNT(*) FROM cotisations
               WHERE tontine_id = $1 AND membre_id = u.id
               AND statut = 'paye'
             ), 0) as nb_paiements_ok,
             COALESCE((
               SELECT COUNT(*) FROM cotisations
               WHERE tontine_id = $1 AND membre_id = u.id
               AND statut = 'partiel'
             ), 0) as nb_partiels,
             COALESCE((
               SELECT COUNT(*) FROM cotisations
               WHERE tontine_id = $1 AND membre_id = u.id
               AND statut = 'en_retard'
             ), 0) as nb_retards
      FROM membres_tontine mt
      JOIN utilisateurs u ON u.id = mt.utilisateur_id
      WHERE mt.tontine_id = $1 AND mt.est_actif = true
      ORDER BY mt.position_rotation
    `, [id]);

    // Cotisations période actuelle
    const { rows: cotisations } = await pool.query(`
      SELECT c.*, u.prenom, u.nom, u.telephone
      FROM cotisations c
      JOIN utilisateurs u ON u.id = c.membre_id
      WHERE c.tontine_id = $1
      ORDER BY c.date_echeance DESC
      LIMIT 50
    `, [id]);

    // NOUVEAU: file d action dédiée — paiements soumis, en attente de
    // validation manuelle par l organisateur (distincte de la liste
    // complète ci-dessus, pour que le dashboard mette en avant ce qui
    // demande une action immédiate).
    const { rows: cotisationsAValider } = await pool.query(`
      SELECT c.*, u.prenom, u.nom, u.telephone
      FROM cotisations c
      JOIN utilisateurs u ON u.id = c.membre_id
      WHERE c.tontine_id = $1 AND c.statut = 'en_attente' AND c.montant_propose IS NOT NULL
      ORDER BY c.periode_numero ASC
    `, [id]);

    // Demandes d'adhésion en attente
    const { rows: demandes } = await pool.query(`
      SELECT a.*, u.prenom, u.nom, u.telephone, u.score_fiabilite
      FROM adhesions_tontine a
      JOIN utilisateurs u ON u.id = a.demandeur_id
      WHERE a.tontine_id = $1 AND a.statut = 'en_attente'
      ORDER BY a.created_at DESC
    `, [id]);

    // NOUVEAU: prochain bénéficiaire de la rotation (premier membre actif,
    // par ordre de position_rotation, qui n a pas encore reçu la cagnotte).
    const { rows: [prochainBeneficiaire] } = await pool.query(`
      SELECT u.id, u.prenom, u.nom, u.telephone, mt.position_rotation
      FROM membres_tontine mt
      JOIN utilisateurs u ON u.id = mt.utilisateur_id
      WHERE mt.tontine_id = $1 AND mt.est_actif = true AND mt.a_recu = false
      ORDER BY mt.position_rotation ASC
      LIMIT 1
    `, [id]);

    // Statistiques globales
    const { rows: [stats] } = await pool.query(`
      SELECT
        COUNT(*) FILTER (WHERE statut = 'paye') as total_payes,
        COUNT(*) FILTER (WHERE statut = 'partiel') as total_partiels,
        COUNT(*) FILTER (WHERE statut = 'en_retard') as total_retards,
        COUNT(*) FILTER (WHERE statut = 'en_attente') as total_attente,
        COALESCE(SUM(montant_paye) FILTER (WHERE statut IN ('paye', 'partiel')), 0) as montant_collecte,
        COUNT(*) as total_cotisations
      FROM cotisations
      WHERE tontine_id = $1
    `, [id]);

    // Solde compte virtuel
    const { rows: [compte] } = await pool.query(
      'SELECT solde, total_depots, total_retraits FROM comptes_virtuels WHERE tontine_id = $1',
      [id]
    );

    // Activité récente (dernières 10 actions réelles)
    const { rows: activite } = await pool.query(`
      SELECT tv.*, u.prenom, u.nom,
             'transaction' as type_action
      FROM transactions_virtuelles tv
      LEFT JOIN utilisateurs u ON u.id = tv.membre_id
      WHERE tv.tontine_id = $1
      ORDER BY tv.created_at DESC
      LIMIT 10
    `, [id]);

    res.json({
      tontine,
      membres,
      cotisations,
      cotisationsAValider,
      demandes,
      prochainBeneficiaire: prochainBeneficiaire || null,
      stats: {
        ...stats,
        solde: compte?.solde || 0,
        totalDepots: compte?.total_depots || 0,
        totalRetraits: compte?.total_retraits || 0,
        taux_paiement: stats.total_cotisations > 0
          ? Math.round((stats.total_payes / stats.total_cotisations) * 100)
          : 0,
      },
      // NOUVEAU: résumé en un coup d œil des éléments demandant une action.
      alertes: {
        membresEnRetard: membres.filter(m => m.jours_retard > 0).length,
        demandesAdhesionEnAttente: demandes.length,
        paiementsAValider: cotisationsAValider.length,
      },
      activite,
      derniere_mise_a_jour: new Date().toISOString(),
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// ── ACTIONS ORGANISATEUR (+ ADMIN) ─────────────────────

// Relancer un membre
router.post('/:id/membres/:membreId/relancer', async (req, res) => {
  try {
    const { id, membreId } = req.params;
    const userId = req.user.id;

    const { tontine, autorise } = await verifierAccesOrganisateur(pool, id, userId);
    if (!tontine) return res.status(404).json({ error: 'Tontine non trouvée' });
    if (!autorise) return res.status(403).json({ error: 'Non autorisé' });

    await pool.query(`
      INSERT INTO notifications (utilisateur_id, tontine_id, type, titre, message, canal)
      VALUES ($1, $2, 'rappel_cotisation',
              'Rappel de cotisation',
              'L''organisateur vous rappelle de payer votre cotisation pour la tontine ' || $3,
              'push')
    `, [membreId, id, tontine.nom]);

    res.json({ success: true, message: 'Rappel envoyé' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Exclure un membre
router.delete('/:id/membres/:membreId/exclure', async (req, res) => {
  try {
    const { id, membreId } = req.params;
    const userId = req.user.id;

    const { tontine, autorise } = await verifierAccesOrganisateur(pool, id, userId);
    if (!tontine) return res.status(404).json({ error: 'Tontine non trouvée' });
    if (!autorise) return res.status(403).json({ error: 'Non autorisé' });

    await pool.query(
      'UPDATE membres_tontine SET est_actif = false WHERE tontine_id = $1 AND utilisateur_id = $2',
      [id, membreId]
    );

    await pool.query(`
      INSERT INTO notifications (utilisateur_id, tontine_id, type, titre, message, canal)
      VALUES ($1, $2, 'exclusion',
              'Exclusion de tontine',
              'Vous avez été exclu de la tontine ' || $3,
              'push')
    `, [membreId, id, tontine.nom]);

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Valider paiement manuel
router.post('/:id/cotisations/:cotisationId/valider', async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { id, cotisationId } = req.params;
    const userId = req.user.id;

    const { tontine, autorise } = await verifierAccesOrganisateur(client, id, userId);
    if (!tontine) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Tontine non trouvée' });
    }
    if (!autorise) {
      await client.query('ROLLBACK');
      return res.status(403).json({ error: 'Non autorisé' });
    }

    const { rows: [cot] } = await client.query(
      `SELECT c.*, t.nom as tontine_nom, u.prenom, u.nom as nom_membre
       FROM cotisations c
       JOIN tontines t ON t.id = c.tontine_id
       JOIN utilisateurs u ON u.id = c.membre_id
       WHERE c.id = $1 AND c.tontine_id = $2`,
      [cotisationId, id]
    );

    if (!cot) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Cotisation non trouvée' });
    }
    if (cot.statut !== 'en_attente' || cot.montant_propose === null) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Cette cotisation ne peut pas être validée (aucun paiement en attente)' });
    }

    const montantDu = parseFloat(cot.montant);
    const dejaPaye = parseFloat(cot.montant_paye) || 0;
    const propose = parseFloat(cot.montant_propose);
    const cumul = dejaPaye + propose;
    const nouveauStatut = cumul >= montantDu ? 'paye' : 'partiel';
    const montantApplique = Math.min(cumul, montantDu);
    const montantAAppliquerMaintenant = montantApplique - dejaPaye;
    const surplus = Math.max(0, cumul - montantDu);

    await client.query(
      `UPDATE cotisations SET statut = $1, montant_paye = $2, montant_propose = NULL,
       date_paiement = CASE WHEN $1 = 'paye' THEN NOW() ELSE date_paiement END,
       valide_par = $3, date_validation = NOW(), methode_paiement = 'manuel_valide'
       WHERE id = $4`,
      [nouveauStatut, montantApplique, userId, cotisationId]
    );

    const { rows: [compteVirtuel] } = await client.query(
      `INSERT INTO comptes_virtuels (tontine_id, solde, total_depots)
       VALUES ($1, $2, $2)
       ON CONFLICT (tontine_id)
       DO UPDATE SET solde = comptes_virtuels.solde + $2,
                     total_depots = COALESCE(comptes_virtuels.total_depots, 0) + $2,
                     updated_at = NOW()
       RETURNING id`,
      [id, montantAAppliquerMaintenant]
    );

    await client.query(
      `INSERT INTO transactions_virtuelles (
        tontine_id, compte_virtuel_id, type, montant, membre_id, utilisateur_id,
        cotisation_id, description
      ) VALUES ($1, $2, 'depot', $3, $4, $5, $6, $7)`,
      [id, compteVirtuel.id, montantAAppliquerMaintenant, cot.membre_id, cot.membre_id, cotisationId,
       `Cotisation validée manuellement (dashboard) - ${cot.prenom} ${cot.nom_membre}` +
         (nouveauStatut === 'partiel' ? ' (partiel)' : '')]
    );

    await client.query(
      `UPDATE utilisateurs SET score_fiabilite = LEAST(100, score_fiabilite + 2)
       WHERE id = $1`,
      [cot.membre_id]
    );

    let surplusNonAffecte = 0;
    if (surplus > 0) {
      surplusNonAffecte = await appliquerSurplus(
        client, id, cot.membre_id,
        { prenom: cot.prenom, nom_membre: cot.nom_membre },
        surplus, cot.periode_numero
      );
    }

    const montantRestant = Math.max(0, montantDu - montantApplique);
    const messageMembre = nouveauStatut === 'paye'
      ? `✅ Votre cotisation de ${montantApplique} F a été validée pour "${cot.tontine_nom}"` +
        (surplus > 0 ? ` (surplus de ${surplus} F reporté sur la prochaine échéance)` : '')
      : `✅ Paiement partiel de ${propose} F validé pour "${cot.tontine_nom}". Reste à payer: ${montantRestant} F`;

    await client.query(
      `INSERT INTO notifications (utilisateur_id, tontine_id, type, titre, message, canal)
       VALUES ($1, $2, 'cotisation', 'Cotisation validée', $3, 'push')`,
      [cot.membre_id, id, messageMembre]
    );

    await client.query('COMMIT');

    res.json({
      success: true,
      message: messageMembre,
      statut: nouveauStatut,
      montantRestant,
      surplus,
      surplusNonAffecte,
    });
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(500).json({ error: err.message });
  } finally {
    client.release();
  }
});

// Demandes adhésion d'une tontine
router.get('/:id/demandes', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const { tontine, autorise } = await verifierAccesOrganisateur(pool, id, userId);
    if (!tontine) return res.status(404).json({ error: 'Tontine non trouvée' });
    if (!autorise) return res.status(403).json({ error: 'Non autorisé' });

    const { rows } = await pool.query(`
      SELECT a.*, u.prenom, u.nom, u.telephone, u.score_fiabilite
      FROM adhesions_tontine a
      JOIN utilisateurs u ON u.id = a.demandeur_id
      WHERE a.tontine_id = $1 AND a.statut = 'en_attente'
      ORDER BY a.created_at DESC
    `, [id]);

    res.json({ demandes: rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;