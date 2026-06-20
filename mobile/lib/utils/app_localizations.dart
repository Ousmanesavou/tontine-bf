import 'package:flutter/material.dart';

class AppLocalizations {
  final String locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations('fr');
  }

  static const localizationsDelegates = <LocalizationsDelegate>[
    _AppLocalizationsDelegate(),
    DefaultMaterialLocalizations.delegate,
    DefaultWidgetsLocalizations.delegate,
  ];

  static const Map<String, Map<String, String>> _translations = {
    'fr': {
      'app_name': 'Tontine BF',
      'bienvenue': 'Bienvenue',
      'bonjour': 'Bonjour',
      'choisir_langue': 'Choisissez votre langue',
      'continuer': 'Continuer',
      'connexion': 'Connexion',
      'inscription': 'S\'inscrire',
      'telephone': 'Numéro de téléphone',
      'code_pin': 'Code PIN (4 chiffres)',
      'nom': 'Nom',
      'prenom': 'Prénom',
      'mes_tontines': 'Mes tontines',
      'creer_tontine': 'Créer une tontine',
      'catalogue': 'Catalogue',
      'alertes': 'Alertes',
      'profil': 'Profil',
      'payer': 'Payer',
      'confirmer': 'Confirmer',
      'annuler': 'Annuler',
      'cotisation': 'Cotisation',
      'mon_tour': 'Mon tour',
      'membres': 'Membres',
      'jours_restants': 'jours restants',
      'paiement_reussi': 'Paiement réussi !',
      'aide_vocale': 'Aide vocale',
      'orange_money': 'Orange Money',
      'moov_money': 'Moov Money',
      'depot_physique': 'Dépôt physique',
      'type_tontine': 'Type de tontine',
      'argent_liquide': 'Argent liquide',
      'objet_bien': 'Objet / Bien',
      'periodicite': 'Périodicité',
      'quotidien': 'Quotidien',
      'hebdomadaire': 'Hebdomadaire',
      'mensuel': 'Mensuel',
      'nombre_membres': 'Nombre de membres',
      'date_debut': 'Date de début',
      'inviter_membre': 'Inviter un membre',
      'rapport': 'Rapport',
      'statistiques': 'Statistiques',
      'score_fiabilite': 'Score de fiabilité',
      'retard': 'En retard',
      'paye': 'Payé',
      'en_attente': 'En attente',
      'erreur_connexion': 'Erreur de connexion',
      'reessayer': 'Réessayer',
      'chargement': 'Chargement...',
      'aucune_tontine': 'Pas encore de tontine',
      'creer_premiere': 'Créez votre première tontine !',
    },
    'moore': {
      'app_name': 'Tontine BF',
      'bienvenue': 'Aw laafi',
      'bonjour': 'Aw laafi',
      'choisir_langue': 'Paam n\' bʋʋd',
      'continuer': 'Tɩ kẽng',
      'connexion': 'Kẽng',
      'inscription': 'Sɩng',
      'telephone': 'Tẽlefonn nimero',
      'code_pin': 'PIN kood (4 yĩnga)',
      'nom': 'Yĩnga',
      'prenom': 'Yĩng-pɛlg',
      'mes_tontines': 'M tontines',
      'creer_tontine': 'Tontine sɩng',
      'catalogue': 'Bõn-yõodo',
      'alertes': 'Sõsg',
      'profil': 'Mam',
      'payer': 'Laf',
      'confirmer': 'Sɩd',
      'annuler': 'Bas',
      'cotisation': 'Cotisation',
      'mon_tour': 'M yɩɩr',
      'membres': 'Neb',
      'jours_restants': 'dɛgr',
      'paiement_reussi': 'Paiement sɩda !',
      'aide_vocale': 'Sõsg',
      'orange_money': 'Orange Money',
      'moov_money': 'Moov Money',
      'depot_physique': 'Laf tʋʋm',
      'type_tontine': 'Tontine yelle',
      'argent_liquide': 'Ligdi',
      'objet_bien': 'Bõn-yõodo',
      'periodicite': 'Doge',
      'quotidien': 'Dẽenga',
      'hebdomadaire': 'Dɩ pʋgẽ',
      'mensuel': 'Kiuugu pʋgẽ',
      'nombre_membres': 'Neb yĩnga',
      'date_debut': 'Sɩng doge',
      'inviter_membre': 'Ned bool',
      'rapport': 'Raporr',
      'statistiques': 'Tõodo',
      'score_fiabilite': 'Tɩɩ score',
      'retard': 'Pɩng',
      'paye': 'Lafame',
      'en_attente': 'Mik',
      'erreur_connexion': 'Yoodo ka sɩd ye',
      'reessayer': 'Lɛɛg',
      'chargement': 'Mik...',
      'aucune_tontine': 'Tontine ka be ye',
      'creer_premiere': 'F yɩɩr tontine sɩng !',
    },
    'dioula': {
      'app_name': 'Tontine BF',
      'bienvenue': 'I bisimila',
      'bonjour': 'I ni sogoma',
      'choisir_langue': 'Kan dɔ sugandi',
      'continuer': 'Taa ɲɔgɔn fɛ',
      'connexion': 'Sɔrɔ',
      'inscription': 'Sɛbɛn',
      'telephone': 'Telefɔni nimɔrɔ',
      'code_pin': 'PIN kodi (4 hakɛ)',
      'nom': 'Tɔgɔ',
      'prenom': 'Tɔgɔ fɔlɔ',
      'mes_tontines': 'N tontines',
      'creer_tontine': 'Tontine dɔ daminɛ',
      'catalogue': 'Fɛnw',
      'alertes': 'Kunnafoni',
      'profil': 'N yɛrɛ',
      'payer': 'Sara',
      'confirmer': 'Sɛbɛn',
      'annuler': 'Bali',
      'cotisation': 'Musaka',
      'mon_tour': 'N sira',
      'membres': 'Mɔgɔw',
      'jours_restants': 'tile tɔ',
      'paiement_reussi': 'Sarali bɛn !',
      'aide_vocale': 'Dɛmɛ',
      'orange_money': 'Orange Money',
      'moov_money': 'Moov Money',
      'depot_physique': 'Sara ni bolo',
      'type_tontine': 'Tontine sugandi',
      'argent_liquide': 'Wari',
      'objet_bien': 'Fɛn',
      'periodicite': 'Lɛ',
      'quotidien': 'Tile o tile',
      'hebdomadaire': 'Dɔn kelen',
      'mensuel': 'Kalo kelen',
      'nombre_membres': 'Mɔgɔ hakɛ',
      'date_debut': 'Daminɛ lɛ',
      'inviter_membre': 'Mɔgɔ wele',
      'rapport': 'Rapɔri',
      'statistiques': 'Kunnafoni',
      'score_fiabilite': 'Danbe score',
      'retard': 'Lɔgɔma',
      'paye': 'Sarala',
      'en_attente': 'Mɛnni',
      'erreur_connexion': 'Sɔrɔli tɛ se',
      'reessayer': 'Lajɛ',
      'chargement': 'Mɛnni...',
      'aucune_tontine': 'Tontine tɛ yen',
      'creer_premiere': 'I ka tontine fɔlɔ daminɛ !',
    },
  };

  String t(String key) {
    return _translations[locale]?[key] ??
        _translations['fr']?[key] ??
        key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['fr', 'mo', 'dyu'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale.languageCode);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
