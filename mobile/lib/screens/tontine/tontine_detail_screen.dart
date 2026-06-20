import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/vocal_service.dart';

class TontineDetailScreen extends StatefulWidget {
  final String id;
  const TontineDetailScreen({super.key, required this.id});

  @override
  State<TontineDetailScreen> createState() => _TontineDetailScreenState();
}

class _TontineDetailScreenState extends State<TontineDetailScreen> {
  Map<String, dynamic>? _tontine;
  bool _chargement = true;
  final VocalService _vocal = VocalService();

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final data = await ApiService.getTontine(widget.id);
      setState(() { _tontine = data; _chargement = false; });
    } catch (e) {
      setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.vert)),
      );
    }

    if (_tontine == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppTheme.vert,
            foregroundColor: Colors.white, title: const Text('Tontine')),
        body: const Center(child: Text('Tontine non trouvée')),
      );
    }

    final t = _tontine!;
    final membres = (t['membres'] as List?) ?? [];
    final totalMembres = membres.length;
    final joursRestants = t['jours_restants'] as int? ?? 0;
    final couleur = joursRestants <= 1 ? AppTheme.rouge
        : joursRestants <= 2 ? AppTheme.orange : AppTheme.vert;

    return Scaffold(
      backgroundColor: AppTheme.fond,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppTheme.vert,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: Colors.white70),
                onPressed: () => _vocal.parler(
                    'Tontine ${t['nom']}. $totalMembres membres. Cotisation ${t['montant_cotisation']} francs.'),
              ),
              IconButton(
                icon: const Icon(Icons.people_outline, color: Colors.white),
                onPressed: () => context.push('/tontine/${widget.id}/membres'),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(t['nom'] ?? '',
                  style: const TextStyle(fontFamily: 'Nunito',
                      fontSize: 16, fontWeight: FontWeight.w700)),
              background: Container(color: AppTheme.vert,
                child: Center(
                  child: Text(_typeEmoji(t['type']),
                      style: const TextStyle(fontSize: 64)),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCards(t, joursRestants, couleur, totalMembres),
                  const SizedBox(height: 16),
                  _buildProgression(t, totalMembres),
                  const SizedBox(height: 16),
                  _buildMembres(membres),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(t),
    );
  }

  Widget _buildStatCards(Map t, int jours, Color couleur, int totalMembres) {
    return Row(
      children: [
        Expanded(child: _statCard(
          '$jours jours', 'Prochain tour',
          couleur.withOpacity(0.1), couleur,
          Icons.timer_outlined,
        )),
        const SizedBox(width: 10),
        Expanded(child: _statCard(
          '${t['montant_cotisation']} F',
          _periodiciteLabel(t['periodicite']),
          AppTheme.vertClair, AppTheme.vert,
          Icons.payments_outlined,
        )),
      ],
    );
  }

  Widget _statCard(String valeur, String label, Color bg, Color couleur, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: couleur, size: 22),
          const SizedBox(height: 6),
          Text(valeur, style: TextStyle(
            fontFamily: 'Nunito', fontSize: 16,
            fontWeight: FontWeight.w700, color: couleur,
          )),
          Text(label, style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 11, color: AppTheme.grisTexte,
          )),
        ],
      ),
    );
  }

  Widget _buildProgression(Map t, int totalMembres) {
    final membresRecus = (t['membres'] as List? ?? [])
        .where((m) => m['a_recu'] == true).length;
    final pct = totalMembres > 0 ? membresRecus / totalMembres : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E5), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progression', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 14,
            fontWeight: FontWeight.w700, color: AppTheme.texte,
          )),
          const SizedBox(height: 12),
          Row(
            children: [
              CircularPercentIndicator(
                radius: 36,
                lineWidth: 6,
                percent: pct.clamp(0.0, 1.0),
                center: Text('${(pct * 100).toInt()}%',
                    style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 12,
                      fontWeight: FontWeight.w700, color: AppTheme.vert,
                    )),
                progressColor: AppTheme.vert,
                backgroundColor: AppTheme.vertClair,
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$membresRecus sur $totalMembres membres ont reçu',
                        style: const TextStyle(
                          fontFamily: 'Nunito', fontSize: 13,
                          color: AppTheme.grisTexte,
                        )),
                    const SizedBox(height: 4),
                    if (t['prochain_beneficiaire'] != null)
                      Text(
                        'Prochain : ${t['prochain_beneficiaire']['prenom']} ${t['prochain_beneficiaire']['nom']}',
                        style: const TextStyle(
                          fontFamily: 'Nunito', fontSize: 13,
                          fontWeight: FontWeight.w600, color: AppTheme.vert,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembres(List membres) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Membres', style: TextStyle(
              fontFamily: 'Nunito', fontSize: 16,
              fontWeight: FontWeight.w700, color: AppTheme.texte,
            )),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_add_outlined,
                  size: 16, color: AppTheme.vert),
              label: const Text('Inviter',
                  style: TextStyle(fontFamily: 'Nunito', color: AppTheme.vert)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E8E5), width: 0.5),
          ),
          child: membres.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('Aucun membre pour l\'instant',
                      style: TextStyle(color: AppTheme.grisTexte))),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: membres.length,
                  separatorBuilder: (_, __) => const Divider(height: 0.5),
                  itemBuilder: (ctx, i) {
                    final m = membres[i];
                    final aRecu = m['a_recu'] == true;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: aRecu ? AppTheme.vert : AppTheme.grisClair,
                        child: Text(
                          '${m['prenom']?[0] ?? '?'}${m['nom']?[0] ?? ''}',
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: aRecu ? Colors.white : AppTheme.grisTexte,
                          ),
                        ),
                      ),
                      title: Text('${m['prenom']} ${m['nom']}',
                          style: const TextStyle(
                            fontFamily: 'Nunito', fontSize: 14,
                            fontWeight: FontWeight.w600,
                          )),
                      subtitle: Text('Tour ${m['position_rotation']}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.grisTexte)),
                      trailing: aRecu
                          ? const Icon(Icons.check_circle, color: AppTheme.vert)
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.orangeClair,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${m['score_fiabilite'] ?? 100}%',
                                  style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600,
                                    color: AppTheme.orangeFonce,
                                  )),
                            ),
                    );
                  },
                ),
        ),
      ],
    );
  }

Widget _buildBottomBar(Map t) {
  return Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Color(0xFFE8E8E5), width: 0.5)),
    ),
    child: FutureBuilder<Map<String, dynamic>?>(
      future: ApiService.getCotisationEnCours(t['id']),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.vert),
          );
        }
        final cotisation = snapshot.data;
        if (cotisation == null) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.vertClair,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: AppTheme.vert, size: 20),
                SizedBox(width: 8),
                Text(
                  'Toutes vos cotisations sont à jour !',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.vertFonce,
                  ),
                ),
              ],
            ),
          );
        }
        final montant = cotisation['montant']?.toString() ?? '0';
        final dateEcheance = cotisation['date_echeance'] != null
            ? DateTime.parse(cotisation['date_echeance'])
            : null;
        final joursRestants = dateEcheance != null
            ? dateEcheance.difference(DateTime.now()).inDays
            : 0;
        final couleur = joursRestants <= 1
            ? AppTheme.rouge
            : joursRestants <= 2
                ? AppTheme.orange
                : AppTheme.vert;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (joursRestants <= 2)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: couleur.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, color: couleur, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      joursRestants <= 0
                          ? 'Cotisation en retard !'
                          : 'Due dans $joursRestants jour(s)',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: couleur,
                      ),
                    ),
                  ],
                ),
              ),
            ElevatedButton.icon(
              onPressed: () => context.push('/paiement/${cotisation['id']}'),
              icon: const Icon(Icons.payments_outlined),
              label: Text('Payer $montant F CFA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: couleur,
              ),
            ),
          ],
        );
      },
    ),
  );
}
  String _typeEmoji(String? type) {
    const emojis = {
      'argent_liquide': '💰',
      'objet': '📦',
      'caisse_fixe': '🏦',
      'evenementielle': '🎉',
    };
    return emojis[type] ?? '💰';
  }

  String _periodiciteLabel(String? p) {
    const labels = {
      'quotidien': 'par jour',
      '2_jours': 'tous les 2j',
      'hebdomadaire': 'par semaine',
      '2_semaines': 'par 2 sem.',
      'mensuel': 'par mois',
    };
    return labels[p] ?? p ?? '';
  }
}