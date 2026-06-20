const Joi = require('joi');

function validate(schema) {
  return (req, res, next) => {
    const { error } = schema.validate(req.body, { abortEarly: false });
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
  telephone: Joi.string().required()
    .messages({ 'string.pattern.base': 'Numéro de téléphone Burkina Faso invalide' }),
  code_pin: Joi.string().length(4).pattern(/^\d+$/).required()
    .messages({ 'string.length': 'Le code PIN doit avoir 4 chiffres' }),
  langue: Joi.string().valid('fr', 'moore', 'dioula').default('fr'),
  type_acces: Joi.string().valid('smartphone', 'basic').default('smartphone'),
  orange_money_numero: Joi.string().optional(),
  moov_money_numero: Joi.string().optional()
}));

const validateConnexion = validate(Joi.object({
  telephone: Joi.string().required(),
  code_pin: Joi.string().length(4).required()
}));

const validateTontine = validate(Joi.object({
  nom: Joi.string().min(3).max(200).required(),
  type: Joi.string().valid('argent_liquide', 'objet', 'caisse_fixe', 'evenementielle').required(),
  description: Joi.string().max(500).optional(),
  montant_cotisation: Joi.number().positive().required(),
  periodicite: Joi.string().valid('quotidien', '2_jours', 'hebdomadaire', '2_semaines', 'mensuel', 'personnalise').required(),
  periodicite_jours: Joi.number().integer().min(1).max(90).default(1),
  nombre_membres: Joi.number().integer().min(2).max(100).required(),
  date_debut: Joi.date().min('now').required(),
  ordre_rotation: Joi.string().valid('tirage_sort', 'manuel', 'besoin').default('tirage_sort'),
  produit_catalogue_id: Joi.string().uuid().optional()
}));

const validateCotisation = validate(Joi.object({
  cotisation_id: Joi.string().uuid().required(),
  methode_paiement: Joi.string().valid('orange_money', 'moov_money', 'depot_physique').required(),
  telephone_paiement: Joi.string().optional()
}));

module.exports = { validateInscription, validateConnexion, validateTontine, validateCotisation };
