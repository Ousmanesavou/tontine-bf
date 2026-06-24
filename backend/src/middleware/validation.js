const Joi = require('joi');

function validate(schema) {
  return (req, res, next) => {
    const { error } = schema.validate(req.body, { abortEarly: false, allowUnknown: true });
    if (error) {
      return res.status(400).json({
        error: 'Données invalides',
        details: error.details.map(d => d.message)
      });
    }
    next();
  };
}

const validateInscription = validate(Joi.object({
  nom: Joi.string().min(2).max(100).required(),
  prenom: Joi.string().min(2).max(100).required(),
  telephone: Joi.string().min(6).max(20).required(),
  code_pin: Joi.string().length(4).pattern(/^\d+$/).required()
    .messages({ 'string.length': 'Le code PIN doit avoir 4 chiffres' }),
  langue: Joi.string().optional().default('fr'),
  type_acces: Joi.string().valid('smartphone', 'basic').default('smartphone'),
  pays: Joi.string().optional().default('BF'),
  indicatif: Joi.string().optional().allow('', null),
  orange_money_numero: Joi.string().optional().allow('', null),
  moov_money_numero: Joi.string().optional().allow('', null),
  photo_profil: Joi.string().optional().allow('', null),
}));

const validateConnexion = validate(Joi.object({
  telephone: Joi.string().min(6).max(20).required(),
  code_pin: Joi.string().min(4).max(6).required(),
}));

const validateTontine = validate(Joi.object({
  nom: Joi.string().min(3).max(200).required(),
  type: Joi.string().required(),
  description: Joi.string().max(1000).optional().allow('', null),
  montant_cotisation: Joi.number().positive().required(),
  periodicite: Joi.string().required(),
  periodicite_jours: Joi.number().integer().min(1).max(3650).default(1),
  nombre_membres: Joi.number().integer().min(2).max(500).required(),
  date_debut: Joi.alternatives().try(
    Joi.date(),
    Joi.string()
  ).required(),
  date_fin: Joi.alternatives().try(
    Joi.date(),
    Joi.string()
  ).optional().allow('', null),
  ordre_rotation: Joi.string().optional().default('tirage_sort'),
  produit_catalogue_id: Joi.string().uuid().optional().allow('', null),
  photo_tontine: Joi.string().optional().allow('', null),
  video_tontine: Joi.string().optional().allow('', null),
  devise: Joi.string().optional().default('XOF'),
  pays: Joi.string().optional().default('BF'),
  est_publique: Joi.boolean().optional().default(false),
  est_public: Joi.boolean().optional().default(false),
  orange_money_numero: Joi.string().optional().allow('', null),
  moov_money_numero: Joi.string().optional().allow('', null),
  mtn_numero: Joi.string().optional().allow('', null),
  wave_numero: Joi.string().optional().allow('', null),
}));

const validateCotisation = validate(Joi.object({
  cotisation_id: Joi.string().uuid().required(),
  methode_paiement: Joi.string().required(),
  telephone_paiement: Joi.string().optional().allow('', null),
}));

const validateInvitation = validate(Joi.object({
  telephone: Joi.string().min(6).max(20).required(),
  message: Joi.string().optional().allow('', null),
}));

const validateProfil = validate(Joi.object({
  nom: Joi.string().min(2).max(100).optional(),
  prenom: Joi.string().min(2).max(100).optional(),
  langue: Joi.string().optional(),
  pays: Joi.string().optional(),
  photo_profil: Joi.string().optional().allow('', null),
  photo_url: Joi.string().optional().allow('', null),
  orange_money_numero: Joi.string().optional().allow('', null),
  moov_money_numero: Joi.string().optional().allow('', null),
}));

module.exports = {
  validateInscription,
  validateConnexion,
  validateTontine,
  validateCotisation,
  validateInvitation,
  validateProfil,
};