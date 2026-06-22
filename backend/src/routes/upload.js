const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const {
  uploadProfilPhoto,
  uploadTontinePhoto,
  uploadTontineVideo,
  uploadMultiple,
  uploadCatalogue,
} = require('../services/cloudinaryService');
const { pool } = require('../../config/database');
const logger = require('../utils/logger');

router.use(authenticate);

// Upload photo de profil
router.post('/profil', uploadProfilPhoto.single('photo'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'Aucune photo reçue' });

    const url = req.file.path;
    await pool.query(
      'UPDATE utilisateurs SET photo_profil = $1, updated_at = NOW() WHERE id = $2',
      [url, req.user.id]
    );

    res.json({ success: true, url, message: 'Photo de profil mise à jour' });
  } catch (err) {
    logger.error('Erreur upload profil:', err);
    res.status(500).json({ error: 'Erreur upload' });
  }
});

// Upload photo de tontine
router.post('/tontine/:id/photo', uploadTontinePhoto.single('photo'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'Aucune photo reçue' });

    const url = req.file.path;
    await pool.query(
      'UPDATE tontines SET photo_tontine = $1, updated_at = NOW() WHERE id = $2 AND responsable_id = $3',
      [url, req.params.id, req.user.id]
    );

    res.json({ success: true, url, message: 'Photo tontine mise à jour' });
  } catch (err) {
    logger.error('Erreur upload tontine photo:', err);
    res.status(500).json({ error: 'Erreur upload' });
  }
});

// Upload vidéo de tontine
router.post('/tontine/:id/video', uploadTontineVideo.single('video'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'Aucune vidéo reçue' });

    const url = req.file.path;
    await pool.query(
      'UPDATE tontines SET video_tontine = $1, updated_at = NOW() WHERE id = $2 AND responsable_id = $3',
      [url, req.params.id, req.user.id]
    );

    res.json({ success: true, url, message: 'Vidéo tontine mise à jour' });
  } catch (err) {
    logger.error('Erreur upload tontine video:', err);
    res.status(500).json({ error: 'Erreur upload' });
  }
});

// Upload photo + vidéo en même temps
router.post('/tontine/:id/media', uploadMultiple, async (req, res) => {
  try {
    const updates = [];
    const params = [];

    if (req.files?.photo?.[0]) {
      updates.push(`photo_tontine = $${params.length + 1}`);
      params.push(req.files.photo[0].path);
    }
    if (req.files?.video?.[0]) {
      updates.push(`video_tontine = $${params.length + 1}`);
      params.push(req.files.video[0].path);
    }

    if (updates.length === 0) return res.status(400).json({ error: 'Aucun fichier reçu' });

    params.push(req.params.id, req.user.id);
    await pool.query(
      `UPDATE tontines SET ${updates.join(', ')}, updated_at = NOW()
       WHERE id = $${params.length - 1} AND responsable_id = $${params.length}`,
      params
    );

    res.json({
      success: true,
      photo_url: req.files?.photo?.[0]?.path || null,
      video_url: req.files?.video?.[0]?.path || null,
      message: 'Médias uploadés avec succès',
    });
  } catch (err) {
    logger.error('Erreur upload media:', err);
    res.status(500).json({ error: 'Erreur upload' });
  }
});

// Upload photo catalogue (admin)
router.post('/catalogue/:id/photo', uploadCatalogue.single('photo'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'Aucune photo reçue' });

    const url = req.file.path;
    const { rows } = await pool.query(
      'SELECT photos FROM catalogue_produits WHERE id = $1', [req.params.id]
    );
    const photos = rows[0]?.photos || [];
    photos.push(url);

    await pool.query(
      'UPDATE catalogue_produits SET photos = $1 WHERE id = $2',
      [JSON.stringify(photos), req.params.id]
    );

    res.json({ success: true, url, photos, message: 'Photo catalogue ajoutée' });
  } catch (err) {
    logger.error('Erreur upload catalogue:', err);
    res.status(500).json({ error: 'Erreur upload' });
  }
});

// Upload base64 (depuis Flutter directement)
router.post('/base64', async (req, res) => {
  try {
    const { data, dossier } = req.body;
    if (!data) return res.status(400).json({ error: 'Données manquantes' });

    const { uploadBase64 } = require('../services/cloudinaryService');
    const url = await uploadBase64(data, `tontine-bf/${dossier || 'divers'}`);

    res.json({ success: true, url });
  } catch (err) {
    logger.error('Erreur upload base64:', err);
    res.status(500).json({ error: 'Erreur upload' });
  }
});

module.exports = router;