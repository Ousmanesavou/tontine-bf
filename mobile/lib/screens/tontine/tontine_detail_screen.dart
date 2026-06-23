import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/vocal_service.dart';
import '../../main.dart';

// ── TRADUCTIONS ───────────────────────────────────────
const Map<String, Map<String, String>> _tr = {
  'fr': {
    'prochain_tour': 'Prochain tour',
    'progression': 'Progression',
    'membres': 'Membres',
    'inviter': 'Inviter',
    'sur': 'sur',
    'ont_recu': 'membres ont reçu',
    'prochain': 'Prochain',
    'tour': 'Tour',
    'cotisations': 'Cotisations',
    'historique': 'Historique',
    'infos': 'Informations',
    'payer': 'Payer',
    'a_jour': 'Toutes vos cotisations sont à jour !',
    'en_retard': 'Cotisation en retard !',
    'due_dans': 'Due dans',
    'jour': 'jour',
    'jours': 'jours',
    'date_debut': 'Date de début',
    'date_fin': 'Date de fin',
    'periodicite': 'Périodicité',
    'montant': 'Montant total',
    'type': 'Type',
    'statut': 'Statut',
    'actif': 'Actif',
    'termine': 'Terminé',
    'en_attente': 'En attente',
    'responsable': 'Responsable',
    'description': 'Description',
    'non_trouve': 'Tontine non trouvée',
    'vocal_detail': 'Tontine',
    'membres_recu': 'ont reçu leur tour',
    'par_jour': 'par jour',
    'par_semaine': 'par semaine',
    'par_mois': 'par mois',
    'par_2j': 'tous les 2 jours',
    'par_2sem': 'toutes les 2 semaines',
    'par_trim': 'par trimestre',
    'score': 'Fiabilité',
    'partager': 'Partager',
    'modifier': 'Modifier',
    'cotisation_courante': 'Cotisation en cours',
    'aucune_cotisation': 'Aucune cotisation en cours',
  },
  'en': {
    'prochain_tour': 'Next round',
    'progression': 'Progress',
    'membres': 'Members',
    'inviter': 'Invite',
    'sur': 'of',
    'ont_recu': 'members received',
    'prochain': 'Next',
    'tour': 'Round',
    'cotisations': 'Contributions',
    'historique': 'History',
    'infos': 'Information',
    'payer': 'Pay',
    'a_jour': 'All your contributions are up to date!',
    'en_retard': 'Late contribution!',
    'due_dans': 'Due in',
    'jour': 'day',
    'jours': 'days',
    'date_debut': 'Start date',
    'date_fin': 'End date',
    'periodicite': 'Frequency',
    'montant': 'Total amount',
    'type': 'Type',
    'statut': 'Status',
    'actif': 'Active',
    'termine': 'Finished',
    'en_attente': 'Pending',
    'responsable': 'Manager',
    'description': 'Description',
    'non_trouve': 'Tontine not found',
    'vocal_detail': 'Tontine',
    'membres_recu': 'have received their turn',
    'par_jour': 'per day',
    'par_semaine': 'per week',
    'par_mois': 'per month',
    'par_2j': 'every 2 days',
    'par_2sem': 'every 2 weeks',
    'par_trim': 'per quarter',
    'score': 'Reliability',
    'partager': 'Share',
    'modifier': 'Edit',
    'cotisation_courante': 'Current contribution',
    'aucune_cotisation': 'No current contribution',
  },
  'mos': {
    'prochain_tour': 'Tɩɩs paalga',
    'progression': 'Zagsem',
    'membres': 'Neb',
    'inviter': 'Bool',
    'sur': 'zugu',
    'ont_recu': 'neb paamame',
    'prochain': 'Paalga',
    'tour': 'Tɩɩs',
    'cotisations': 'Kõ-dãmba',
    'historique': 'Yɛl-tɛɛsã',
    'infos': 'Sɩb-rɛɛzã',
    'payer': 'Kõ',
    'a_jour': 'F kõ-dãmba fãa sɩng sɩda !',
    'en_retard': 'F cotisation la yɩɩr !',
    'due_dans': 'Rãmba',
    'jour': 'dãmb',
    'jours': 'dãmba',
    'date_debut': 'Sɩng-dãmba',
    'date_fin': 'Tɩɩm-dãmba',
    'periodicite': 'Kõ-wakatã',
    'montant': 'Ligdi fãa',
    'type': 'Bõne',
    'statut': 'Tɩɩga',
    'actif': 'Bee',
    'termine': 'Tɩɩmame',
    'en_attente': 'Rog-m-tɩɩg',
    'responsable': 'Naab',
    'description': 'Sɩbgrã',
    'non_trouve': 'Tontine ka be ye',
    'vocal_detail': 'Tontine',
    'membres_recu': 'paamame b yell',
    'par_jour': 'dũnni fãa',
    'par_semaine': 'wiki fãa',
    'par_mois': 'kiuugã fãa',
    'par_2j': 'dũnni 2',
    'par_2sem': 'wiki 2',
    'par_trim': 'kiuugu 3',
    'score': 'Kaseto',
    'partager': 'Pʋgd',
    'modifier': 'Toeeg',
    'cotisation_courante': 'Kõ rũnna',
    'aucune_cotisation': 'Kõ ka be ye',
  },
  'bm': {
    'prochain_tour': 'Yɔrɔ kura',
    'progression': 'Taabolo',
    'membres': 'Mɔgɔw',
    'inviter': 'Wele',
    'sur': 'kan',
    'ont_recu': 'mɔgɔw sɔrɔla',
    'prochain': 'Kura',
    'tour': 'Yɔrɔ',
    'cotisations': 'Saraliw',
    'historique': 'Kunnafoniw',
    'infos': 'Kunnafoni',
    'payer': 'Sara',
    'a_jour': 'I ka saraliw bɛɛ kɛra !',
    'en_retard': 'I ka sarali suura !',
    'due_dans': 'Tile',
    'jour': 'tile',
    'jours': 'tile',
    'date_debut': 'Daminɛ tile',
    'date_fin': 'Laban tile',
    'periodicite': 'Sara waati',
    'montant': 'Wari bɛɛ',
    'type': 'Sugandi',
    'statut': 'Cogoya',
    'actif': 'Be kɔnɔ',
    'termine': 'Bannana',
    'en_attente': 'Kɔnɔ',
    'responsable': 'Kuntigui',
    'description': 'Fɔtɔ',
    'non_trouve': 'Tontine si sɔrɔla',
    'vocal_detail': 'Tontine',
    'membres_recu': 'ye sɔrɔ',
    'par_jour': 'tile o tile',
    'par_semaine': 'dɔgɔkun kelen',
    'par_mois': 'kalo kelen',
    'par_2j': 'tile fila',
    'par_2sem': 'dɔgɔkun fila',
    'par_trim': 'kalo saba',
    'score': 'Danbe',
    'partager': 'Labɛn',
    'modifier': 'Yɛlɛma',
    'cotisation_courante': 'Sara sisan',
    'aucune_cotisation': 'Sara si be yen',
  },
  'wo': {
    'prochain_tour': 'Yoon bu bees',
    'progression': 'Xam-xam',
    'membres': 'Nit yi',
    'inviter': 'Wele',
    'sur': 'ci',
    'ont_recu': 'nit yi jotoon',
    'prochain': 'Bu bees',
    'tour': 'Yoon',
    'cotisations': 'Cotisations yi',
    'historique': 'Laaj yi',
    'infos': 'Xam-xam',
    'payer': 'Fay',
    'a_jour': 'Say cotisations yëpp dafa siiw !',
    'en_retard': 'Cotisation bi suura !',
    'due_dans': 'Ci fan',
    'jour': 'fan',
    'jours': 'fan',
    'date_debut': 'Bët ci kanam',
    'date_fin': 'Bët ci dëkk',
    'periodicite': 'Waxt bu fay',
    'montant': 'Xaalis bu am',
    'type': 'Xam-xam',
    'statut': 'Cogna',
    'actif': 'Am na',
    'termine': 'Jeex na',
    'en_attente': 'Xaaraan',
    'responsable': 'Boroom',
    'description': 'Wandlu',
    'non_trouve': 'Tontine bi amul',
    'vocal_detail': 'Tontine',
    'membres_recu': 'jotoon',
    'par_jour': 'fan bu nekk',
    'par_semaine': 'ayu bu nekk',
    'par_mois': 'weer bu nekk',
    'par_2j': 'fan yu ñaar',
    'par_2sem': 'ayu yu ñaar',
    'par_trim': 'weer yu ñett',
    'score': 'Diggante',
    'partager': 'Yëgël',
    'modifier': 'Soppi',
    'cotisation_courante': 'Cotisation bi',
    'aucune_cotisation': 'Cotisation amul',
  },
};

String _t(String langue, String key) {
  final lang = _tr[langue] ?? _tr['fr']!;
  return lang[key] ?? _tr['fr']![key] ?? key;
}

class TontineDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const TontineDetailScreen({super.key, required this.id});

  @override
  ConsumerState<TontineDetailScreen> createState() =>
      _TontineDetailScreenState();
}

class _TontineDetailScreenState extends ConsumerState<TontineDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _tontine;
  bool _chargement = true;
  late TabController _tabController;
  final VocalService _vocal = VocalService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _charger();
  }

  Future<void> _charger() async {
    try {
      final data = await ApiService.getTontine(widget.id);
      setState(() {
        _tontine = data;
        _chargement = false;
      });
    } catch (e) {
      setState(() => _chargement = false);
    }
  }

  String _typeEmoji(String? type) {
    const emojis = {
      'argent_liquide': '💰', 'objet': '📦',
      'caisse_fixe': '🏦', 'evenementielle': '🎉',
      'sante': '🏥', 'education': '🎓',
      'agriculture': '🌾', 'construction': '🏗️',
      'voyage': '✈️', 'commerce': '🛒',
    };
    return emojis[type] ?? '💰';
  }

  String _periodiciteLabel(String? p, String langue) {
    switch (p) {
      case 'quotidien': return _t(langue, 'par_jour');
      case '2_jours': return _t(langue, 'par_2j');
      case 'hebdomadaire': return _t(langue, 'par_semaine');
      case '2_semaines': return _t(langue, 'par_2sem');
      case 'mensuel': return _t(langue, 'par_mois');
      case 'trimestriel': return _t(langue, 'par_trim');
      default: return p ?? '';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final langue = ref.watch(langueProvider);
    final sw = MediaQuery.of(context).size.width;
    final isSmall = sw < 360;

    if (_chargement) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppTheme.vert)),
      );
    }

    if (_tontine == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.vert,
          foregroundColor: Colors.white,
          title: Text(_t(langue, 'non_trouve')),
        ),
        body: Center(child: Text(_t(langue, 'non_trouve'))),
      );
    }

    final t = _tontine!;
    final membres =
        List<Map<String, dynamic>>.from(t['membres'] as List? ?? []);
    final totalMembres = membres.length;
    final joursRestants = t['jours_restants'] as int? ?? 0;
    final couleur = joursRestants <= 1
        ? AppTheme.rouge
        : joursRestants <= 2
            ? AppTheme.orange
            : AppTheme.vert;
    final imageUrl = t['image_url'];

    return Scaffold(
      backgroundColor: AppTheme.fond,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          SliverAppBar(
            expandedHeight: isSmall ? 160 : 200,
            pinned: true,
            backgroundColor: AppTheme.vert,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.volume_up_rounded,
                    color: Colors.white70),
                onPressed: () => _vocal.parler(
                    '${_t(langue, 'vocal_detail')} ${t['nom']}. $totalMembres ${_t(langue, 'membres')}. ${t['montant_cotisation']} F.'),
              ),
              IconButton(
                icon: const Icon(Icons.people_outline,
                    color: Colors.white),
                onPressed: () =>
                    context.push('/tontine/${widget.id}/membres'),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                t['nom'] ?? '',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: isSmall ? 14 : 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: imageUrl != null
                  ? Image.network(imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildEmojiHeader(t))
                  : _buildEmojiHeader(t),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: isSmall ? 11 : 13,
              ),
              tabs: [
                Tab(text: _t(langue, 'progression')),
                Tab(text: _t(langue, 'membres')),
                Tab(text: _t(langue, 'infos')),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── ONGLET 1 : PROGRESSION ────────────────
            _buildOngletProgression(t, membres, totalMembres,
                joursRestants, couleur, langue, isSmall),
            // ── ONGLET 2 : MEMBRES ────────────────────
            _buildOngletMembres(membres, langue, isSmall),
            // ── ONGLET 3 : INFOS ─────────────────────
            _buildOngletInfos(t, langue, isSmall),
          ],
        ),
      ),
      bottomNavigationBar:
          _buildBottomBar(t, langue, isSmall, couleur, joursRestants),
    );
  }

  Widget _buildEmojiHeader(Map t) {
    return Container(
      color: AppTheme.vert,
      child: Center(
        child: Text(_typeEmoji(t['type']),
            style: const TextStyle(fontSize: 72)),
      ),
    );
  }

  // ── ONGLET PROGRESSION ────────────────────────────
  Widget _buildOngletProgression(
      Map t, List membres, int totalMembres,
      int joursRestants, Color couleur,
      String langue, bool isSmall) {
    final membresRecus =
        membres.where((m) => m['a_recu'] == true).length;
    final pct =
        totalMembres > 0 ? membresRecus / totalMembres : 0.0;

    return RefreshIndicator(
      color: AppTheme.vert,
      onRefresh: _charger,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats rapides
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    '$joursRestants ${joursRestants > 1 ? _t(langue, 'jours') : _t(langue, 'jour')}',
                    _t(langue, 'prochain_tour'),
                    couleur.withOpacity(0.1), couleur,
                    Icons.timer_outlined, isSmall,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    '${t['montant_cotisation']} F',
                    _periodiciteLabel(t['periodicite'], langue),
                    AppTheme.vertClair, AppTheme.vert,
                    Icons.payments_outlined, isSmall,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmall ? 12 : 16),

            // Progression circulaire
            Container(
              padding: EdgeInsets.all(isSmall ? 14 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFE8E8E5), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t(langue, 'progression'),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: isSmall ? 13 : 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.texte,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircularPercentIndicator(
                        radius: isSmall ? 30 : 40,
                        lineWidth: 6,
                        percent: pct.clamp(0.0, 1.0),
                        center: Text(
                          '${(pct * 100).toInt()}%',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: isSmall ? 11 : 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.vert,
                          ),
                        ),
                        progressColor: AppTheme.vert,
                        backgroundColor: AppTheme.vertClair,
                        circularStrokeCap: CircularStrokeCap.round,
                        animation: true,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$membresRecus ${_t(langue, 'sur')} $totalMembres ${_t(langue, 'ont_recu')}',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: isSmall ? 12 : 13,
                                color: AppTheme.grisTexte,
                              ),
                            ),
                            if (t['prochain_beneficiaire'] != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppTheme.vertClair,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_t(langue, 'prochain')} : ${t['prochain_beneficiaire']['prenom']} ${t['prochain_beneficiaire']['nom']}',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: isSmall ? 11 : 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.vertFonce,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Barre de progression linéaire
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      backgroundColor: AppTheme.vertClair,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.vert),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isSmall ? 12 : 16),

            // Ligne du temps des membres
            _buildLigneTemps(membres, langue, isSmall),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildLigneTemps(
      List membres, String langue, bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFE8E8E5), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_t(langue, 'tour')}s',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmall ? 13 : 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.texte,
            ),
          ),
          const SizedBox(height: 12),
          ...membres.asMap().entries.map((e) {
            final i = e.key;
            final m = e.value;
            final aRecu = m['a_recu'] == true;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  // Cercle numéroté
                  Container(
                    width: isSmall ? 28 : 32,
                    height: isSmall ? 28 : 32,
                    decoration: BoxDecoration(
                      color: aRecu
                          ? AppTheme.vert
                          : AppTheme.grisClair,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: aRecu
                          ? Icon(Icons.check,
                              color: Colors.white,
                              size: isSmall ? 14 : 16)
                          : Text(
                              '${m['position_rotation'] ?? i + 1}',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: isSmall ? 10 : 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.grisTexte,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${m['prenom'] ?? ''} ${m['nom'] ?? ''}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: isSmall ? 12 : 13,
                        fontWeight: aRecu
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: aRecu
                            ? AppTheme.vert
                            : AppTheme.texte,
                      ),
                    ),
                  ),
                  if (aRecu)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.vertClair,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '✅',
                        style:
                            TextStyle(fontSize: isSmall ? 12 : 14),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ── ONGLET MEMBRES ────────────────────────────────
  Widget _buildOngletMembres(
      List<Map<String, dynamic>> membres,
      String langue, bool isSmall) {
    if (membres.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👥', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              _t(langue, 'membres'),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                color: AppTheme.grisTexte,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isSmall ? 12 : 16),
      itemCount: membres.length,
      itemBuilder: (ctx, i) {
        final m = membres[i];
        final aRecu = m['a_recu'] == true;
        final score = m['score_fiabilite'] is int
            ? m['score_fiabilite'] as int
            : int.tryParse(
                    m['score_fiabilite']?.toString() ?? '100') ??
                100;
        final couleurScore = score >= 80
            ? AppTheme.vert
            : score >= 50
                ? AppTheme.orange
                : AppTheme.rouge;
        final photoUrl = m['photo_url'];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.all(isSmall ? 12 : 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: aRecu
                  ? AppTheme.vert.withOpacity(0.3)
                  : const Color(0xFFE8E8E5),
              width: aRecu ? 1 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: isSmall ? 40 : 46,
                height: isSmall ? 40 : 46,
                decoration: BoxDecoration(
                  color: aRecu
                      ? AppTheme.vert
                      : AppTheme.grisClair,
                  shape: BoxShape.circle,
                ),
                child: photoUrl != null
                    ? ClipOval(
                        child: Image.network(photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildInitiales(m, aRecu, isSmall)))
                    : _buildInitiales(m, aRecu, isSmall),
              ),
              SizedBox(width: isSmall ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${m['prenom'] ?? ''} ${m['nom'] ?? ''}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: isSmall ? 13 : 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.texte,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m['telephone'] ?? '',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: isSmall ? 11 : 12,
                        color: AppTheme.grisTexte,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.vertClair,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_t(langue, 'tour')} ${m['position_rotation'] ?? i + 1}',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: isSmall ? 9 : 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.vertFonce,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: couleurScore.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_t(langue, 'score')} $score%',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: isSmall ? 9 : 10,
                              fontWeight: FontWeight.w600,
                              color: couleurScore,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              aRecu
                  ? const Icon(Icons.check_circle,
                      color: AppTheme.vert, size: 24)
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.orangeClair,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _t(langue, 'en_attente'),
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isSmall ? 10 : 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.orangeFonce,
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInitiales(
      Map m, bool aRecu, bool isSmall) {
    return Center(
      child: Text(
        '${(m['prenom'] ?? '?')[0]}${(m['nom'] ?? '')[0]}',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: isSmall ? 12 : 14,
          fontWeight: FontWeight.w700,
          color: aRecu ? Colors.white : AppTheme.grisTexte,
        ),
      ),
    );
  }

  // ── ONGLET INFOS ──────────────────────────────────
  Widget _buildOngletInfos(
      Map t, String langue, bool isSmall) {
    final statut = t['statut'] ?? 'actif';
    final couleurStatut = statut == 'actif'
        ? AppTheme.vert
        : statut == 'termine'
            ? AppTheme.grisTexte
            : AppTheme.orange;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmall ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte infos principales
          Container(
            padding: EdgeInsets.all(isSmall ? 14 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFFE8E8E5), width: 0.5),
            ),
            child: Column(
              children: [
                _buildInfoLigne(
                  Icons.category_outlined,
                  _t(langue, 'type'),
                  '${_typeEmoji(t['type'])} ${t['type']?.toString().replaceAll('_', ' ') ?? ''}',
                  isSmall,
                ),
                _buildDivider(),
                _buildInfoLigne(
                  Icons.payments_outlined,
                  _t(langue, 'montant'),
                  '${t['montant_cotisation']} F ${_periodiciteLabel(t['periodicite'], langue)}',
                  isSmall,
                ),
                _buildDivider(),
                _buildInfoLigne(
                  Icons.people_outline,
                  _t(langue, 'membres'),
                  '${(t['membres'] as List?)?.length ?? 0} / ${t['nombre_membres'] ?? '-'}',
                  isSmall,
                ),
                _buildDivider(),
                _buildInfoLigne(
                  Icons.calendar_today_outlined,
                  _t(langue, 'date_debut'),
                  _formatDate(t['date_debut']),
                  isSmall,
                ),
                _buildDivider(),
                _buildInfoLigne(
                  Icons.event_outlined,
                  _t(langue, 'date_fin'),
                  _formatDate(t['date_fin']),
                  isSmall,
                ),
                _buildDivider(),
                _buildInfoLigneStatut(
                  couleurStatut,
                  _t(langue, 'statut'),
                  statut == 'actif'
                      ? _t(langue, 'actif')
                      : statut == 'termine'
                          ? _t(langue, 'termine')
                          : _t(langue, 'en_attente'),
                  isSmall,
                ),
              ],
            ),
          ),
          SizedBox(height: isSmall ? 12 : 16),

          // Responsable
          if (t['responsable'] != null) ...[
            Container(
              padding: EdgeInsets.all(isSmall ? 14 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFE8E8E5), width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: isSmall ? 40 : 46,
                    height: isSmall ? 40 : 46,
                    decoration: const BoxDecoration(
                      color: AppTheme.vertClair,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (t['responsable']['prenom'] ?? 'R')[0],
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isSmall ? 16 : 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.vert,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isSmall ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t(langue, 'responsable'),
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: isSmall ? 10 : 11,
                            color: AppTheme.grisTexte,
                          ),
                        ),
                        Text(
                          '${t['responsable']['prenom'] ?? ''} ${t['responsable']['nom'] ?? ''}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: isSmall ? 13 : 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.texte,
                          ),
                        ),
                        Text(
                          t['responsable']['telephone'] ?? '',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: isSmall ? 11 : 12,
                            color: AppTheme.grisTexte,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.vertClair,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _t(langue, 'responsable'),
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: isSmall ? 9 : 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.vertFonce,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isSmall ? 12 : 16),
          ],

          // Description
          if (t['description'] != null &&
              t['description'].toString().isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(isSmall ? 14 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFE8E8E5), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t(langue, 'description'),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: isSmall ? 11 : 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.grisTexte,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t['description'],
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: isSmall ? 13 : 14,
                      color: AppTheme.texte,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildInfoLigne(
      IconData icon, String label, String valeur, bool isSmall) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: isSmall ? 18 : 20, color: AppTheme.grisTexte),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: isSmall ? 12 : 13,
                color: AppTheme.grisTexte,
              ),
            ),
          ),
          Text(
            valeur,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmall ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.texte,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLigneStatut(
      Color couleur, String label, String valeur, bool isSmall) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(Icons.circle, size: isSmall ? 14 : 16, color: couleur),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: isSmall ? 12 : 13,
                color: AppTheme.grisTexte,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: couleur.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              valeur,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: isSmall ? 11 : 12,
                fontWeight: FontWeight.w700,
                color: couleur,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() =>
      const Divider(height: 1, color: Color(0xFFE8E8E5));

  Widget _statCard(String valeur, String label, Color bg,
      Color couleur, IconData icon, bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: couleur, size: isSmall ? 18 : 22),
          SizedBox(height: isSmall ? 4 : 6),
          Text(
            valeur,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmall ? 14 : 16,
              fontWeight: FontWeight.w700,
              color: couleur,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmall ? 9 : 11,
              color: AppTheme.grisTexte,
            ),
          ),
        ],
      ),
    );
  }

  // ── BOTTOM BAR PAIEMENT ───────────────────────────
  Widget _buildBottomBar(Map t, String langue,
      bool isSmall, Color couleur, int joursRestants) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, isSmall ? 16 : 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
            top: BorderSide(color: Color(0xFFE8E8E5), width: 0.5)),
      ),
      child: FutureBuilder<Map<String, dynamic>?>(
        future: ApiService.getCotisationEnCours(t['id']),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                height: 40,
                child: CircularProgressIndicator(
                    color: AppTheme.vert, strokeWidth: 2),
              ),
            );
          }

          final cotisation = snapshot.data;
          if (cotisation == null) {
            return Container(
              padding: EdgeInsets.all(isSmall ? 12 : 14),
              decoration: BoxDecoration(
                color: AppTheme.vertClair,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle,
                      color: AppTheme.vert, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _t(langue, 'a_jour'),
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: isSmall ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.vertFonce,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final montant =
              cotisation['montant']?.toString() ?? '0';
          final dateEcheance =
              cotisation['date_echeance'] != null
                  ? DateTime.parse(cotisation['date_echeance'])
                  : null;
          final jours = dateEcheance != null
              ? dateEcheance.difference(DateTime.now()).inDays
              : 0;
          final c = jours <= 0
              ? AppTheme.rouge
              : jours <= 2
                  ? AppTheme.orange
                  : AppTheme.vert;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (jours <= 2)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          color: c, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        jours <= 0
                            ? _t(langue, 'en_retard')
                            : '${_t(langue, 'due_dans')} $jours ${jours > 1 ? _t(langue, 'jours') : _t(langue, 'jour')}',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isSmall ? 12 : 13,
                          fontWeight: FontWeight.w600,
                          color: c,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: isSmall ? 46 : 52,
                child: ElevatedButton.icon(
                  onPressed: () => context
                      .push('/paiement/${cotisation['id']}'),
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(
                    '${_t(langue, 'payer')} $montant F CFA',
                    style: TextStyle(
                        fontSize: isSmall ? 14 : 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _vocal.stop();
    super.dispose();
  }
}