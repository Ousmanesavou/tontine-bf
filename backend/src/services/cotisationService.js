/**
 * Applique un surplus (trop-perçu sur une période) aux périodes suivantes
 * du même membre, dans l'ordre chronologique, jusqu'à épuisement du
 * surplus ou absence de période éligible restante.
 *
 * CONSOLIDÉ: cette fonction existait à l'identique dans tontineController.js,
 * routes/paiements.js et routes/tontines.js — un correctif dans l'une ne se
 * propageait jamais aux deux autres. Un seul endroit désormais.
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
      SELECT $1, $2, 'depot', $3, $4, $4, $5, $6,
             COALESCE(solde, 0) - $3, COALESCE(solde, 0)
      FROM comptes_virtuels WHERE tontine_id = $1`,
      [
        tontineId, compteVirtuel.id, aAppliquer, membreId, prochaine.id,
        `Surplus reporté (période ${derniereDeriode} → ${prochaine.periode_numero}) - ${membreInfo.prenom} ${membreInfo.nom_membre}`
      ]
    );

    surplus -= aAppliquer;
    derniereDeriode = prochaine.periode_numero;
  }

  return surplus;
}

module.exports = { appliquerSurplus };