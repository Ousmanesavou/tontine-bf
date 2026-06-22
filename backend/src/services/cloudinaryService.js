const cloudinary = require('cloudinary').v2;
const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Storage pour photos de profil
const storageProfilPhoto = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: 'tontine-bf/profils',
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
    transformation: [{ width: 400, height: 400, crop: 'fill', gravity: 'face' }],
  },
});

// Storage pour photos de tontine
const storageTontinePhoto = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: 'tontine-bf/tontines',
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
    transformation: [{ width: 800, height: 600, crop: 'fill' }],
  },
});

// Storage pour vidéos de tontine
const storageTontineVideo = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: 'tontine-bf/videos',
    resource_type: 'video',
    allowed_formats: ['mp4', 'mov', 'avi', 'webm'],
    transformation: [{ width: 720, height: 480, crop: 'limit' }],
  },
});

// Storage pour catalogue produits
const storageCatalogue = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: 'tontine-bf/catalogue',
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
    transformation: [{ width: 600, height: 600, crop: 'fill' }],
  },
});

const uploadProfilPhoto = multer({
  storage: storageProfilPhoto,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
});

const uploadTontinePhoto = multer({
  storage: storageTontinePhoto,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
});

const uploadTontineVideo = multer({
  storage: storageTontineVideo,
  limits: { fileSize: 100 * 1024 * 1024 }, // 100MB
});

const uploadCatalogue = multer({
  storage: storageCatalogue,
  limits: { fileSize: 5 * 1024 * 1024 },
});

// Upload multiple (photo + vidéo en même temps)
const uploadMultiple = multer({
  storage: storageTontinePhoto,
  limits: { fileSize: 100 * 1024 * 1024 },
}).fields([
  { name: 'photo', maxCount: 5 },
  { name: 'video', maxCount: 1 },
]);

async function supprimerFichier(publicId) {
  try {
    await cloudinary.uploader.destroy(publicId);
  } catch (err) {
    console.error('Erreur suppression Cloudinary:', err);
  }
}

async function uploadBase64(base64Data, dossier = 'tontine-bf/divers') {
  try {
    const result = await cloudinary.uploader.upload(base64Data, {
      folder: dossier,
      resource_type: 'auto',
    });
    return result.secure_url;
  } catch (err) {
    console.error('Erreur upload base64:', err);
    throw err;
  }
}

module.exports = {
  cloudinary,
  uploadProfilPhoto,
  uploadTontinePhoto,
  uploadTontineVideo,
  uploadCatalogue,
  uploadMultiple,
  supprimerFichier,
  uploadBase64,
};