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

final tontinesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ApiService.getMesTontines();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;
  bool _estConnecte = true;
  final VocalService _vocal = VocalService();

  @override
  void initState() {
    super.initState();
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
    ConnectivityService.estConnecte().then((connecte) {
      if (mounted) setState(() => _estConnecte = connecte);
    });
  }

  Future<void> _saluerUtilisateur() async {
    final user = StorageService.getUser();
    if (user != null) {
      final langue = StorageService.getLangue() ?? 'fr';
      final messages = {
        'fr': 'Bonjour ${user['prenom']} ! Bienvenue sur Tontine BF.',
        'moore': 'Aw laafi ${user['prenom']} ! Tontine BF pʋgẽ aw laafi.',
        'dioula': 'I ni sogoma ${user['prenom']} ! Tontine BF la i bisimila.',
      };
      await Future.delayed(const Duration(seconds: 1));
      _vocal.parler(messages[langue] ?? messages['fr']!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = StorageService.getUser();
    final tontines = ref.watch(tontinesProvider);

    return Scaffold(
      backgroundColor: AppTheme.fond,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(user),
            if (!_estConnecte) _buildBandeauHorsLigne(),
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.vert,
                onRefresh: () => ref.refresh(tontinesProvider.future),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatCards(tontines),
                      const SizedBox(height: 20),
                      _buildSectionTitre('Mes tontines actives'),
                      tontines.when(
                        data: (data) => data.isEmpty
                            ? _buildEtatVide()
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
                        error: (e, _) => _buildErreur(e.toString()),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tontine/creer'),
        backgroundColor: AppTheme.vert,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nouvelle tontine',
          style: TextStyle(
              color: Colors.white,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          switch (i) {
            case 1:
              context.push('/catalogue');
              break;
            case 2:
              context.push('/notifications');
              break;
            case 3:
              context.push('/profil');
              break;
          }
        },
      ),
    );
  }

  Widget _buildTopBar(Map<String, dynamic>? user) {
    return Container(
      color: AppTheme.vert,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour ${user?['prenom'] ?? ''} 👋',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Aw laafi  •  I ni sogoma',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _vocal.parler(
                'Appuyez sur une tontine pour voir les détails.'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.volume_up_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push('/profil'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  (user?['prenom'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBandeauHorsLigne() {
    return Container(
      color: AppTheme.orangeClair,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: AppTheme.orangeFonce, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Mode hors-ligne — Données en cache',
              style: TextStyle(
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

  Widget _buildStatCards(AsyncValue tontines) {
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
                'Tontines actives',
                AppTheme.vertClair,
                AppTheme.vert,
                Icons.groups_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                urgentes > 0
                    ? '$urgentes urgente${urgentes > 1 ? 's' : ''}'
                    : 'Rien d\'urgent',
                'Cotisations',
                urgentes > 0 ? AppTheme.orangeClair : AppTheme.vertClair,
                urgentes > 0 ? AppTheme.orange : AppTheme.vert,
                urgentes > 0
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
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
      Color couleur, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: couleur, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valeur,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: couleur,
                    )),
                Text(label,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
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
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.texte,
        ),
      ),
    );
  }

  Widget _buildEtatVide() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('💰', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            'Pas encore de tontine',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.texte,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Créez votre première tontine\nou rejoignez un groupe existant',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.grisTexte, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.push('/tontine/creer'),
            icon: const Icon(Icons.add),
            label: const Text('Créer une tontine'),
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
      children: List.generate(
        3,
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildErreur(String message) {
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
                ? 'Pas de connexion internet'
                : 'Impossible de charger',
            style: TextStyle(
              color: !_estConnecte ? AppTheme.orangeFonce : AppTheme.rouge,
              fontWeight: FontWeight.w600,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            !_estConnecte
                ? 'Vos données en cache s\'afficheront dès que possible.'
                : message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: AppTheme.grisTexte,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => ref.refresh(tontinesProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  !_estConnecte ? AppTheme.orange : AppTheme.rouge,
            ),
          ),
        ],
      ),
    );
  }
}