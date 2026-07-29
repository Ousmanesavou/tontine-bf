const express = require('express');
const router = express.Router();
const { pool } = require('../../config/database');
const { authenticate } = require('../middleware/auth');
const notificationService = require('../services/notificationService');
const logger = require('../utils/logger');

router.use(authenticate);

// ── DEMANDER À DEVENIR COMMERÇANT ──────────────────────
router.post('/demander', async (req, res) => {
  try {
    const userId = req.user.id;
    const { nom, proprietaire, telephone, email, categorie, pays, adresse, description, livraison_disponible } = req.body;

    if (!nom) return res.status(400).json({ error: 'Le nom de l\'entreprise est requis' });

    const { rows: existant } = await pool.query(
      `SELECT id, statut FROM commercants WHERE utilisateur_id = $1 ORDER BY created_at DESC LIMIT 1`,
      [userId]
    );
    if (existant[0] && ['en_attente', 'valide'].includes(existant[0].statut)) {
      return res.status(400).json({
        error: existant[0].statut === 'valide'
          ? 'Vous êtes déjà commerçant validé'
          : 'Une demande est déjà en attente de traitement'
      });
    }

    // FIX SÉCURITÉ: statut/est_verifie jamais pris depuis le corps de la
    // requête — toujours forcés côté serveur, pour empêcher un utilisateur
    // de s'auto-valider commerçant.
    const { rows } = await pool.query(`
      INSERT INTO commercants
        (nom, proprietaire, telephone, email, categorie, pays, adresse, description,
         livraison_disponible, est_verifie, statut, utilisateur_id)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,false,'en_attente',$10)
      RETURNING *
    `, [nom, proprietaire || null, telephone || null, email || null, categorie || null,
        pays || 'BF', adresse || null, description || null,
        livraison_disponible || false, userId]);

    await notificationService.notifierTousLesAdmins({
      type: 'demande_adhesion',
      nom_acteur: `${req.user.prenom} ${req.user.nom}`,
      nom_tontine: `commerçant "${nom}"`,
    });

    res.status(201).json({ success: true, message: 'Demande envoyée, en attente de validation', data: rows[0] });
  } catch (err) {
    logger.error('Erreur demande commerçant:', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ── MON STATUT COMMERÇANT ──────────────────────────────
router.get('/mon-statut', async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT * FROM commercants WHERE utilisateur_id = $1 ORDER BY created_at DESC LIMIT 1`,
      [req.user.id]
    );
    res.json({ success: true, data: rows[0] || null });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

async function getCommercantValide(userId) {
  const { rows } = await pool.query(
    `SELECT id FROM commercants WHERE utilisateur_id = $1 AND statut = 'valide'`,
    [userId]
  );
  return rows[0]?.id || null;
}

// ── MES PRODUITS (commerçant validé uniquement) ────────
router.get('/mes-produits', async (req, res) => {
  try {
    const commercantId = await getCommercantValide(req.user.id);
    if (!commercantId) return res.status(403).json({ error: 'Vous n\'êtes pas encore un commerçant validé' });

    const { rows } = await pool.query(
      `SELECT * FROM catalogue_produits WHERE commercant_id = $1 ORDER BY created_at DESC`,
      [commercantId]
    );
    res.json({ success: true, data: rows });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

router.post('/mes-produits', async (req, res) => {
  try {
    const commercantId = await getCommercantValide(req.user.id);
    if (!commercantId) return res.status(403).json({ error: 'Vous n\'êtes pas encore un commerçant validé' });

    const { nom, categorie, description, prix, livraison_disponible, emoji, medias } = req.body;
    if (!nom || !categorie || !prix) {
      return res.status(400).json({ error: 'Nom, catégorie et prix sont requis' });
    }

    const { rows: [commercant] } = await pool.query(
      `SELECT nom, telephone FROM commercants WHERE id = $1`, [commercantId]
    );

    const mediasArray = Array.isArray(medias) ? medias : [];

    // FIX SÉCURITÉ: statut toujours forcé à 'en_attente' ici, jamais pris
    // du corps de la requête — un produit commerçant doit systématiquement
    // passer par une validation admin avant d'être visible publiquement.
    const { rows } = await pool.query(`
      INSERT INTO catalogue_produits
        (nom, categorie, description, prix, fournisseur_nom, fournisseur_contact,
         livraison_disponible, photos, emoji, commercant_id, statut)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,'en_attente')
      RETURNING *
    `, [nom, categorie, description || null, prix, commercant.nom, commercant.telephone,
        livraison_disponible || false, JSON.stringify(mediasArray), emoji || '📦', commercantId]);

    await notificationService.notifierTousLesAdmins({
      type: 'demande_adhesion',
      nom_acteur: commercant.nom,
      nom_tontine: `produit "${nom}" à valider`,
    });

    res.status(201).json({ success: true, message: 'Produit soumis, en attente de validation admin', data: rows[0] });
  } catch (err) {
    logger.error('Erreur ajout produit commerçant:', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

router.put('/mes-produits/:id', async (req, res) => {
  try {
    const commercantId = await getCommercantValide(req.user.id);
    if (!commercantId) return res.status(403).json({ error: 'Vous n\'êtes pas encore un commerçant validé' });

    const { rows: [produit] } = await pool.query(
      `SELECT id FROM catalogue_produits WHERE id = $1 AND commercant_id = $2`,
      [req.params.id, commercantId]
    );
    if (!produit) return res.status(404).json({ error: 'Produit non trouvé ou non autorisé' });

    const { nom, categorie, description, prix, livraison_disponible, emoji, est_actif } = req.body;
    const { rows } = await pool.query(`
      UPDATE catalogue_produits SET
        nom=COALESCE($1,nom), categorie=COALESCE($2,categorie),
        description=COALESCE($3,description), prix=COALESCE($4,prix),
        livraison_disponible=COALESCE($5,livraison_disponible),
        emoji=COALESCE($6,emoji), est_actif=COALESCE($7,est_actif)
      WHERE id=$8 RETURNING *
    `, [nom, categorie, description, prix, livraison_disponible, emoji, est_actif, req.params.id]);

    res.json({ success: true, data: rows[0] });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

router.delete('/mes-produits/:id', async (req, res) => {
  try {
    const commercantId = await getCommercantValide(req.user.id);
    if (!commercantId) return res.status(403).json({ error: 'Vous n\'êtes pas encore un commerçant validé' });

    const { rowCount } = await pool.query(
      `UPDATE catalogue_produits SET est_actif=false WHERE id=$1 AND commercant_id=$2`,
      [req.params.id, commercantId]
    );
    if (rowCount === 0) return res.status(404).json({ error: 'Produit non trouvé ou non autorisé' });

    res.json({ success: true, message: 'Produit désactivé' });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;