import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/vocal_service.dart';
import '../../widgets/media_picker_widget.dart';
import '../../main.dart';

// ── TRADUCTIONS ───────────────────────────────────────
const Map<String, Map<String, String>> _tr = {
  'fr': {
    'titre': 'Nouvelle tontine',
    'nom': 'Nom de la tontine',
    'nom_hint': 'Ex: Tontine des amis du quartier',
    'type': 'Type de tontine',
    'montant': 'Montant total',
    'montant_hint': 'Ex: 150000',
    'membres': 'Nombre de membres',
    'membres_hint': 'Ex: 10',
    'periodicite': 'Périodicité des cotisations',
    'date_debut': 'Date de début',
    'date_fin': 'Date de fin (optionnel)',
    'description': 'Description (optionnel)',
    'description_hint': 'Décrivez votre tontine...',
    'media': 'Image ou vidéo (optionnel)',
    'recap': 'Récapitulatif',
    'cotisation_membre': 'Cotisation / membre',
    'duree': 'Durée totale',
    'jours': 'jours',
    'tours': 'tours',
    'creer': 'Créer la tontine',
    'succes': 'Tontine créée avec succès !',
    'requis': 'Requis',
    'montant_invalide': 'Montant invalide',
    'min_membres': 'Minimum 2 membres',
    'vocal': 'Remplissez le nom, le type, le montant, le nombre de membres et la périodicité.',
    'quotidien': 'Chaque jour',
    '2_jours': 'Tous les 2 jours',
    'hebdomadaire': 'Chaque semaine',
    '2_semaines': 'Toutes les 2 semaines',
    'mensuel': 'Chaque mois',
    'trimestriel': 'Tous les 3 mois',
    'argent_liquide': 'Argent liquide',
    'argent_liquide_desc': 'Chaque membre reçoit la cagnotte à son tour',
    'objet': 'Objet / Bien',
    'objet_desc': 'Choisissez un objet dans le catalogue',
    'caisse_fixe': 'Caisse commune',
    'caisse_fixe_desc': 'Épargne collective avec emprunts possibles',
    'evenementielle': 'Événement',
    'evenementielle_desc': 'Mariage, baptême, funérailles',
    'sante': 'Santé',
    'sante_desc': 'Fonds d\'urgence médicale pour le groupe',
    'education': 'Éducation',
    'education_desc': 'Scolarité et fournitures scolaires',
    'agriculture': 'Agriculture',
    'agriculture_desc': 'Semences, engrais, équipements agricoles',
    'construction': 'Construction',
    'construction_desc': 'Matériaux de construction et rénovation',
    'voyage': 'Voyage',
    'voyage_desc': 'Transport et déplacements',
    'commerce': 'Commerce',
    'commerce_desc': 'Fonds de roulement pour petits commerces',
  },
  'en': {
    'titre': 'New tontine',
    'nom': 'Tontine name',
    'nom_hint': 'Ex: Friends savings group',
    'type': 'Tontine type',
    'montant': 'Total amount',
    'montant_hint': 'Ex: 150000',
    'membres': 'Number of members',
    'membres_hint': 'Ex: 10',
    'periodicite': 'Contribution frequency',
    'date_debut': 'Start date',
    'date_fin': 'End date (optional)',
    'description': 'Description (optional)',
    'description_hint': 'Describe your tontine...',
    'media': 'Image or video (optional)',
    'recap': 'Summary',
    'cotisation_membre': 'Contribution / member',
    'duree': 'Total duration',
    'jours': 'days',
    'tours': 'rounds',
    'creer': 'Create tontine',
    'succes': 'Tontine created successfully!',
    'requis': 'Required',
    'montant_invalide': 'Invalid amount',
    'min_membres': 'Minimum 2 members',
    'vocal': 'Fill in the name, type, amount, number of members and frequency.',
    'quotidien': 'Every day',
    '2_jours': 'Every 2 days',
    'hebdomadaire': 'Every week',
    '2_semaines': 'Every 2 weeks',
    'mensuel': 'Every month',
    'trimestriel': 'Every 3 months',
    'argent_liquide': 'Cash',
    'argent_liquide_desc': 'Each member receives the pot in turn',
    'objet': 'Object / Item',
    'objet_desc': 'Choose an item from the catalogue',
    'caisse_fixe': 'Common fund',
    'caisse_fixe_desc': 'Collective savings with possible loans',
    'evenementielle': 'Event',
    'evenementielle_desc': 'Wedding, baptism, funeral',
    'sante': 'Health',
    'sante_desc': 'Group medical emergency fund',
    'education': 'Education',
    'education_desc': 'School fees and supplies',
    'agriculture': 'Agriculture',
    'agriculture_desc': 'Seeds, fertilizers, farm equipment',
    'construction': 'Construction',
    'construction_desc': 'Building materials and renovation',
    'voyage': 'Travel',
    'voyage_desc': 'Transport and travel',
    'commerce': 'Commerce',
    'commerce_desc': 'Working capital for small businesses',
  },
  'mos': {
    'titre': 'Tontine paalga',
    'nom': 'Tontine yʋʋre',
    'nom_hint': 'Tõnd tontine',
    'type': 'Tontine bõne',
    'montant': 'Ligdi fãa',
    'montant_hint': '150000',
    'membres': 'Neb sõore',
    'membres_hint': '10',
    'periodicite': 'Kõ-wakatã',
    'date_debut': 'Sɩng-dãmba',
    'date_fin': 'Tɩɩm-dãmba',
    'description': 'Sɩbgrã',
    'description_hint': 'Wilg f tontine...',
    'media': 'Foto wall vide',
    'recap': 'Fãa-wilgr',
    'cotisation_membre': 'Kõ / neb',
    'duree': 'Wakatã fãa',
    'jours': 'dãmba',
    'tours': 'tɩɩse',
    'creer': 'Bʋg tontine',
    'succes': 'Tontine sɩng sɩda !',
    'requis': 'Tõnd',
    'montant_invalide': 'Ligdi ka sɩd ye',
    'min_membres': 'Neb 2 tõnd',
    'vocal': 'Tɩ sɩbg tontine yʋʋre, bõn-yende, ligdi la neb sõore.',
    'quotidien': 'Dũnni fãa',
    '2_jours': 'Dũnni 2',
    'hebdomadaire': 'Wiki fãa',
    '2_semaines': 'Wiki 2',
    'mensuel': 'Kiuugã fãa',
    'trimestriel': 'Kiuugu 3',
    'argent_liquide': 'Ligdi',
    'argent_liquide_desc': 'Ned fãa paamda a ligdi',
    'objet': 'Bũmb',
    'objet_desc': 'Tɩ yãk bũmb katalɔg pʋgẽ',
    'caisse_fixe': 'Caisse',
    'caisse_fixe_desc': 'Ligdi-kũuni la yõk-yõkrã',
    'evenementielle': 'Barka',
    'evenementielle_desc': 'Rog-m-tɩɩg, bapɛɛm, sɩbg',
    'sante': 'Laafɩ',
    'sante_desc': 'Ligdi laafɩ-yõkã yĩnga',
    'education': 'Zãmsg',
    'education_desc': 'Zãmsgã yĩnga',
    'agriculture': 'Tɩɩs',
    'agriculture_desc': 'Bẽedã la tɩɩs-neesr',
    'construction': 'Weoogo',
    'construction_desc': 'Weoogo bõn-dãmba',
    'voyage': 'Viage',
    'voyage_desc': 'Zig-yãkr',
    'commerce': 'Toeega',
    'commerce_desc': 'Ligdi toeeg yĩnga',
  },
  'bm': {
    'titre': 'Tontine kura',
    'nom': 'Tontine tɔgɔ',
    'nom_hint': 'Tontine kura',
    'type': 'Tontine sugandi',
    'montant': 'Wari bɛɛ',
    'montant_hint': '150000',
    'membres': 'Mɔgɔ hakɛ',
    'membres_hint': '10',
    'periodicite': 'Sara waati',
    'date_debut': 'Daminɛ tile',
    'date_fin': 'Laban tile',
    'description': 'Fɔtɔ',
    'description_hint': 'I ka tontine fɔ...',
    'media': 'Foto walima vide',
    'recap': 'Jɛnsɛgɛli',
    'cotisation_membre': 'Sara / mɔgɔ',
    'duree': 'Waati bɛɛ',
    'jours': 'tile',
    'tours': 'yɔrɔw',
    'creer': 'Tontine daminɛ',
    'succes': 'Tontine daminɛna ka kɛ sɛbɛn !',
    'requis': 'Ɲɛnabɔ',
    'montant_invalide': 'Wari tɛ ɲɛ',
    'min_membres': 'Mɔgɔ 2 ɲɛnabɔ',
    'vocal': 'Tontine tɔgɔ, sugandi, wari ni mɔgɔ hakɛ sɛbɛn.',
    'quotidien': 'Tile o tile',
    '2_jours': 'Tile 2 o 2',
    'hebdomadaire': 'Dɔgɔkun kelen',
    '2_semaines': 'Dɔgɔkun fila',
    'mensuel': 'Kalo kelen',
    'trimestriel': 'Kalo saba',
    'argent_liquide': 'Wari',
    'argent_liquide_desc': 'Mɔgɔ o mɔgɔ bɛ wari sɔrɔ',
    'objet': 'Fɛn',
    'objet_desc': 'Fɛn sugandi katalogi la',
    'caisse_fixe': 'Caisse',
    'caisse_fixe_desc': 'Wari mara ni dalaw',
    'evenementielle': 'Fɛsɛn',
    'evenementielle_desc': 'Furuli, batisi, sɔgɔ',
    'sante': 'Kɛnɛya',
    'sante_desc': 'Kɛnɛya nafaw kama',
    'education': 'Kalanso',
    'education_desc': 'Kalansen nafaw kama',
    'agriculture': 'Sarakaso',
    'agriculture_desc': 'Jiriw ni sarakaso bolofɛnw',
    'construction': 'Kɛnɛ',
    'construction_desc': 'Kɛnɛ bolofɛnw',
    'voyage': 'Taama',
    'voyage_desc': 'Taama nafaw kama',
    'commerce': 'Jaabi',
    'commerce_desc': 'Jaabi wari kama',
  },
  'wo': {
    'titre': 'Tontine bu bees',
    'nom': 'Tontine bi tur',
    'nom_hint': 'Tontine bu bees',
    'type': 'Tontine bu fan',
    'montant': 'Xaalis bu dëkk',
    'montant_hint': '150000',
    'membres': 'Nit yu am',
    'membres_hint': '10',
    'periodicite': 'Waxt bu fay',
    'date_debut': 'Bët ci kanam',
    'date_fin': 'Bët ci dëkk',
    'description': 'Wandlu',
    'description_hint': 'Wandlu sa tontine...',
    'media': 'Nataal walla vide',
    'recap': 'Jot ak jot',
    'cotisation_membre': 'Cotisation / nit',
    'duree': 'Waxt bu am',
    'jours': 'fan',
    'tours': 'yoon',
    'creer': 'Def tontine',
    'succes': 'Tontine defna ko !',
    'requis': 'Waajib',
    'montant_invalide': 'Xaalis bu baax',
    'min_membres': 'Nit yu 2 waajib',
    'vocal': 'Bind tur, xam-xam, xaalis ak nit yu am.',
    'quotidien': 'Fan bu nekk',
    '2_jours': 'Fan yu ñaar',
    'hebdomadaire': 'Ayu bu nekk',
    '2_semaines': 'Ayu yu ñaar',
    'mensuel': 'Weer bu nekk',
    'trimestriel': 'Weer yu ñett',
    'argent_liquide': 'Xaalis',
    'argent_liquide_desc': 'Nit bu nekk dafa jot xaalis bi',
    'objet': 'Xam-xam',
    'objet_desc': 'Tann xam-xam ci katalog bi',
    'caisse_fixe': 'Caisse',
    'caisse_fixe_desc': 'Xaalis bu am ak jël-jël',
    'evenementielle': 'Fête',
    'evenementielle_desc': 'Takk, dëkk, dëgg',
    'sante': 'Wer-gi',
    'sante_desc': 'Xaalis bu sant pour wer-gi',
    'education': 'Jàng',
    'education_desc': 'Jàng ak ay jëf',
    'agriculture': 'Ndey-ji',
    'agriculture_desc': 'Kanam ak ndey-ji',
    'construction': 'Kër-gi',
    'construction_desc': 'Ay jëf ci kër-gi',
    'voyage': 'Dem-dem',
    'voyage_desc': 'Dem-dem ak transport',
    'commerce': 'Jaay-jaay',
    'commerce_desc': 'Xaalis jaay-jaay kama',
  },
};

String _t(String langue, String key) {
  final lang = _tr[langue] ?? _tr['fr']!;
  return lang[key] ?? _tr['fr']![key] ?? key;
}

class CreerTontineScreen extends ConsumerStatefulWidget {
  const CreerTontineScreen({super.key});

  @override
  ConsumerState<CreerTontineScreen> createState() =>
      _CreerTontineScreenState();
}

class _CreerTontineScreenState extends ConsumerState<CreerTontineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  final _membresCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final VocalService _vocal = VocalService();

  String _type = 'argent_liquide';
  String _periodicite = 'hebdomadaire';
  int _periodicitejours = 7;
  DateTime _dateDebut = DateTime.now().add(const Duration(days: 1));
  DateTime? _dateFin;
  bool _chargement = false;
  String? _mediaImagePath;
  String? _mediaVideoPath;

  List<Map<String, dynamic>> _getTypes(String langue) => [
    {'code': 'argent_liquide', 'label': _t(langue, 'argent_liquide'),
      'emoji': '💰', 'description': _t(langue, 'argent_liquide_desc'),
      'couleur': const Color(0xFF1D9E75)},
    {'code': 'objet', 'label': _t(langue, 'objet'),
      'emoji': '📦', 'description': _t(langue, 'objet_desc'),
      'couleur': const Color(0xFF378ADD)},
    {'code': 'caisse_fixe', 'label': _t(langue, 'caisse_fixe'),
      'emoji': '🏦', 'description': _t(langue, 'caisse_fixe_desc'),
      'couleur': const Color(0xFFBA7517)},
    {'code': 'evenementielle', 'label': _t(langue, 'evenementielle'),
      'emoji': '🎉', 'description': _t(langue, 'evenementielle_desc'),
      'couleur': const Color(0xFFD4537E)},
    {'code': 'sante', 'label': _t(langue, 'sante'),
      'emoji': '🏥', 'description': _t(langue, 'sante_desc'),
      'couleur': const Color(0xFFE24B4A)},
    {'code': 'education', 'label': _t(langue, 'education'),
      'emoji': '🎓', 'description': _t(langue, 'education_desc'),
      'couleur': const Color(0xFF534AB7)},
    {'code': 'agriculture', 'label': _t(langue, 'agriculture'),
      'emoji': '🌾', 'description': _t(langue, 'agriculture_desc'),
      'couleur': const Color(0xFF639922)},
    {'code': 'construction', 'label': _t(langue, 'construction'),
      'emoji': '🏗️', 'description': _t(langue, 'construction_desc'),
      'couleur': const Color(0xFF888780)},
    {'code': 'voyage', 'label': _t(langue, 'voyage'),
      'emoji': '✈️', 'description': _t(langue, 'voyage_desc'),
      'couleur': const Color(0xFF0F6E56)},
    {'code': 'commerce', 'label': _t(langue, 'commerce'),
      'emoji': '🛒', 'description': _t(langue, 'commerce_desc'),
      'couleur': const Color(0xFFD85A30)},
  ];

  List<Map<String, dynamic>> _getPeriodicites(String langue) => [
    {'code': 'quotidien', 'label': _t(langue, 'quotidien'), 'jours': 1},
    {'code': '2_jours', 'label': _t(langue, '2_jours'), 'jours': 2},
    {'code': 'hebdomadaire', 'label': _t(langue, 'hebdomadaire'), 'jours': 7},
    {'code': '2_semaines', 'label': _t(langue, '2_semaines'), 'jours': 14},
    {'code': 'mensuel', 'label': _t(langue, 'mensuel'), 'jours': 30},
    {'code': 'trimestriel', 'label': _t(langue, 'trimestriel'), 'jours': 90},
  ];

  double get _cotisationParMembre {
    final montant = double.tryParse(_montantCtrl.text) ?? 0;
    final membres = int.tryParse(_membresCtrl.text) ?? 1;
    return membres > 0 ? montant / membres : 0;
  }

  DateTime get _dateFinCalculee {
    if (_dateFin != null) return _dateFin!;
    final membres = int.tryParse(_membresCtrl.text) ?? 1;
    return _dateDebut.add(Duration(days: _periodicitejours * membres));
  }

  Future<void> _creer(String langue) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _chargement = true);
    try {
      await ApiService.creerTontine({
        'nom': _nomCtrl.text.trim(),
        'type': _type,
        'description': _descriptionCtrl.text.trim(),
        'montant_cotisation': double.parse(_montantCtrl.text),
        'periodicite': _periodicite,
        'periodicite_jours': _periodicitejours,
        'nombre_membres': int.parse(_membresCtrl.text),
        'date_debut': _dateDebut.toIso8601String().split('T')[0],
        'date_fin': _dateFinCalculee.toIso8601String().split('T')[0],
        'ordre_rotation': 'tirage_sort',
      });
      _vocal.parler(_t(langue, 'succes'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t(langue, 'succes')),
            backgroundColor: AppTheme.vert,
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppTheme.rouge),
        );
      }
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final langue = ref.watch(langueProvider);
    final sw = MediaQuery.of(context).size.width;
    final isSmall = sw < 360;
    final padding = isSmall ? 12.0 : 16.0;
    final cardItemWidth = (sw - padding * 2 - 10) / 2.2;
    final cardItemHeight = isSmall ? 110.0 : 130.0;
    final types = _getTypes(langue);
    final periodicites = _getPeriodicites(langue);
    final typeSelectionne =
        types.firstWhere((t) => t['code'] == _type);

    return Scaffold(
      backgroundColor: AppTheme.fond,
      appBar: AppBar(
        backgroundColor: AppTheme.vert,
        foregroundColor: Colors.white,
        title: Text(
          _t(langue, 'titre'),
          style: TextStyle(
            fontFamily: 'Nunito',
            color: Colors.white,
            fontSize: isSmall ? 16 : 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded,
                color: Colors.white70),
            onPressed: () => _vocal.parler(_t(langue, 'vocal')),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── NOM ──────────────────────────────────────
              _buildSection(_t(langue, 'nom'), isSmall),
              TextFormField(
                controller: _nomCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: _t(langue, 'nom_hint'),
                  prefixIcon: const Icon(Icons.group_outlined),
                ),
                validator: (v) => v == null || v.isEmpty
                    ? _t(langue, 'requis') : null,
              ),
              SizedBox(height: isSmall ? 14 : 20),

              // ── TYPE ──────────────────────────────────────
              _buildSection(_t(langue, 'type'), isSmall),
              SizedBox(
                height: cardItemHeight,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: types.length,
                  itemBuilder: (ctx, i) {
                    final t = types[i];
                    final selected = _type == t['code'];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _type = t['code']);
                        _vocal.parler(
                            '${t['label']}. ${t['description']}');
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: cardItemWidth,
                        margin: const EdgeInsets.only(right: 10),
                        padding: EdgeInsets.all(isSmall ? 8 : 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? (t['couleur'] as Color).withOpacity(0.15)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? t['couleur'] as Color
                                : const Color(0xFFE8E8E5),
                            width: selected ? 2 : 0.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(t['emoji'],
                                style: TextStyle(
                                    fontSize: isSmall ? 24 : 30)),
                            SizedBox(height: isSmall ? 4 : 6),
                            Text(
                              t['label'],
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: isSmall ? 10 : 12,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? t['couleur'] as Color
                                    : AppTheme.texte,
                              ),
                            ),
                            SizedBox(height: isSmall ? 2 : 4),
                            Text(
                              t['description'],
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: isSmall ? 8 : 9,
                                color: AppTheme.grisTexte,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: (typeSelectionne['couleur'] as Color)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(typeSelectionne['emoji'],
                        style: TextStyle(
                            fontSize: isSmall ? 16 : 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        typeSelectionne['description'],
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isSmall ? 11 : 12,
                          color: typeSelectionne['couleur'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmall ? 14 : 20),

              // ── MONTANT ───────────────────────────────────
              _buildSection(_t(langue, 'montant'), isSmall),
              TextFormField(
                controller: _montantCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                decoration: InputDecoration(
                  hintText: _t(langue, 'montant_hint'),
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixText: 'F CFA',
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return _t(langue, 'requis');
                  if (double.tryParse(v) == null)
                    return _t(langue, 'montant_invalide');
                  return null;
                },
              ),
              SizedBox(height: isSmall ? 14 : 20),

              // ── MEMBRES ───────────────────────────────────
              _buildSection(_t(langue, 'membres'), isSmall),
              TextFormField(
                controller: _membresCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                decoration: InputDecoration(
                  hintText: _t(langue, 'membres_hint'),
                  prefixIcon: const Icon(Icons.people_outline),
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return _t(langue, 'requis');
                  final n = int.tryParse(v);
                  if (n == null || n < 2)
                    return _t(langue, 'min_membres');
                  return null;
                },
              ),
              SizedBox(height: isSmall ? 14 : 20),

              // ── PERIODICITE ───────────────────────────────
              _buildSection(_t(langue, 'periodicite'), isSmall),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: periodicites.map((p) {
                  final selected = _periodicite == p['code'];
                  return GestureDetector(
                    onTap: () => setState(() {
                      _periodicite = p['code'];
                      _periodicitejours = p['jours'];
                      _dateFin = null; // reset date fin manuelle
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmall ? 10 : 14,
                        vertical: isSmall ? 7 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.vert
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppTheme.vert
                              : const Color(0xFFE8E8E5),
                        ),
                      ),
                      child: Text(
                        p['label'],
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isSmall ? 11 : 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : AppTheme.texte,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: isSmall ? 14 : 20),

              // ── DATE DEBUT ────────────────────────────────
              _buildSection(_t(langue, 'date_debut'), isSmall),
              _buildDatePicker(
                date: _dateDebut,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateDebut,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now()
                        .add(const Duration(days: 365)),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(
                            primary: AppTheme.vert),
                      ),
                      child: child!,
                    ),
                  );
                  if (date != null) {
                    setState(() {
                      _dateDebut = date;
                      _dateFin = null;
                    });
                  }
                },
                isSmall: isSmall,
              ),
              SizedBox(height: isSmall ? 14 : 20),

              // ── DATE FIN ──────────────────────────────────
              _buildSection(_t(langue, 'date_fin'), isSmall),
              _buildDatePicker(
                date: _dateFinCalculee,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateFinCalculee,
                    firstDate: _dateDebut,
                    lastDate: DateTime.now()
                        .add(const Duration(days: 1825)),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(
                            primary: AppTheme.vert),
                      ),
                      child: child!,
                    ),
                  );
                  if (date != null) setState(() => _dateFin = date);
                },
                isSmall: isSmall,
                isCalculee: _dateFin == null,
              ),
              SizedBox(height: isSmall ? 14 : 20),

              // ── DESCRIPTION ───────────────────────────────
              _buildSection(_t(langue, 'description'), isSmall),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _t(langue, 'description_hint'),
                  prefixIcon:
                      const Icon(Icons.description_outlined),
                ),
              ),
              SizedBox(height: isSmall ? 14 : 20),

              // ── MEDIA ─────────────────────────────────────
              _buildSection(_t(langue, 'media'), isSmall),
              MediaPickerWidget(
                onMediaSelected: (imagePath, videoPath) {
                  setState(() {
                    _mediaImagePath = imagePath;
                    _mediaVideoPath = videoPath;
                  });
                },
              ),
              SizedBox(height: isSmall ? 14 : 20),

              // ── RECAP ─────────────────────────────────────
              if (_montantCtrl.text.isNotEmpty &&
                  _membresCtrl.text.isNotEmpty)
                _buildRecapitulatif(langue, isSmall, periodicites),
              const SizedBox(height: 24),

              // ── BOUTON ────────────────────────────────────
              _chargement
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.vert))
                  : SizedBox(
                      width: double.infinity,
                      height: isSmall ? 48 : 54,
                      child: ElevatedButton.icon(
                        onPressed: () => _creer(langue),
                        icon: const Icon(Icons.check),
                        label: Text(
                          _t(langue, 'creer'),
                          style: TextStyle(
                              fontSize: isSmall ? 14 : 16),
                        ),
                      ),
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String titre, bool isSmall) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        titre,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: isSmall ? 11 : 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.grisTexte,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required DateTime date,
    required VoidCallback onTap,
    required bool isSmall,
    bool isCalculee = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isSmall ? 12 : 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCalculee
                ? const Color(0xFFD3D1C7)
                : AppTheme.vert,
            width: isCalculee ? 1 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: isCalculee
                  ? AppTheme.grisTexte
                  : AppTheme.vert,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${date.day}/${date.month}/${date.year}',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: isSmall ? 13 : 15,
                  color: isCalculee
                      ? AppTheme.texte
                      : AppTheme.vert,
                  fontWeight: isCalculee
                      ? FontWeight.normal
                      : FontWeight.w600,
                ),
              ),
            ),
            if (isCalculee)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.grisClair,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Auto',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: isSmall ? 10 : 11,
                    color: AppTheme.grisTexte,
                  ),
                ),
              )
            else
              const Icon(Icons.edit_outlined,
                  color: AppTheme.vert, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRecapitulatif(String langue, bool isSmall,
      List<Map<String, dynamic>> periodicites) {
    final membres = int.tryParse(_membresCtrl.text) ?? 1;
    final periodeLabel = periodicites
        .firstWhere((p) => p['code'] == _periodicite)['label'];

    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.vertClair,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getTypes(langue)
                    .firstWhere((t) => t['code'] == _type)['emoji'],
                style: TextStyle(fontSize: isSmall ? 16 : 18),
              ),
              const SizedBox(width: 8),
              Text(
                _t(langue, 'recap'),
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: isSmall ? 13 : 15,
                  color: AppTheme.vertFonce,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildRecapLigne(
            _t(langue, 'cotisation_membre'),
            '${_cotisationParMembre.toStringAsFixed(0)} F / $periodeLabel',
            isSmall,
          ),
          _buildRecapLigne(
            _t(langue, 'duree'),
            '${membres * _periodicitejours} ${_t(langue, 'jours')}',
            isSmall,
          ),
          _buildRecapLigne(
            _t(langue, 'date_debut'),
            '${_dateDebut.day}/${_dateDebut.month}/${_dateDebut.year}',
            isSmall,
          ),
          _buildRecapLigne(
            _t(langue, 'date_fin'),
            '${_dateFinCalculee.day}/${_dateFinCalculee.month}/${_dateFinCalculee.year}',
            isSmall,
          ),
          _buildRecapLigne(
            _t(langue, 'membres'),
            '$membres ${_t(langue, 'tours')}',
            isSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildRecapLigne(
      String label, String valeur, bool isSmall) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: isSmall ? 11 : 13,
                color: AppTheme.grisTexte,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              valeur,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: isSmall ? 11 : 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.vertFonce,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _montantCtrl.dispose();
    _membresCtrl.dispose();
    _descriptionCtrl.dispose();
    _vocal.stop();
    super.dispose();
  }
}