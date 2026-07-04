import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/vocal_service.dart';
import '../../services/connectivity_service.dart';
import '../widgets/tontine_card.dart';
import '../widgets/bottom_nav.dart';
import '../../main.dart';

// ── PROVIDERS ──────────────────────────────────────────
final tontinesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ApiService.getMesTontines();
});

final tontinesPubliquesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, search) async {
  return await ApiService.getTontinesPubliques(search: search);
});

// ── TRADUCTIONS ───────────────────────────────────────
const Map<String, Map<String, String>> _tr = {
  'fr': {
    'bonjour': 'Bonjour',
    'sous_titre': 'Aw laafi  •  I ni sogoma',
    'mes_tontines': 'Mes tontines',
    'tontines_publiques': 'Tontines disponibles',
    'nouvelle_tontine': 'Nouvelle tontine',
    'tontines_actives': 'Actives',
    'cotisations_urgentes': 'Urgent',
    'solde_total': 'Solde total',
    'rien_urgent': 'À jour ✅',
    'urgente': 'urgente',
    'urgentes': 'urgentes',
    'hors_ligne': 'Mode hors-ligne — Données en cache',
    'pas_tontine': 'Pas encore de tontine',
    'creer_premiere': 'Créez votre première tontine\nou rejoignez un groupe existant',
    'creer_tontine': 'Créer une tontine',
    'pas_connexion': 'Pas de connexion internet',
    'impossible_charger': 'Impossible de charger',
    'donnees_cache': 'Données en cache affichées.',
    'reessayer': 'Réessayer',
    'voir_details': 'Appuyez sur une tontine pour voir les détails.',
    'rejoindre': 'Rejoindre',
    'demande_envoyee': 'Demande envoyée !',
    'complet': 'Complet',
    'membres': 'membres',
    'aucune_publique': 'Aucune tontine publique disponible',
    'rechercher': 'Rechercher une tontine...',
    'onglet_mes': 'Mes tontines',
    'onglet_publiques': 'Rejoindre',
    'voir_tout': 'Voir tout',
    'prochain_tour': 'Prochain tour',
    'jours': 'jours',
    'jour': 'jour',
    'cotisation_due': 'Cotisation due',
    'payer': 'Payer',
    'resume': 'Résumé',
    'total_epargne': 'Total épargné',
    'prochaine_echeance': 'Prochaine échéance',
    'score': 'Mon score',
    'inviter': 'Inviter',
    'en_retard': 'En retard !',
    'demande_en_attente': 'En attente',
  },
  'en': {
    'bonjour': 'Hello',
    'sous_titre': 'Welcome  •  Good day',
    'mes_tontines': 'My tontines',
    'tontines_publiques': 'Available tontines',
    'nouvelle_tontine': 'New tontine',
    'tontines_actives': 'Active',
    'cotisations_urgentes': 'Urgent',
    'solde_total': 'Total balance',
    'rien_urgent': 'Up to date ✅',
    'urgente': 'urgent',
    'urgentes': 'urgent',
    'hors_ligne': 'Offline mode — Cached data',
    'pas_tontine': 'No tontine yet',
    'creer_premiere': 'Create your first tontine\nor join an existing group',
    'creer_tontine': 'Create a tontine',
    'pas_connexion': 'No internet connection',
    'impossible_charger': 'Unable to load',
    'donnees_cache': 'Cached data displayed.',
    'reessayer': 'Retry',
    'voir_details': 'Tap a tontine to see details.',
    'rejoindre': 'Join',
    'demande_envoyee': 'Request sent!',
    'complet': 'Full',
    'membres': 'members',
    'aucune_publique': 'No public tontine available',
    'rechercher': 'Search a tontine...',
    'onglet_mes': 'My tontines',
    'onglet_publiques': 'Join',
    'voir_tout': 'See all',
    'prochain_tour': 'Next round',
    'jours': 'days',
    'jour': 'day',
    'cotisation_due': 'Due contribution',
    'payer': 'Pay',
    'resume': 'Summary',
    'total_epargne': 'Total saved',
    'prochaine_echeance': 'Next deadline',
    'score': 'My score',
    'inviter': 'Invite',
    'en_retard': 'Late!',
    'demande_en_attente': 'Pending',
  },
  'mos': {
    'bonjour': 'Aw laafi',
    'sous_titre': 'TontiLigdi pʋgẽ aw laafi',
    'mes_tontines': 'M tontines',
    'tontines_publiques': 'Tontines wʋsgã',
    'nouvelle_tontine': 'Tontine paalga',
    'tontines_actives': 'Bee',
    'cotisations_urgentes': 'Toore',
    'solde_total': 'Ligdi fãa',
    'rien_urgent': 'Sɩda ✅',
    'urgente': 'toore',
    'urgentes': 'toore',
    'hors_ligne': 'Internet ka be — Dɩkr yɛla',
    'pas_tontine': 'Tontine ka be tɩ ta',
    'creer_premiere': 'Bʋg f tontine yembr\nwall kẽng tontine pʋgẽ',
    'creer_tontine': 'Bʋg tontine',
    'pas_connexion': 'Internet ka be',
    'impossible_charger': 'Ka tõe n loog ye',
    'donnees_cache': 'F dɩkr yɛla lʋɩɩ.',
    'reessayer': 'Tɩ sok kãsem',
    'voir_details': 'Paam tontine n ges a yelle.',
    'rejoindre': 'Kẽng',
    'demande_envoyee': 'Kẽngr tõog !',
    'complet': 'Pida',
    'membres': 'neb',
    'aucune_publique': 'Tontine ka be',
    'rechercher': 'Bʋgs tontine...',
    'onglet_mes': 'M tontines',
    'onglet_publiques': 'Kẽng',
    'voir_tout': 'Ges fãa',
    'prochain_tour': 'Tɩɩs paalga',
    'jours': 'dãmba',
    'jour': 'dãmb',
    'cotisation_due': 'Kõ tõnd',
    'payer': 'Kõ',
    'resume': 'Fãa-wilgr',
    'total_epargne': 'Ligdi kũuni',
    'prochaine_echeance': 'Wakatã',
    'score': 'M kaseto',
    'inviter': 'Bool',
    'en_retard': 'Yɩɩr !',
    'demande_en_attente': 'Rog-m-tɩɩg',
  },
  'bm': {
    'bonjour': 'I ni sogoma',
    'sous_titre': 'TontiLigdi la i bisimila',
    'mes_tontines': 'N ka tontinew',
    'tontines_publiques': 'Tontinew minw be',
    'nouvelle_tontine': 'Tontine kura',
    'tontines_actives': 'Be kɔnɔ',
    'cotisations_urgentes': 'Teliman',
    'solde_total': 'Wari bɛɛ',
    'rien_urgent': 'Ɲɛ ✅',
    'urgente': 'teliman',
    'urgentes': 'teliman',
    'hors_ligne': 'Internet tε — Kunnafoni jɔlen',
    'pas_tontine': 'Tontine si sɔrɔla',
    'creer_premiere': 'I ka tontine daminɛ\nwalima tontine dɔnn kɔnɔ don',
    'creer_tontine': 'Tontine daminɛ',
    'pas_connexion': 'Internet tε',
    'impossible_charger': 'A tε se ka load',
    'donnees_cache': 'Kunnafoni jɔlen.',
    'reessayer': 'A lajɛ',
    'voir_details': 'Tontine dɔnn kun.',
    'rejoindre': 'Don',
    'demande_envoyee': 'Daali tɔgɔlen !',
    'complet': 'Mɔgɔw bɛ',
    'membres': 'mɔgɔw',
    'aucune_publique': 'Tontine si be',
    'rechercher': 'Tontine ɲini...',
    'onglet_mes': 'N ka tontinew',
    'onglet_publiques': 'Don',
    'voir_tout': 'Bɛɛ ye',
    'prochain_tour': 'Yɔrɔ kura',
    'jours': 'tile',
    'jour': 'tile',
    'cotisation_due': 'Sara ɲɛnabɔ',
    'payer': 'Sara',
    'resume': 'Jɛnsɛgɛli',
    'total_epargne': 'Wari mara',
    'prochaine_echeance': 'Waati',
    'score': 'N danbe',
    'inviter': 'Wele',
    'en_retard': 'Suura !',
    'demande_en_attente': 'Kɔnɔ',
  },
  'wo': {
    'bonjour': 'Salut',
    'sous_titre': 'TontiLigdi, dalal ak jàmm',
    'mes_tontines': 'Say tontine yi',
    'tontines_publiques': 'Tontine yi ci kanam',
    'nouvelle_tontine': 'Tontine bu bees',
    'tontines_actives': 'Am na',
    'cotisations_urgentes': 'Xóot',
    'solde_total': 'Xaalis bu am',
    'rien_urgent': 'Siiw ✅',
    'urgente': 'xóot',
    'urgentes': 'xóot',
    'hors_ligne': 'Offline — Cache bi',
    'pas_tontine': 'Tontine amul',
    'creer_premiere': 'Def sa tontine bu njëkk\nwalla dugg ci ab tontine',
    'creer_tontine': 'Def tontine',
    'pas_connexion': 'Internet amul',
    'impossible_charger': 'Mënul a yóbbu',
    'donnees_cache': 'Cache bi.',
    'reessayer': 'Jëf ci kanam',
    'voir_details': 'Topp tontine.',
    'rejoindre': 'Dugg',
    'demande_envoyee': 'Dëkk yónnéen !',
    'complet': 'Donn na',
    'membres': 'nit yi',
    'aucune_publique': 'Tontine amul',
    'rechercher': 'Seet tontine...',
    'onglet_mes': 'Say tontine',
    'onglet_publiques': 'Dugg',
    'voir_tout': 'Xool yëpp',
    'prochain_tour': 'Yoon bu bees',
    'jours': 'fan',
    'jour': 'fan',
    'cotisation_due': 'Cotisation waajib',
    'payer': 'Fay',
    'resume': 'Jot ak jot',
    'total_epargne': 'Xaalis baabu',
    'prochaine_echeance': 'Waxt bi',
    'score': 'Sam score',
    'inviter': 'Wele',
    'en_retard': 'Suura !',
    'demande_en_attente': 'Xaaraan',
  },
};

String _t(String langue, String key) {
  final lang = _tr[langue] ?? _tr['fr']!;
  return lang[key] ?? _tr['fr']![key] ?? key;
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _navIndex = 0;
  bool _estConnecte = true;
  late TabController _tabController;
  final VocalService _vocal = VocalService();
  final TextEditingController _searchCtrl = TextEditingController();
  String _recherche = '';
  final Map<String, bool> _demandesEnvoyees = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _saluerUtilisateur();
    _surveillerConnectivite();
  }

  void _surveillerConnectivite() {
    ConnectivityService.streamConnectivite.listen((connecte) {
      if (mounted) {
        setState(() => _estConnecte = connecte);
        if (connecte) {
          ref.refresh(tontinesProvider);
        }
      }
    });
    ConnectivityService.estConnecte()
        .then((c) { if (mounted) setState(() => _estConnecte = c); });
  }

  Future<void> _saluerUtilisateur() async {
    final user = StorageService.getUser();
    if (user == null) return;
    final langue = StorageService.getLangue() ?? 'fr';
    final prenom = user['prenom'] ?? '';
    final messages = {
      'fr': 'Bonjour $prenom ! Bienvenue sur TontiLigdi.',
      'en': 'Hello $prenom! Welcome to TontiLigdi.',
      'mos': 'Aw laafi $prenom ! TontiLigdi pʋgẽ aw laafi.',
      'bm': 'I ni sogoma $prenom ! TontiLigdi la i bisimila.',
      'wo': 'Salut $prenom ! TontiLigdi, dalal ak jàmm.',
    };
    await Future.delayed(const Duration(milliseconds: 800));
    _vocal.parler(messages[langue] ?? messages['fr']!);
  }

  Future<void> _demanderAdhesion(String tontineId, String langue) async {
    try {
      await ApiService.demanderAdhesion(tontineId);
      setState(() => _demandesEnvoyees[tontineId] = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t(langue, 'demande_envoyee')),
            backgroundColor: AppTheme.vert,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppTheme.rouge),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = StorageService.getUser();
    final langue = ref.watch(langueProvider);
    final sw = MediaQuery.of(context).size.width;
    final isSmall = sw < 360;

    return Scaffold(
      backgroundColor: AppTheme.fond,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(user, langue, isSmall),
            if (!_estConnecte) _buildBandeauHorsLigne(langue),
            Container(
              color: AppTheme.vert,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: isSmall ? 12 : 14,
                ),
                tabs: [
                  Tab(text: _t(langue, 'onglet_mes')),
                  Tab(text: _t(langue, 'onglet_publiques')),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOngletMesTontines(langue, isSmall),
                  _buildOngletPubliques(langue, isSmall),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tontine/creer'),
        backgroundColor: AppTheme.vert,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _t(langue, 'nouvelle_tontine'),
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
            fontSize: isSmall ? 13 : 15,
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          switch (i) {
            case 1: context.push('/catalogue'); break;
            case 2: context.push('/notifications'); break;
            case 3: context.push('/profil'); break;
          }
        },
      ),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────
  Widget _buildTopBar(Map<String, dynamic>? user,
      String langue, bool isSmall) {
    final score = int.tryParse(
            user?['score_fiabilite']?.toString() ?? '100') ?? 100;
    final couleurScore = score >= 80
        ? Colors.white
        : score >= 60
            ? const Color(0xFFFFE082)
            : const Color(0xFFEF9A9A);

    return Container(
      color: AppTheme.vert,
      padding: EdgeInsets.fromLTRB(
          isSmall ? 14 : 18, 12, isSmall ? 14 : 18, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_t(langue, 'bonjour')} ${user?['prenom'] ?? ''} 👋',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: isSmall ? 17 : 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _t(langue, 'sous_titre'),
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: isSmall ? 11 : 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '⭐ $score%',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isSmall ? 10 : 11,
                          fontWeight: FontWeight.w700,
                          color: couleurScore,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _vocal.parler(_t(langue, 'voir_details')),
            child: Container(
              width: isSmall ? 34 : 38,
              height: isSmall ? 34 : 38,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.volume_up_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push('/profil'),
            child: Container(
              width: isSmall ? 38 : 42,
              height: isSmall ? 38 : 42,
              decoration: BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: _buildAvatarHome(user, isSmall),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BANDEAU HORS LIGNE ────────────────────────────────
  Widget _buildBandeauHorsLigne(String langue) {
    return Container(
      color: AppTheme.orangeClair,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: AppTheme.orangeFonce, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _t(langue, 'hors_ligne'),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.orangeFonce,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => ref.refresh(tontinesProvider),
            child: const Icon(Icons.refresh,
                color: AppTheme.orangeFonce, size: 18),
          ),
        ],
      ),
    );
  }

  // ── ONGLET MES TONTINES ───────────────────────────────
  Widget _buildOngletMesTontines(String langue, bool isSmall) {
    final tontinesAsync = ref.watch(tontinesProvider);

    return RefreshIndicator(
      color: AppTheme.vert,
      onRefresh: () => ref.refresh(tontinesProvider.future),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
            isSmall ? 12 : 16, isSmall ? 12 : 16,
            isSmall ? 12 : 16, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── RÉSUMÉ FINANCIER ──────────────────────
            tontinesAsync.when(
              data: (data) => _buildResumeFinancier(data, langue, isSmall),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            SizedBox(height: isSmall ? 14 : 18),

            // ── COTISATIONS URGENTES ──────────────────
            tontinesAsync.when(
              data: (data) {
                final urgentes = data.where((t) =>
                    (t['jours_restants'] as int? ?? 99) <= 3).toList();
                if (urgentes.isEmpty) return const SizedBox();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitre(
                        '🔴 ${_t(langue, 'cotisations_urgentes')}', isSmall),
                    ...urgentes.map((t) =>
                        _buildCotisationUrgente(t, langue, isSmall)),
                    SizedBox(height: isSmall ? 14 : 18),
                  ],
                );
              },
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),

            // ── MES TONTINES ──────────────────────────
            _buildSectionTitre(
                _t(langue, 'mes_tontines'), isSmall),
            tontinesAsync.when(
              data: (data) => data.isEmpty
                  ? _buildEtatVide(langue, isSmall)
                  : Column(
                      children: data
                          .map((t) {
                            final user = StorageService.getUser();
                            final estOrga = t['responsable_id']?.toString() == user?['id']?.toString();
                            return TontineCard(
                              tontine: t,
                              onTap: () => context.push('/tontine/${t['id']}'),
                              estOrganisateur: estOrga,
                            );
                          }).toList(),
                    ),
              loading: () => _buildChargement(),
              error: (e, _) => _buildErreur(e.toString(), langue),
            ),
          ],
        ),
      ),
    );
  }

  // ── RÉSUMÉ FINANCIER ──────────────────────────────────
  Widget _buildResumeFinancier(List<Map<String, dynamic>> tontines,
      String langue, bool isSmall) {
    final nbActives = tontines.length;
    final urgentes = tontines
        .where((t) => (t['jours_restants'] as int? ?? 99) <= 3)
        .length;
    final soldeTotal = tontines.fold<double>(
        0,
        (s, t) =>
            s + (double.tryParse(t['solde_virtuel']?.toString() ?? '0') ?? 0));

    // Prochaine échéance
    int? joursMin;
    for (final t in tontines) {
      final j = t['jours_restants'] as int?;
      if (j != null && (joursMin == null || j < joursMin)) joursMin = j;
    }

    final user = StorageService.getUser();
    final score = int.tryParse(
            user?['score_fiabilite']?.toString() ?? '100') ?? 100;

    return Container(
      padding: EdgeInsets.all(isSmall ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.vert, AppTheme.vertFonce],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.vert.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Solde total
          Text(
            _t(langue, 'solde_total'),
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            soldeTotal > 0
                ? '${soldeTotal >= 1000 ? '${(soldeTotal / 1000).toStringAsFixed(0)}k' : soldeTotal.toStringAsFixed(0)} F CFA'
                : '— F CFA',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmall ? 26 : 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          // Stats rapides
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  '$nbActives',
                  _t(langue, 'tontines_actives'),
                  Icons.groups_outlined,
                  isSmall,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStat(
                  urgentes > 0 ? '$urgentes ⚠️' : _t(langue, 'rien_urgent'),
                  _t(langue, 'cotisations_urgentes'),
                  Icons.timer_outlined,
                  isSmall,
                  couleur: urgentes > 0
                      ? const Color(0xFFFFE082)
                      : Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStat(
                  '$score%',
                  _t(langue, 'score'),
                  Icons.star_outline_rounded,
                  isSmall,
                  couleur: score >= 80
                      ? const Color(0xFFFFE082)
                      : const Color(0xFFEF9A9A),
                ),
              ),
            ],
          ),
          // Prochaine échéance
          if (joursMin != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_outlined,
                      color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${_t(langue, 'prochaine_echeance')}: $joursMin ${joursMin > 1 ? _t(langue, 'jours') : _t(langue, 'jour')}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildAvatarHome(Map<String, dynamic>? user, bool isSmall) {
  final photoUrl = user?['photo_url'] ?? user?['photo_profil'];
  final prenom = user?['prenom'] ?? 'U';

  if (photoUrl != null && photoUrl.toString().isNotEmpty) {
    return Image.network(
      photoUrl,
      fit: BoxFit.cover,
      width: isSmall ? 38 : 42,
      height: isSmall ? 38 : 42,
      errorBuilder: (_, __, ___) => _buildInitialesHome(prenom, isSmall),
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }
  return _buildInitialesHome(prenom, isSmall);
}

Widget _buildInitialesHome(String prenom, bool isSmall) {
  return Container(
    color: Colors.white24,
    child: Center(
      child: Text(
        prenom[0].toUpperCase(),
        style: TextStyle(
          fontFamily: 'Nunito',
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: isSmall ? 15 : 17,
        ),
      ),
    ),
  );
}
  Widget _buildMiniStat(String valeur, String label,
      IconData icon, bool isSmall, {Color couleur = Colors.white}) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 8 : 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: couleur, size: isSmall ? 14 : 16),
          const SizedBox(height: 4),
          Text(
            valeur,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmall ? 12 : 14,
              fontWeight: FontWeight.w700,
              color: couleur,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 9,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  // ── COTISATION URGENTE ────────────────────────────────
  Widget _buildCotisationUrgente(Map<String, dynamic> t,
      String langue, bool isSmall) {
    final jours = t['jours_restants'] as int? ?? 0;
    final estRetard = jours <= 0;
    final couleur = estRetard ? AppTheme.rouge : AppTheme.orange;
    final montant = t['montant_cotisation']?.toString() ?? '0';

    return GestureDetector(
      onTap: () => context.push('/tontine/${t['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(isSmall ? 12 : 14),
        decoration: BoxDecoration(
          color: couleur.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: couleur.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: isSmall ? 36 : 42,
              height: isSmall ? 36 : 42,
              decoration: BoxDecoration(
                color: couleur.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                estRetard
                    ? Icons.warning_rounded
                    : Icons.timer_outlined,
                color: couleur,
                size: isSmall ? 18 : 20,
              ),
            ),
            SizedBox(width: isSmall ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t['nom'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: isSmall ? 13 : 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.texte,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    estRetard
                        ? _t(langue, 'en_retard')
                        : '$jours ${jours > 1 ? _t(langue, 'jours') : _t(langue, 'jour')}',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: isSmall ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: couleur,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 10 : 14,
                vertical: isSmall ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: couleur,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_t(langue, 'payer')} $montant F',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: isSmall ? 10 : 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ONGLET PUBLIQUES ──────────────────────────────────
  Widget _buildOngletPubliques(String langue, bool isSmall) {
    final tontinesPubliques =
        ref.watch(tontinesPubliquesProvider(_recherche));

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(isSmall ? 12 : 16),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: _t(langue, 'rechercher'),
              prefixIcon:
                  const Icon(Icons.search, color: AppTheme.grisTexte),
              suffixIcon: _recherche.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: AppTheme.grisTexte),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _recherche = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
            ),
            onChanged: (v) => setState(() => _recherche = v),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppTheme.vert,
            onRefresh: () =>
                ref.refresh(tontinesPubliquesProvider(_recherche).future),
            child: tontinesPubliques.when(
              data: (data) {
                if (data.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔍',
                            style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          _t(langue, 'aucune_publique'),
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            color: AppTheme.grisTexte,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                      isSmall ? 12 : 16, 0,
                      isSmall ? 12 : 16, 90),
                  itemCount: data.length,
                  itemBuilder: (ctx, i) =>
                      _buildCartePublique(data[i], langue, isSmall),
                );
              },
              loading: () => _buildChargement(),
              error: (e, _) => _buildErreur(e.toString(), langue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartePublique(Map<String, dynamic> t,
      String langue, bool isSmall) {
    final tontineId = t['id'].toString();
    final estMembre = t['est_membre'] == true;
    final demandeEnAttente = t['demande_en_attente'] == true ||
        _demandesEnvoyees[tontineId] == true;
    final totalMembres =
        int.tryParse(t['total_membres']?.toString() ?? '0') ?? 0;
    final nombreMembres =
        int.tryParse(t['nombre_membres']?.toString() ?? '0') ?? 0;
    final estComplet =
        totalMembres >= nombreMembres && nombreMembres > 0;
    final solde = double.tryParse(
            t['solde_virtuel']?.toString() ?? '0') ?? 0;

    const typeEmoji = {
      'argent_liquide': '💰', 'objet': '📦', 'caisse_fixe': '🏦',
      'evenementielle': '🎉', 'sante': '🏥', 'education': '🎓',
      'agriculture': '🌾', 'construction': '🏗️', 'voyage': '✈️',
      'commerce': '🛒',
    };

    return GestureDetector(
      onTap: () => context.push('/tontine/$tontineId'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFFE8E8E5), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: isSmall ? 42 : 48,
                    height: isSmall ? 42 : 48,
                    decoration: BoxDecoration(
                      color: AppTheme.vertClair,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        typeEmoji[t['type']] ?? '💰',
                        style: TextStyle(
                            fontSize: isSmall ? 20 : 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t['nom'] ?? '',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: isSmall ? 14 : 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.texte,
                          ),
                        ),
                        Text(
                          '${t['responsable_prenom'] ?? ''} ${t['responsable_nom'] ?? ''}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: isSmall ? 11 : 12,
                            color: AppTheme.grisTexte,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bouton action
                  _buildBoutonRejoindre(
                      tontineId, estMembre, demandeEnAttente,
                      estComplet, langue, isSmall),
                ],
              ),
              const SizedBox(height: 12),
              // Infos
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildChip(
                    '${double.tryParse(t['montant_cotisation']?.toString() ?? '0')?.toStringAsFixed(0)} F',
                    Icons.attach_money,
                    isSmall,
                  ),
                  _buildChip(
                    '$totalMembres/$nombreMembres ${_t(langue, 'membres')}',
                    Icons.people_outline,
                    isSmall,
                  ),
                  _buildChip(
                    t['periodicite']?.toString().replaceAll('_', ' ') ?? '',
                    Icons.calendar_today_outlined,
                    isSmall,
                  ),
                  if (solde > 0)
                    _buildChip(
                      '🏦 ${solde >= 1000 ? '${(solde / 1000).toStringAsFixed(0)}k' : solde.toStringAsFixed(0)} F',
                      Icons.account_balance_wallet_outlined,
                      isSmall,
                      couleur: AppTheme.vert,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Barre progression membres
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: nombreMembres > 0
                      ? (totalMembres / nombreMembres).clamp(0.0, 1.0)
                      : 0,
                  backgroundColor:
                      AppTheme.grisTexte.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    estComplet ? AppTheme.rouge : AppTheme.vert,
                  ),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoutonRejoindre(String tontineId, bool estMembre,
      bool demandeEnAttente, bool estComplet,
      String langue, bool isSmall) {
    if (estMembre) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.vertClair,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('✅', style: TextStyle(fontSize: 16)),
      );
    }
    if (estComplet) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.grisClair,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _t(langue, 'complet'),
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: isSmall ? 11 : 12,
            color: AppTheme.grisTexte,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    if (demandeEnAttente) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.orangeClair,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _t(langue, 'demande_en_attente'),
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: isSmall ? 10 : 11,
            color: AppTheme.orangeFonce,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () => _demanderAdhesion(tontineId, langue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.vert,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _t(langue, 'rejoindre'),
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: isSmall ? 12 : 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, bool isSmall,
      {Color? couleur}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: couleur != null
            ? couleur.withOpacity(0.1)
            : AppTheme.fond,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: isSmall ? 10 : 12,
              color: couleur ?? AppTheme.grisTexte),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmall ? 10 : 11,
              color: couleur ?? AppTheme.grisTexte,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitre(String titre, bool isSmall) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        titre,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: isSmall ? 14 : 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.texte,
        ),
      ),
    );
  }

  Widget _buildEtatVide(String langue, bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 24 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('💰', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text(
            _t(langue, 'pas_tontine'),
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmall ? 15 : 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.texte,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _t(langue, 'creer_premiere'),
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppTheme.grisTexte,
                fontSize: 13,
                fontFamily: 'Nunito'),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.push('/tontine/creer'),
            icon: const Icon(Icons.add),
            label: Text(_t(langue, 'creer_tontine')),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 46)),
          ),
        ],
      ),
    );
  }

  Widget _buildChargement() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          3,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErreur(String message, String langue) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: !_estConnecte
            ? AppTheme.orangeClair
            : AppTheme.rougeClair,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            !_estConnecte
                ? Icons.wifi_off_rounded
                : Icons.error_outline,
            color: !_estConnecte ? AppTheme.orange : AppTheme.rouge,
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            !_estConnecte
                ? _t(langue, 'pas_connexion')
                : _t(langue, 'impossible_charger'),
            style: TextStyle(
              color: !_estConnecte
                  ? AppTheme.orangeFonce
                  : AppTheme.rouge,
              fontWeight: FontWeight.w700,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => ref.refresh(tontinesProvider),
            icon: const Icon(Icons.refresh),
            label: Text(_t(langue, 'reessayer')),
            style: ElevatedButton.styleFrom(
              backgroundColor: !_estConnecte
                  ? AppTheme.orange
                  : AppTheme.rouge,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _vocal.stop();
    super.dispose();
  }
}
