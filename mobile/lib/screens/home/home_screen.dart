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

final tontinesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ApiService.getMesTontines();
});

final tontinesPubliquesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ApiService.getTontinesPubliques();
});

// ── TRADUCTIONS HOME ──────────────────────────────────
const Map<String, Map<String, String>> _tr = {
  'fr': {
    'bonjour': 'Bonjour',
    'sous_titre': 'Aw laafi  •  I ni sogoma',
    'mes_tontines': 'Mes tontines actives',
    'tontines_publiques': 'Tontines disponibles',
    'nouvelle_tontine': 'Nouvelle tontine',
    'tontines_actives': 'Tontines actives',
    'cotisations': 'Cotisations',
    'rien_urgent': 'Rien d\'urgent',
    'urgente': 'urgente',
    'urgentes': 'urgentes',
    'hors_ligne': 'Mode hors-ligne — Données en cache',
    'pas_tontine': 'Pas encore de tontine',
    'creer_premiere': 'Créez votre première tontine\nou rejoignez un groupe existant',
    'creer_tontine': 'Créer une tontine',
    'pas_connexion': 'Pas de connexion internet',
    'impossible_charger': 'Impossible de charger',
    'donnees_cache': 'Vos données en cache s\'afficheront dès que possible.',
    'reessayer': 'Réessayer',
    'voir_details': 'Appuyez sur une tontine pour voir les détails.',
    'rejoindre': 'Rejoindre',
    'demande_envoyee': 'Demande envoyée',
    'complet': 'Complet',
    'membres': 'membres',
    'aucune_publique': 'Aucune tontine publique disponible',
    'rechercher': 'Rechercher une tontine...',
    'onglet_mes': 'Mes tontines',
    'onglet_publiques': 'Rejoindre',
  },
  'en': {
    'bonjour': 'Hello',
    'sous_titre': 'Welcome  •  Good day',
    'mes_tontines': 'My active tontines',
    'tontines_publiques': 'Available tontines',
    'nouvelle_tontine': 'New tontine',
    'tontines_actives': 'Active tontines',
    'cotisations': 'Contributions',
    'rien_urgent': 'Nothing urgent',
    'urgente': 'urgent',
    'urgentes': 'urgent',
    'hors_ligne': 'Offline mode — Cached data',
    'pas_tontine': 'No tontine yet',
    'creer_premiere': 'Create your first tontine\nor join an existing group',
    'creer_tontine': 'Create a tontine',
    'pas_connexion': 'No internet connection',
    'impossible_charger': 'Unable to load',
    'donnees_cache': 'Your cached data will appear as soon as possible.',
    'reessayer': 'Retry',
    'voir_details': 'Tap a tontine to see details.',
    'rejoindre': 'Join',
    'demande_envoyee': 'Request sent',
    'complet': 'Full',
    'membres': 'members',
    'aucune_publique': 'No public tontine available',
    'rechercher': 'Search a tontine...',
    'onglet_mes': 'My tontines',
    'onglet_publiques': 'Join',
  },
  'mos': {
    'bonjour': 'Aw laafi',
    'sous_titre': 'Tontine Africa pʋgẽ aw laafi',
    'mes_tontines': 'M tontines wʋsgã',
    'tontines_publiques': 'Tontines wʋsgã',
    'nouvelle_tontine': 'Tontine paalga',
    'tontines_actives': 'Tontines wʋsgã',
    'cotisations': 'Cotisations',
    'rien_urgent': 'Bũmb ka be ye',
    'urgente': 'toore',
    'urgentes': 'toore',
    'hors_ligne': 'Internet ka be — Dɩkr yɛla',
    'pas_tontine': 'Tontine ka be tɩ ta',
    'creer_premiere': 'Bʋg f tontine yembr\nwall kẽng tontine yembr pʋgẽ',
    'creer_tontine': 'Bʋg tontine',
    'pas_connexion': 'Internet ka be',
    'impossible_charger': 'Ka tõe n loog ye',
    'donnees_cache': 'F dɩkr yɛla lʋɩɩ tao-tao.',
    'reessayer': 'Tɩ sok kãsem',
    'voir_details': 'Paam tontine n ges a yelle.',
    'rejoindre': 'Kẽng',
    'demande_envoyee': 'Kẽngr tõog',
    'complet': 'Pida',
    'membres': 'neb',
    'aucune_publique': 'Tontine ka be',
    'rechercher': 'Bʋgs tontine...',
    'onglet_mes': 'M tontines',
    'onglet_publiques': 'Kẽng',
  },
  'bm': {
    'bonjour': 'I ni sogoma',
    'sous_titre': 'Tontine Africa la i bisimila',
    'mes_tontines': 'N ka tontinew',
    'tontines_publiques': 'Tontinew minw be',
    'nouvelle_tontine': 'Tontine kura',
    'tontines_actives': 'Tontinew minw be',
    'cotisations': 'Saraliw',
    'rien_urgent': 'Fɛn t\'a fɛ joona',
    'urgente': 'teliman',
    'urgentes': 'teliman',
    'hors_ligne': 'Internet tε — Kunnafoni jɔlen',
    'pas_tontine': 'Tontine si sɔrɔla fɔlɔ',
    'creer_premiere': 'I ka tontine daminɛ\nwalima tontine dɔnn kɔnɔ don',
    'creer_tontine': 'Tontine daminɛ',
    'pas_connexion': 'Internet tε',
    'impossible_charger': 'A tε se ka load',
    'donnees_cache': 'I ka kunnafoni bɛ na.',
    'reessayer': 'A lajɛ',
    'voir_details': 'Tontine dɔnn kun ka a kunnafoni ye.',
    'rejoindre': 'Don',
    'demande_envoyee': 'Daali tɔgɔlen',
    'complet': 'Mɔgɔw bɛ yen',
    'membres': 'mɔgɔw',
    'aucune_publique': 'Tontine si be yen',
    'rechercher': 'Tontine ɲini...',
    'onglet_mes': 'N ka tontinew',
    'onglet_publiques': 'Don',
  },
  'wo': {
    'bonjour': 'Salut',
    'sous_titre': 'Tontine Africa, dalal ak jàmm',
    'mes_tontines': 'Say tontine yi',
    'tontines_publiques': 'Tontine yi ci kanam',
    'nouvelle_tontine': 'Tontine bu bees',
    'tontines_actives': 'Tontine yi',
    'cotisations': 'Cotisations yi',
    'rien_urgent': 'Dara mën a xam',
    'urgente': 'xóot',
    'urgentes': 'xóot',
    'hors_ligne': 'Offline — Données yi ci cache bi',
    'pas_tontine': 'Tontine amul ci kanam',
    'creer_premiere': 'Def sa tontine bu njëkk\nwalla dugg ci ab tontine',
    'creer_tontine': 'Def tontine',
    'pas_connexion': 'Internet amul',
    'impossible_charger': 'Mënul a yóbbu',
    'donnees_cache': 'Say données yi dina ñëw.',
    'reessayer': 'Jëf ci kanam',
    'voir_details': 'Topp tontine bu xam sa xam.',
    'rejoindre': 'Dugg',
    'demande_envoyee': 'Dëkk yónéen',
    'complet': 'Donn na',
    'membres': 'nit yi',
    'aucune_publique': 'Tontine amul',
    'rechercher': 'Seet tontine...',
    'onglet_mes': 'Say tontine',
    'onglet_publiques': 'Dugg',
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
          ref.refresh(tontinesPubliquesProvider);
        }
      }
    });
    ConnectivityService.estConnecte().then((connecte) {
      if (mounted) setState(() => _estConnecte = connecte);
    });
  }

  Future<void> _saluerUtilisateur() async {
    final user = StorageService.getUser();
    if (user != null) {
      final langue = StorageService.getLangue() ?? 'fr';
      final prenom = user['prenom'] ?? '';
      final messages = {
        'fr': 'Bonjour $prenom ! Bienvenue sur Tontine Africa.',
        'en': 'Hello $prenom! Welcome to Tontine Africa.',
        'mos': 'Aw laafi $prenom ! Tontine Africa pʋgẽ aw laafi.',
        'bm': 'I ni sogoma $prenom ! Tontine Africa la i bisimila.',
        'wo': 'Salut $prenom ! Tontine Africa, dalal ak jàmm.',
      };
      await Future.delayed(const Duration(seconds: 1));
      _vocal.parler(messages[langue] ?? messages['fr']!);
    }
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
            backgroundColor: AppTheme.rouge,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = StorageService.getUser();
    final tontines = ref.watch(tontinesProvider);
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
            // Onglets
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
                  // ── ONGLET 1 : MES TONTINES ──────────────
                  RefreshIndicator(
                    color: AppTheme.vert,
                    onRefresh: () => ref.refresh(tontinesProvider.future),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(isSmall ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatCards(tontines, langue, isSmall),
                          SizedBox(height: isSmall ? 14 : 20),
                          _buildSectionTitre(_t(langue, 'mes_tontines')),
                          tontines.when(
                            data: (data) => data.isEmpty
                                ? _buildEtatVide(langue)
                                : Column(
                                    children: data
                                        .map((t) => TontineCard(
                                              tontine: t,
                                              onTap: () => context.push(
                                                  '/tontine/${t['id']}'),
                                            ))
                                        .toList(),
                                  ),
                            loading: () => _buildChargement(),
                            error: (e, _) =>
                                _buildErreur(e.toString(), langue),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),

                  // ── ONGLET 2 : TONTINES PUBLIQUES ────────
                  _buildTontinesPubliques(langue, isSmall),
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

  Widget _buildTontinesPubliques(String langue, bool isSmall) {
    final tontinesPubliques = ref.watch(tontinesPubliquesProvider);
    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: EdgeInsets.all(isSmall ? 12 : 16),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: _t(langue, 'rechercher'),
              prefixIcon: const Icon(Icons.search, color: AppTheme.grisTexte),
              suffixIcon: _recherche.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppTheme.grisTexte),
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
            onRefresh: () => ref.refresh(tontinesPubliquesProvider.future),
            child: tontinesPubliques.when(
              data: (data) {
                final filtre = _recherche.isEmpty
                    ? data
                    : data.where((t) => t['nom']
                            .toString()
                            .toLowerCase()
                            .contains(_recherche.toLowerCase()))
                        .toList();

                if (filtre.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔍', style: TextStyle(fontSize: 48)),
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
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 12 : 16,
                    vertical: 4,
                  ),
                  itemCount: filtre.length,
                  itemBuilder: (ctx, i) =>
                      _buildTontinePubliqueCard(filtre[i], langue, isSmall),
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

  Widget _buildTontinePubliqueCard(
      Map<String, dynamic> t, String langue, bool isSmall) {
    final tontineId = t['id'].toString();
    final estMembre = t['est_membre'] == true;
    final demandeEnAttente =
        t['demande_en_attente'] == true || _demandesEnvoyees[tontineId] == true;
    final totalMembres = int.tryParse(t['total_membres']?.toString() ?? '0') ?? 0;
    final nombreMembres = int.tryParse(t['nombre_membres']?.toString() ?? '0') ?? 0;
    final estComplet = totalMembres >= nombreMembres && nombreMembres > 0;

    final typeEmoji = {
      'argent_liquide': '💰', 'objet': '📦', 'caisse_fixe': '🏦',
      'evenementielle': '🎉', 'sante': '🏥', 'education': '🎓',
      'agriculture': '🌾', 'construction': '🏗️', 'voyage': '✈️',
      'commerce': '🛒',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E5), width: 0.5),
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
                      style: TextStyle(fontSize: isSmall ? 20 : 24),
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
                // Bouton rejoindre
                if (estMembre)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.vertClair,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('✅',
                        style: TextStyle(fontSize: 16)),
                  )
                else if (estComplet)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.grisTexte.withOpacity(0.1),
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
                  )
                else if (demandeEnAttente)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.orangeClair,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _t(langue, 'demande_envoyee'),
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: isSmall ? 10 : 11,
                        color: AppTheme.orangeFonce,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => _demanderAdhesion(tontineId, langue),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
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
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Infos
            Row(
              children: [
                _buildInfoChip(
                  '${double.tryParse(t['montant_cotisation']?.toString() ?? '0')?.toStringAsFixed(0)} F',
                  Icons.attach_money,
                  isSmall,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  '$totalMembres/$nombreMembres ${_t(langue, 'membres')}',
                  Icons.people_outline,
                  isSmall,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  t['periodicite']?.toString().replaceAll('_', ' ') ?? '',
                  Icons.calendar_today_outlined,
                  isSmall,
                ),
              ],
            ),
            // Barre de progression membres
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: nombreMembres > 0
                    ? (totalMembres / nombreMembres).clamp(0.0, 1.0)
                    : 0,
                backgroundColor: AppTheme.grisTexte.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  estComplet ? AppTheme.rouge : AppTheme.vert,
                ),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.fond,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmall ? 10 : 12, color: AppTheme.grisTexte),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmall ? 10 : 11,
              color: AppTheme.grisTexte,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
      Map<String, dynamic>? user, String langue, bool isSmall) {
    return Container(
      color: AppTheme.vert,
      padding: EdgeInsets.fromLTRB(
          isSmall ? 12 : 16, 12, isSmall ? 12 : 16, 14),
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
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _t(langue, 'sous_titre'),
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: isSmall ? 11 : 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _vocal.parler(_t(langue, 'voir_details')),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.volume_up_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push('/profil'),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  (user?['prenom'] ?? 'U')[0].toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: isSmall ? 14 : 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                fontFamily: 'Nunito', fontSize: 12,
                fontWeight: FontWeight.w600, color: AppTheme.orangeFonce,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              ref.refresh(tontinesProvider);
              ref.refresh(tontinesPubliquesProvider);
            },
            child: const Icon(Icons.refresh,
                color: AppTheme.orangeFonce, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(
      AsyncValue tontines, String langue, bool isSmall) {
    return tontines.when(
      data: (data) {
        final liste = data as List<Map<String, dynamic>>;
        final urgentes = liste
            .where((t) => (t['jours_restants'] as int? ?? 99) <= 2)
            .length;
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '${liste.length}',
                _t(langue, 'tontines_actives'),
                AppTheme.vertClair, AppTheme.vert,
                Icons.groups_outlined, isSmall,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                urgentes > 0
                    ? '$urgentes ${urgentes > 1 ? _t(langue, 'urgentes') : _t(langue, 'urgente')}'
                    : _t(langue, 'rien_urgent'),
                _t(langue, 'cotisations'),
                urgentes > 0 ? AppTheme.orangeClair : AppTheme.vertClair,
                urgentes > 0 ? AppTheme.orange : AppTheme.vert,
                urgentes > 0
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                isSmall,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildStatCard(String valeur, String label, Color bg,
      Color couleur, IconData icon, bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 10 : 14),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: couleur, size: isSmall ? 22 : 28),
          SizedBox(width: isSmall ? 6 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valeur,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: isSmall ? 13 : 16,
                      fontWeight: FontWeight.w700,
                      color: couleur,
                    )),
                Text(label,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: isSmall ? 9 : 11,
                      color: AppTheme.grisTexte,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitre(String titre) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        titre,
        style: const TextStyle(
          fontFamily: 'Nunito', fontSize: 16,
          fontWeight: FontWeight.w700, color: AppTheme.texte,
        ),
      ),
    );
  }

  Widget _buildEtatVide(String langue) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('💰', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            _t(langue, 'pas_tontine'),
            style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 16,
              fontWeight: FontWeight.w600, color: AppTheme.texte,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _t(langue, 'creer_premiere'),
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppTheme.grisTexte, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.push('/tontine/creer'),
            icon: const Icon(Icons.add),
            label: Text(_t(langue, 'creer_tontine')),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 44),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargement() {
    return Column(
      children: List.generate(3, (i) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      )),
    );
  }

  Widget _buildErreur(String message, String langue) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: !_estConnecte ? AppTheme.orangeClair : AppTheme.rougeClair,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            !_estConnecte ? Icons.wifi_off_rounded : Icons.error_outline,
            color: !_estConnecte ? AppTheme.orange : AppTheme.rouge,
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            !_estConnecte
                ? _t(langue, 'pas_connexion')
                : _t(langue, 'impossible_charger'),
            style: TextStyle(
              color: !_estConnecte ? AppTheme.orangeFonce : AppTheme.rouge,
              fontWeight: FontWeight.w600, fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            !_estConnecte ? _t(langue, 'donnees_cache') : message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 12,
              color: AppTheme.grisTexte,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              ref.refresh(tontinesProvider);
              ref.refresh(tontinesPubliquesProvider);
            },
            icon: const Icon(Icons.refresh),
            label: Text(_t(langue, 'reessayer')),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  !_estConnecte ? AppTheme.orange : AppTheme.rouge,
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