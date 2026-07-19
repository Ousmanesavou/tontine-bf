import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../main.dart';

const Map<String, Map<String, String>> _tr = {
  'fr': {
    'dashboard': 'Dashboard organisateur',
    'vue_ensemble': 'Vue d ensemble',
    'membres': 'Membres',
    'paiements': 'Paiements',
    'securite': 'Securite',
    'regles': 'Regles',
    'membres_actifs': 'Membres actifs',
    'solde': 'Solde collecte',
    'prochain_tour': 'Prochain tour',
    'taux_paiement': 'Taux paiement',
    'en_retard': 'En retard',
    'a_collecter': 'A collecter',
    'valider': 'Valider',
    'rejeter': 'Rejeter',
    'accepter': 'Accepter',
    'refuser': 'Refuser',
    'exclure': 'Exclure',
    'relancer': 'Relancer',
    'demandes': 'Demandes adhesion',
    'ordre_rotation': 'Ordre rotation',
    'historique': 'Historique paiements',
    'valider_paiement': 'Valider paiement',
    'securite_titre': 'Statut securite',
    'regles_titre': 'Regles de la tontine',
    'progression': 'Progression du cycle',
    'activite': 'Activite recente',
    'non_trouve': 'Tontine non trouvee',
    'maj': 'Mis a jour',
    'jours': 'jours',
    'jour': 'jour',
  },
  'en': {
    'dashboard': 'Organizer dashboard',
    'vue_ensemble': 'Overview',
    'membres': 'Members',
    'paiements': 'Payments',
    'securite': 'Security',
    'regles': 'Rules',
    'membres_actifs': 'Active members',
    'solde': 'Collected',
    'prochain_tour': 'Next round',
    'taux_paiement': 'Payment rate',
    'en_retard': 'Late',
    'a_collecter': 'To collect',
    'valider': 'Validate',
    'rejeter': 'Reject',
    'accepter': 'Accept',
    'refuser': 'Refuse',
    'exclure': 'Exclude',
    'relancer': 'Remind',
    'demandes': 'Join requests',
    'ordre_rotation': 'Rotation order',
    'historique': 'Payment history',
    'valider_paiement': 'Validate payment',
    'securite_titre': 'Security status',
    'regles_titre': 'Tontine rules',
    'progression': 'Cycle progress',
    'activite': 'Recent activity',
    'non_trouve': 'Tontine not found',
    'maj': 'Updated',
    'jours': 'days',
    'jour': 'day',
  },
};

String _t(String langue, String key) =>
    (_tr[langue] ?? _tr['fr']!)[key] ?? (_tr['fr']![key] ?? key);

class DashboardOrganisateurScreen extends ConsumerStatefulWidget {
  final String tontineId;
  const DashboardOrganisateurScreen({super.key, required this.tontineId});

  @override
  ConsumerState<DashboardOrganisateurScreen> createState() =>
      _DashboardOrganisateurScreenState();
}

class _DashboardOrganisateurScreenState
    extends ConsumerState<DashboardOrganisateurScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _dashboard;
  bool _chargement = true;
  DateTime? _derniereMaj;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _charger();
    // ✅ Polling automatique toutes les 30 secondes
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _charger(silencieux: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _charger({bool silencieux = false}) async {
    if (!silencieux) setState(() => _chargement = true);
    try {
      final data = await ApiService.getDashboardOrganisateur(widget.tontineId);
      if (mounted) {
        setState(() {
          _dashboard = data;
          _chargement = false;
          _derniereMaj = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted && !silencieux) setState(() => _chargement = false);
    }
  }

  // ── GETTERS PRATIQUES ─────────────────────────────────
  Map<String, dynamic> get _tontine => _dashboard?['tontine'] ?? {};
  List<Map<String, dynamic>> get _membres =>
      List<Map<String, dynamic>>.from(_dashboard?['membres'] ?? []);
  List<Map<String, dynamic>> get _cotisations =>
      List<Map<String, dynamic>>.from(_dashboard?['cotisations'] ?? []);
  List<Map<String, dynamic>> get _demandes =>
      List<Map<String, dynamic>>.from(_dashboard?['demandes'] ?? []);
  Map<String, dynamic> get _stats => _dashboard?['stats'] ?? {};
  List<Map<String, dynamic>> get _activite =>
      List<Map<String, dynamic>>.from(_dashboard?['activite'] ?? []);

  // ── ACTIONS ───────────────────────────────────────────
  Future<void> _accepterMembre(String adhesionId) async {
    try {
      await ApiService.accepterAdhesion(adhesionId);
      await _charger();
      if (mounted) _snack('Membre accepte !', AppTheme.vert);
    } catch (e) {
      if (mounted) _snack(e.toString(), AppTheme.rouge);
    }
  }

  Future<void> _refuserMembre(String adhesionId) async {
    try {
      await ApiService.refuserAdhesion(adhesionId);
      await _charger();
    } catch (_) {}
  }

  Future<void> _validerPaiement(String cotisationId) async {
    try {
      await ApiService.validerPaiementManuel(widget.tontineId, cotisationId);
      await _charger();
      if (mounted) _snack('Paiement valide !', AppTheme.vert);
    } catch (e) {
      if (mounted) _snack(e.toString(), AppTheme.rouge);
    }
  }

  Future<void> _relancerMembre(String membreId, String prenom) async {
    try {
      await ApiService.relancerMembre(widget.tontineId, membreId);
      if (mounted) _snack('Rappel envoye a $prenom', AppTheme.vert);
    } catch (_) {}
  }

  Future<void> _exclureMembre(String membreId, String prenom) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmer exclusion',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
        content: Text('Exclure $prenom de cette tontine ?',
            style: const TextStyle(fontFamily: 'Nunito')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rouge),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exclure', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.exclureMembre(widget.tontineId, membreId);
        await _charger();
        if (mounted) _snack('$prenom exclu', AppTheme.orange);
      } catch (_) {}
    }
  }

  void _snack(String msg, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: couleur));
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) { return dateStr; }
  }

  String _formatHeure(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final d = DateTime.parse(dateStr).toLocal();
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppTheme.vert;
    if (score >= 60) return AppTheme.orange;
    return AppTheme.rouge;
  }

  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFE8E8E5), width: 0.5),
  );

  Widget _sectionTitre(String titre) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(titre, style: const TextStyle(
        fontFamily: 'Nunito', fontSize: 15,
        fontWeight: FontWeight.w700, color: AppTheme.texte)),
  );

  Widget _statCard(String valeur, String label, IconData icon,
      Color couleur, bool isSmall) =>
      Container(
        padding: EdgeInsets.all(isSmall ? 10 : 12),
        decoration: BoxDecoration(
          color: couleur.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: couleur, size: isSmall ? 18 : 22),
            SizedBox(height: isSmall ? 4 : 6),
            Text(valeur, style: TextStyle(fontFamily: 'Nunito',
                fontSize: isSmall ? 16 : 20,
                fontWeight: FontWeight.w700, color: couleur)),
            Text(label, style: TextStyle(fontFamily: 'Nunito',
                fontSize: isSmall ? 9 : 10, color: AppTheme.grisTexte)),
          ],
        ),
      );

  Widget _buildAlerte(String msg, Color couleur, IconData icon) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: couleur.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: couleur.withOpacity(0.3), width: 1),
        ),
        child: Row(children: [
          Icon(icon, color: couleur, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: TextStyle(
              fontFamily: 'Nunito', fontSize: 12,
              fontWeight: FontWeight.w600, color: couleur))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final langue = ref.watch(langueProvider);
    final sw = MediaQuery.of(context).size.width;
    final isSmall = sw < 360;

    if (_chargement) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppTheme.vert)));
    }

    if (_dashboard == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppTheme.vert,
            foregroundColor: Colors.white,
            title: Text(_t(langue, 'non_trouve'))),
        body: Center(child: ElevatedButton(
          onPressed: _charger, child: const Text('Réessayer'))),
      );
    }

    final enRetard = int.tryParse(_stats['total_retards']?.toString() ?? '0') ?? 0;
    final taux = int.tryParse(_stats['taux_paiement']?.toString() ?? '0') ?? 0;
    final solde = double.tryParse(_stats['solde']?.toString() ?? '0') ?? 0;
    final montantCollecte = double.tryParse(_stats['montant_collecte']?.toString() ?? '0') ?? 0;
    final joursRestants = int.tryParse(_tontine['jours_restants']?.toString() ?? '0') ?? 0;
    final totalMembres = int.tryParse(_tontine['nombre_membres']?.toString() ?? '0') ?? 0;
    final membresRecus = _membres.where((m) => m['a_recu'] == true).length;
    final pct = totalMembres > 0 ? membresRecus / totalMembres : 0.0;
    final aCollecter = (enRetard * (double.tryParse(_tontine['montant_cotisation']?.toString() ?? '0') ?? 0)).toDouble();

    return Scaffold(
      backgroundColor: AppTheme.fond,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.vertFonce,
            foregroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_t(langue, 'dashboard'), style: const TextStyle(
                    fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 16)),
                Text(_tontine['nom'] ?? '', style: const TextStyle(
                    fontFamily: 'Nunito', fontSize: 11, color: Colors.white70)),
              ],
            ),
            actions: [
              // ✅ Indicateur de dernière mise à jour
              if (_derniereMaj != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Center(
                    child: Text(
                      '${_t(langue, 'maj')} ${_formatHeure(_derniereMaj!.toIso8601String())}',
                      style: const TextStyle(fontSize: 10, color: Colors.white54),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _charger,
                tooltip: 'Actualiser',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppTheme.orange,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                  fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 12),
              tabs: [
                Tab(text: _t(langue, 'vue_ensemble')),
                Tab(text: '${_t(langue, 'membres')} (${_membres.length})'),
                Tab(text: _t(langue, 'paiements')),
                Tab(text: _t(langue, 'securite')),
                Tab(text: _t(langue, 'regles')),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildVueEnsemble(enRetard, taux, solde, montantCollecte,
                joursRestants, pct, membresRecus, langue, isSmall),
            _buildMembres(langue, isSmall),
            _buildPaiements(aCollecter, taux, langue, isSmall),
            _buildSecurite(langue, isSmall),
            _buildRegles(langue, isSmall),
          ],
        ),
      ),
    );
  }

  // ── VUE ENSEMBLE ─────────────────────────────────────
  Widget _buildVueEnsemble(int enRetard, int taux, double solde,
      double montantCollecte, int joursRestants, double pct,
      int membresRecus, String langue, bool isSmall) {
    return RefreshIndicator(
      color: AppTheme.vert,
      onRefresh: _charger,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (enRetard > 0)
              _buildAlerte('$enRetard membre(s) en retard',
                  AppTheme.rouge, Icons.warning_rounded),
            if (_demandes.isNotEmpty)
              _buildAlerte('${_demandes.length} demande(s) en attente',
                  AppTheme.orange, Icons.person_add_outlined),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10, mainAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                _statCard('${_membres.length}/${_tontine['nombre_membres'] ?? 0}',
                    _t(langue, 'membres_actifs'), Icons.groups_outlined,
                    AppTheme.vert, isSmall),
                _statCard(
                    solde >= 1000 ? '${(solde / 1000).toStringAsFixed(0)}k F'
                        : '${solde.toStringAsFixed(0)} F',
                    _t(langue, 'solde'), Icons.account_balance_wallet_outlined,
                    AppTheme.vertFonce, isSmall),
                _statCard('$joursRestants j', _t(langue, 'prochain_tour'),
                    Icons.timer_outlined,
                    joursRestants <= 3 ? AppTheme.rouge : AppTheme.orange, isSmall),
                _statCard('$taux%', _t(langue, 'taux_paiement'),
                    Icons.pie_chart_outline,
                    taux >= 80 ? AppTheme.vert : AppTheme.orange, isSmall),
              ],
            ),

            const SizedBox(height: 16),
            _sectionTitre(_t(langue, 'progression')),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: _cardDeco(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$membresRecus/${_membres.length} tours effectues',
                          style: const TextStyle(fontFamily: 'Nunito',
                              fontSize: 13, color: AppTheme.grisTexte)),
                      Text('${(pct * 100).toInt()}%',
                          style: const TextStyle(fontFamily: 'Nunito',
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: AppTheme.vert)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      backgroundColor: AppTheme.vertClair,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.vert),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, children: [
                    _infoChip('Debut : ${_formatDate(_tontine['date_debut']?.toString())}'),
                    _infoChip('Fin : ${_formatDate(_tontine['date_fin']?.toString())}'),
                    _infoChip(_tontine['periodicite']?.toString().replaceAll('_', ' ') ?? ''),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 16),
            _sectionTitre(_t(langue, 'activite')),
            Container(
              decoration: _cardDeco(),
              child: Column(
                children: _activite.isEmpty
                    ? [const Padding(padding: EdgeInsets.all(16),
                        child: Text('Aucune activite', style: TextStyle(
                            fontFamily: 'Nunito', color: AppTheme.grisTexte)))]
                    : _activite.map((a) {
                        final isPaye = a['statut'] == 'paye';
                        final isRetard = a['statut'] == 'en_retard';
                        final couleur = isPaye ? AppTheme.vert
                            : isRetard ? AppTheme.rouge : AppTheme.grisTexte;
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            isPaye ? Icons.check_circle_outline
                                : isRetard ? Icons.warning_amber_rounded
                                : Icons.radio_button_unchecked,
                            color: couleur, size: 20),
                          title: Text('${a['prenom'] ?? ''} ${a['nom'] ?? ''}',
                              style: const TextStyle(fontFamily: 'Nunito', fontSize: 13)),
                          subtitle: Text(_formatDate(a['date_echeance']?.toString()),
                              style: const TextStyle(fontFamily: 'Nunito', fontSize: 11)),
                          trailing: Text('${a['montant']} F',
                              style: TextStyle(fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w700, fontSize: 13,
                                  color: couleur)),
                        );
                      }).toList(),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: AppTheme.fond,
        borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: const TextStyle(fontFamily: 'Nunito',
        fontSize: 11, color: AppTheme.grisTexte)),
  );

  // ── MEMBRES ──────────────────────────────────────────
  Widget _buildMembres(String langue, bool isSmall) {
    return RefreshIndicator(
      color: AppTheme.vert,
      onRefresh: _charger,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_demandes.isNotEmpty) ...[
              _sectionTitre(_t(langue, 'demandes')),
              ..._demandes.map((d) => _buildCarteDemande(d, langue, isSmall)),
              const SizedBox(height: 16),
            ],
            _sectionTitre('${_t(langue, 'membres_actifs')} (${_membres.length})'),
            ..._membres.map((m) => _buildCarteMembre(m, langue, isSmall)),
            const SizedBox(height: 16),
            _sectionTitre(_t(langue, 'ordre_rotation')),
            Container(
              decoration: _cardDeco(),
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8, runSpacing: 8,
                children: _membres.asMap().entries.map((e) {
                  final i = e.key;
                  final m = e.value;
                  final aRecu = m['a_recu'] == true;
                  final pos = m['position_rotation'] as int? ?? i + 1;
                  final prenom = m['prenom']?.toString() ?? '?';
                  final nom = m['nom']?.toString() ?? '';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: aRecu ? AppTheme.vertClair : AppTheme.grisClair,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: aRecu ? AppTheme.vert : AppTheme.grisTexte,
                          width: aRecu ? 1.5 : 0.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Tour $pos', style: TextStyle(fontFamily: 'Nunito',
                            fontSize: 9,
                            color: aRecu ? AppTheme.vertFonce : AppTheme.grisTexte)),
                        Text(
                          '${prenom.isNotEmpty ? prenom[0] : '?'}${nom.isNotEmpty ? nom[0] : ''}${aRecu ? ' v' : ''}',
                          style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: aRecu ? AppTheme.vert : AppTheme.texte),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCarteMembre(Map<String, dynamic> m, String langue, bool isSmall) {
    final score = int.tryParse(m['score_fiabilite']?.toString() ?? '100') ?? 100;
    final prenom = m['prenom']?.toString() ?? '?';
    final nom = m['nom']?.toString() ?? '';
    final membreId = m['id']?.toString() ?? '';
    final joursRetard = int.tryParse(m['jours_retard']?.toString() ?? '0') ?? 0;
    final enRetard = joursRetard > 0;
    final initiales = '${prenom.isNotEmpty ? prenom[0] : '?'}${nom.isNotEmpty ? nom[0] : ''}';
    final nbOk = int.tryParse(m['nb_paiements_ok']?.toString() ?? '0') ?? 0;
    final nbRetards = int.tryParse(m['nb_retards']?.toString() ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(isSmall ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: enRetard ? AppTheme.rouge.withOpacity(0.3) : const Color(0xFFE8E8E5),
            width: enRetard ? 1.5 : 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: isSmall ? 18 : 20,
                backgroundColor: enRetard
                    ? AppTheme.rouge.withOpacity(0.15) : AppTheme.vertClair,
                child: Text(initiales, style: TextStyle(fontFamily: 'Nunito',
                    fontSize: isSmall ? 12 : 14, fontWeight: FontWeight.w700,
                    color: enRetard ? AppTheme.rouge : AppTheme.vertFonce)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$prenom $nom', style: TextStyle(fontFamily: 'Nunito',
                        fontSize: isSmall ? 13 : 14, fontWeight: FontWeight.w700)),
                    Text(m['telephone']?.toString() ?? '',
                        style: const TextStyle(fontFamily: 'Nunito',
                            fontSize: 11, color: AppTheme.grisTexte)),
                    // Stats paiements
                    Text('$nbOk payes · $nbRetards retards',
                        style: TextStyle(fontFamily: 'Nunito', fontSize: 10,
                            color: nbRetards > 0 ? AppTheme.rouge : AppTheme.grisTexte)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$score%', style: TextStyle(fontFamily: 'Nunito',
                      fontSize: isSmall ? 14 : 16, fontWeight: FontWeight.w700,
                      color: _scoreColor(score))),
                  if (enRetard)
                    Text('$joursRetard j retard', style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 10, color: AppTheme.rouge)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (score / 100).clamp(0.0, 1.0),
              backgroundColor: AppTheme.grisClair,
              valueColor: AlwaysStoppedAnimation<Color>(_scoreColor(score)),
              minHeight: 4,
            ),
          ),
          if (enRetard) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _relancerMembre(membreId, prenom),
                    icon: const Icon(Icons.notifications_outlined, size: 16),
                    label: Text(_t(langue, 'relancer'),
                        style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.orange,
                        side: const BorderSide(color: AppTheme.orange),
                        padding: const EdgeInsets.symmetric(vertical: 6)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exclureMembre(membreId, prenom),
                    icon: const Icon(Icons.person_remove_outlined, size: 16),
                    label: Text(_t(langue, 'exclure'),
                        style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.rouge,
                        side: const BorderSide(color: AppTheme.rouge),
                        padding: const EdgeInsets.symmetric(vertical: 6)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCarteDemande(Map<String, dynamic> d, String langue, bool isSmall) {
    final adhesionId = d['id']?.toString() ?? '';
    final prenom = d['prenom']?.toString() ?? '?';
    final nom = d['nom']?.toString() ?? '';
    final score = int.tryParse(d['score_fiabilite']?.toString() ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(isSmall ? 12 : 14),
      decoration: BoxDecoration(
        color: AppTheme.orangeClair,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.orange.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.orange.withOpacity(0.2),
                child: Text(prenom.isNotEmpty ? prenom[0] : '?',
                    style: const TextStyle(fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700, color: AppTheme.orangeFonce)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$prenom $nom', style: const TextStyle(
                        fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(d['telephone']?.toString() ?? '',
                        style: const TextStyle(fontFamily: 'Nunito',
                            fontSize: 11, color: AppTheme.grisTexte)),
                    if (score > 0)
                      Text('Score : $score%', style: TextStyle(
                          fontFamily: 'Nunito', fontSize: 11,
                          color: _scoreColor(score), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _accepterMembre(adhesionId),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(_t(langue, 'accepter')),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.vert),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _refuserMembre(adhesionId),
                  icon: const Icon(Icons.close, size: 16),
                  label: Text(_t(langue, 'refuser')),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.rouge,
                      side: const BorderSide(color: AppTheme.rouge)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── PAIEMENTS ────────────────────────────────────────
  Widget _buildPaiements(double aCollecter, int taux,
      String langue, bool isSmall) {
    final payees = int.tryParse(_stats['total_payes']?.toString() ?? '0') ?? 0;
    final enRetard = int.tryParse(_stats['total_retards']?.toString() ?? '0') ?? 0;
    final enAttente = _cotisations
        .where((c) => c['statut'] == 'en_attente' && c['capture_url'] != null)
        .toList();

    return RefreshIndicator(
      color: AppTheme.vert,
      onRefresh: _charger,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _statCard('$payees', 'Payes',
                    Icons.check_circle_outline, AppTheme.vert, isSmall)),
                const SizedBox(width: 10),
                Expanded(child: _statCard('$enRetard', _t(langue, 'en_retard'),
                    Icons.warning_outlined, AppTheme.rouge, isSmall)),
                const SizedBox(width: 10),
                Expanded(child: _statCard(
                    aCollecter >= 1000
                        ? '${(aCollecter / 1000).toStringAsFixed(0)}k F'
                        : '${aCollecter.toStringAsFixed(0)} F',
                    _t(langue, 'a_collecter'), Icons.attach_money,
                    AppTheme.orange, isSmall)),
              ],
            ),
            const SizedBox(height: 16),
            if (enAttente.isNotEmpty) ...[
              _sectionTitre(_t(langue, 'valider_paiement')),
              ...enAttente.map((c) => _buildCarteValidation(c, langue, isSmall)),
              const SizedBox(height: 16),
            ],
            _sectionTitre(_t(langue, 'historique')),
            Container(
              decoration: _cardDeco(),
              child: Column(
                children: _cotisations.isEmpty
                    ? [const Padding(padding: EdgeInsets.all(16),
                        child: Text('Aucun paiement', style: TextStyle(
                            fontFamily: 'Nunito', color: AppTheme.grisTexte)))]
                    : _cotisations.map((c) {
                        final isPaye = c['statut'] == 'paye';
                        final isRetard = c['statut'] == 'en_retard';
                        final couleur = isPaye ? AppTheme.vert
                            : isRetard ? AppTheme.rouge : AppTheme.grisTexte;
                        return Column(children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Icon(isPaye ? Icons.check_circle
                                    : isRetard ? Icons.warning_rounded
                                    : Icons.radio_button_unchecked,
                                    color: couleur, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${c['prenom'] ?? ''} ${c['nom'] ?? ''}',
                                          style: const TextStyle(fontFamily: 'Nunito',
                                              fontSize: 13, fontWeight: FontWeight.w600)),
                                      Text(_formatDate(c['date_echeance']?.toString()),
                                          style: const TextStyle(fontFamily: 'Nunito',
                                              fontSize: 11, color: AppTheme.grisTexte)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${c['montant']} F',
                                        style: TextStyle(fontFamily: 'Nunito',
                                            fontSize: 13, fontWeight: FontWeight.w700,
                                            color: couleur)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: couleur.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6)),
                                      child: Text(
                                        isPaye ? 'Paye' : isRetard ? 'Retard' : 'En attente',
                                        style: TextStyle(fontFamily: 'Nunito',
                                            fontSize: 9, fontWeight: FontWeight.w700,
                                            color: couleur)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE8E8E5)),
                        ]);
                      }).toList(),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCarteValidation(Map<String, dynamic> c,
      String langue, bool isSmall) {
    final cotId = c['id']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(isSmall ? 12 : 14),
      decoration: BoxDecoration(
        color: AppTheme.vertClair,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.vert.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${c['prenom'] ?? ''} ${c['nom'] ?? ''} — ${c['montant']} F CFA',
              style: const TextStyle(fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 4),
          Text('Capture envoyee · ${_formatDate(c['date_paiement']?.toString())}',
              style: const TextStyle(fontFamily: 'Nunito',
                  fontSize: 11, color: AppTheme.grisTexte)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _validerPaiement(cotId),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(_t(langue, 'valider')),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.vert),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.close, size: 16),
                  label: Text(_t(langue, 'rejeter')),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.rouge,
                      side: const BorderSide(color: AppTheme.rouge)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── SECURITE ─────────────────────────────────────────
  Widget _buildSecurite(String langue, bool isSmall) {
    final membresKycOk = _membres
        .where((m) => m['kyc_valide'] == true || m['est_verifie'] == true)
        .length;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmall ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.vertClair,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.vert.withOpacity(0.3), width: 1),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_outlined, color: AppTheme.vert, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tontine securisee', style: TextStyle(
                          fontFamily: 'Nunito', fontWeight: FontWeight.w700,
                          fontSize: 14, color: AppTheme.vertFonce)),
                      Text('Supervision admin TontiLigdi active', style: TextStyle(
                          fontFamily: 'Nunito', fontSize: 12, color: AppTheme.vertFonce)),
                    ],
                  ),
                ),
                Icon(Icons.check_circle, color: AppTheme.vert, size: 24),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitre(_t(langue, 'securite_titre')),
          Container(
            decoration: _cardDeco(),
            child: Column(children: [
              _secItem('KYC organisateur verifie', true, Icons.badge_outlined),
              _secItem('KYC membres ($membresKycOk/${_membres.length})',
                  membresKycOk == _membres.length, Icons.people_outlined),
              _secItem('Validation captures paiement', true, Icons.photo_outlined),
              _secItem('Rappels automatiques 30j', true, Icons.notifications_outlined),
              _secItem('Vote retrait requis', true, Icons.how_to_vote_outlined),
              _secItem('Historique complet trace', true, Icons.history_outlined),
              _secItem('Supervision admin TontiLigdi', true,
                  Icons.admin_panel_settings_outlined),
              _secItem('Score fiabilite membres', true, Icons.star_outline_rounded),
              _secItem('Mise a jour auto (30s)', true, Icons.sync_outlined),
            ]),
          ),
          const SizedBox(height: 16),
          _sectionTitre('Score fiabilite membres'),
          Container(
            decoration: _cardDeco(),
            padding: const EdgeInsets.all(14),
            child: _membres.isEmpty
                ? const Text('Aucun membre', style: TextStyle(
                    fontFamily: 'Nunito', color: AppTheme.grisTexte))
                : Column(
                    children: _membres.map((m) {
                      final score = int.tryParse(
                          m['score_fiabilite']?.toString() ?? '100') ?? 100;
                      final prenom = m['prenom']?.toString() ?? '?';
                      final nom = m['nom']?.toString() ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            SizedBox(width: 90,
                              child: Text(
                                '$prenom ${nom.isNotEmpty ? '${nom[0]}.' : ''}',
                                style: const TextStyle(fontFamily: 'Nunito', fontSize: 12),
                                overflow: TextOverflow.ellipsis)),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (score / 100).clamp(0.0, 1.0),
                                  backgroundColor: AppTheme.grisClair,
                                  valueColor: AlwaysStoppedAnimation<Color>(_scoreColor(score)),
                                  minHeight: 6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('$score%', style: TextStyle(fontFamily: 'Nunito',
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: _scoreColor(score))),
                          ],
                        ),
                      );
                    }).toList()),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _secItem(String label, bool actif, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(children: [
      Icon(icon, size: 18, color: actif ? AppTheme.vert : AppTheme.grisTexte),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: const TextStyle(
          fontFamily: 'Nunito', fontSize: 13, color: AppTheme.texte))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: actif ? AppTheme.vert.withOpacity(0.1) : AppTheme.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(actif ? 'Actif' : 'En attente', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w700,
            color: actif ? AppTheme.vert : AppTheme.orange)),
      ),
    ]),
  );

  // ── REGLES ───────────────────────────────────────────
  Widget _buildRegles(String langue, bool isSmall) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmall ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitre(_t(langue, 'regles_titre')),
          Container(
            decoration: _cardDeco(),
            child: Column(children: [
              _regleLigne('Retard tolere', '3 jours max', Icons.timer_outlined),
              _regleLigne('Penalite retard', '500 F CFA/jour', Icons.money_off_outlined),
              _regleLigne('Exclusion automatique', 'Apres 10 jours', Icons.person_off_outlined),
              _regleLigne('Vote retrait requis', '60% des membres', Icons.how_to_vote_outlined),
              _regleLigne('Litige Admin', 'Automatique', Icons.gavel_outlined),
              _regleLigne('Montant cotisation',
                  '${_tontine['montant_cotisation'] ?? '-'} F CFA', Icons.payments_outlined),
              _regleLigne('Frequence',
                  _tontine['periodicite']?.toString().replaceAll('_', ' ') ?? '-',
                  Icons.calendar_today_outlined),
              _regleLigne('Ordre rotation',
                  _tontine['ordre_rotation']?.toString().replaceAll('_', ' ') ?? '-',
                  Icons.shuffle_outlined),
            ]),
          ),
          const SizedBox(height: 16),
          _sectionTitre('Charte signee par les membres'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.fond,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8E8E5), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('En rejoignant cette tontine, chaque membre s engage a :',
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                ...[
                  'Payer sa cotisation dans les delais impartis',
                  'Respecter les regles de la tontine',
                  'Accepter les decisions prises a la majorite',
                  'Signaler tout probleme a l organisateur',
                  'Ne pas retirer ses fonds sans vote des membres',
                  'Accepter l arbitrage de TontiLigdi en cas de litige',
                ].map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(
                          color: AppTheme.vert, fontWeight: FontWeight.w700)),
                      Expanded(child: Text(r, style: const TextStyle(
                          fontFamily: 'Nunito', fontSize: 12,
                          color: AppTheme.grisTexte))),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _regleLigne(String label, String valeur, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(children: [
      Icon(icon, size: 18, color: AppTheme.grisTexte),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: const TextStyle(
          fontFamily: 'Nunito', fontSize: 13, color: AppTheme.grisTexte))),
      Text(valeur, style: const TextStyle(fontFamily: 'Nunito',
          fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.texte)),
    ]),
  );
}