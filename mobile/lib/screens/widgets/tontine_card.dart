import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../utils/app_theme.dart';

class TontineCard extends StatelessWidget {
  final Map<String, dynamic> tontine;
  final VoidCallback onTap;

  final bool estOrganisateur;
  const TontineCard({super.key, required this.tontine, required this.onTap, this.estOrganisateur = false});

  @override
  Widget build(BuildContext context) {
    final joursRestants = tontine['jours_restants'] as int? ?? 0;
    final totalMembres = int.tryParse(tontine['total_membres']?.toString() ?? '1') ?? 1;
    final membresPayes = int.tryParse(tontine['membres_payes_periode_actuelle']?.toString() ?? '0') ?? 0;
    final pourcentage = totalMembres > 0 ? membresPayes / totalMembres : 0.0;
    final type = tontine['type'] as String? ?? 'argent_liquide';

    final couleurUrgence = joursRestants <= 1
        ? AppTheme.rouge
        : joursRestants <= 2
            ? AppTheme.orange
            : AppTheme.vert;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: joursRestants <= 2 ? couleurUrgence.withOpacity(0.4) : const Color(0xFFE8E8E5),
            width: joursRestants <= 2 ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIcon(type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tontine['nom'] ?? 'Tontine',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.texte,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$totalMembres membres · ${_formatMontant(tontine['montant_cotisation'])} / ${_periodiciteLabel(tontine['periodicite'])}',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: AppTheme.grisTexte,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCompteARebours(joursRestants, couleurUrgence),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pourcentage,
                backgroundColor: AppTheme.grisClair,
                valueColor: AlwaysStoppedAnimation<Color>(
                  joursRestants <= 2 ? couleurUrgence : AppTheme.vert,
                ),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMembresAvatars(totalMembres, membresPayes),
                _buildBadgeTour(tontine),
              ],
            ),
            if (estOrganisateur) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/tontine/${tontine["id"]}/dashboard'),
                  icon: const Icon(Icons.dashboard_outlined, size: 16),
                  label: const Text('Dashboard organisateur',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.vertFonce,
                    side: const BorderSide(color: AppTheme.vert),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(String type) {
    final emojis = {
      'argent_liquide': '💰',
      'objet': '📦',
      'caisse_fixe': '🏦',
      'evenementielle': '🎉',
    };
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppTheme.vertClair,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(emojis[type] ?? '💰', style: const TextStyle(fontSize: 22)),
      ),
    );
  }

  Widget _buildCompteARebours(int jours, Color couleur) {
    return CircularPercentIndicator(
      radius: 28,
      lineWidth: 4,
      percent: jours <= 30 ? (30 - jours) / 30 : 0.0,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$jours',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: couleur,
            ),
          ),
          Text(
            'j',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 9,
              color: couleur,
            ),
          ),
        ],
      ),
      progressColor: couleur,
      backgroundColor: couleur.withOpacity(0.15),
      circularStrokeCap: CircularStrokeCap.round,
      animation: true,
      animationDuration: 800,
    );
  }

  Widget _buildMembresAvatars(int total, int payes) {
    final affichage = total > 6 ? 5 : total;
    return Row(
      children: [
        ...List.generate(affichage, (i) {
          final aPaye = i < payes;
          return Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: aPaye ? AppTheme.vert : AppTheme.grisClair,
            ),
            child: Center(
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: aPaye ? Colors.white : AppTheme.grisTexte,
                ),
              ),
            ),
          );
        }),
        if (total > 6)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.grisClair,
            ),
            child: Center(
              child: Text(
                '+${total - 5}',
                style: const TextStyle(fontSize: 7, color: AppTheme.grisTexte, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        const SizedBox(width: 6),
        Text(
          '$payes/$total payés',
          style: const TextStyle(fontSize: 11, color: AppTheme.grisTexte, fontFamily: 'Nunito'),
        ),
      ],
    );
  }

  Widget _buildBadgeTour(Map<String, dynamic> tontine) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.vertClair,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Tour ${tontine['position_rotation'] ?? 1}/${tontine['nombre_membres'] ?? 1}',
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.vertFonce,
        ),
      ),
    );
  }

  String _formatMontant(dynamic montant) {
    if (montant == null) return '0F';
    final val = double.tryParse(montant.toString()) ?? 0;
    if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(val % 1000 == 0 ? 0 : 1)}k F';
    }
    return '${val.toStringAsFixed(0)}F';
  }

  String _periodiciteLabel(String? periodicite) {
    const labels = {
      'quotidien': 'jour',
      '2_jours': '2j',
      'hebdomadaire': 'semaine',
      '2_semaines': '2 sem.',
      'mensuel': 'mois',
    };
    return labels[periodicite] ?? periodicite ?? '';
  }
}
