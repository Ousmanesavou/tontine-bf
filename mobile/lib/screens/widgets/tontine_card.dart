import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';

class TontineCard extends StatelessWidget {
  final Map<String, dynamic> tontine;
  final VoidCallback onTap;
  final bool estOrganisateur;

  const TontineCard({
    super.key,
    required this.tontine,
    required this.onTap,
    this.estOrganisateur = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = tontine;
    final sw = MediaQuery.of(context).size.width;
    final nom = t['nom']?.toString() ?? 'Tontine';
    final montant = double.tryParse(t['montant_cotisation']?.toString() ?? '0') ?? 0;
    final periodicite = _periodiciteLabel(t['periodicite']?.toString());
    final totalMembres = int.tryParse(t['nombre_membres']?.toString() ?? '0') ?? 0;
    final membres = (t['membres'] as List?)?.length ?? 0;
    final joursRestants = t['jours_restants'] as int? ?? 0;
    final membresPayes = int.tryParse(t['membres_payes']?.toString() ?? '0') ?? 0;
    final tourActuel = int.tryParse(t['tour_actuel']?.toString() ?? '1') ?? 1;
    final totalTours = totalMembres > 0 ? totalMembres : 1;
    final statut = t['statut']?.toString() ?? 'actif';
    final estEnRetard = t['cotisation_en_retard'] == true;
    final pct = totalTours > 0 ? (tourActuel - 1) / totalTours : 0.0;

    // Couleur selon statut
    final couleurBord = estEnRetard
        ? AppTheme.rouge
        : statut == 'termine'
            ? AppTheme.grisTexte
            : AppTheme.vert;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: estEnRetard
                ? AppTheme.rouge.withOpacity(0.4)
                : const Color(0xFFE8E8E5),
            width: estEnRetard ? 1.5 : 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── HEADER ──────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Icône tontine
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: couleurBord.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _typeEmoji(t['type']?.toString()),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Infos principales
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom complet sans troncature
                        Text(
                          nom,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.texte,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        // Montant + periodicite
                        Text(
                          '${_formatMontant(montant)} F · $periodicite',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: AppTheme.grisTexte,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Membres
                        Row(children: [
                          Icon(Icons.people_outline,
                              size: 12, color: AppTheme.grisTexte),
                          const SizedBox(width: 4),
                          Text(
                            '$membres/$totalMembres membres',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              color: AppTheme.grisTexte,
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),

                  // Timer circulaire
                  _buildTimer(joursRestants, pct, couleurBord),
                ],
              ),
            ),

            // ── DIVIDER ─────────────────────────────
            const Divider(height: 1, color: Color(0xFFE8E8E5)),

            // ── FOOTER ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  // Avatars membres payés
                  _buildMembresPayes(membresPayes, membres),
                  const Spacer(),
                  // Badge tour
                  _buildBadgeTour(tourActuel, totalTours, statut),
                ],
              ),
            ),

            // ── ALERTE RETARD ────────────────────────
            if (estEnRetard)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.rouge.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.rouge, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Cotisation en retard — Payez maintenant',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.rouge,
                    ),
                  ),
                ]),
              ),

            // ── BOUTON DASHBOARD ORGANISATEUR ────────
            if (estOrganisateur)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(
                        '/tontine/${t['id']}/dashboard'),
                    icon: const Icon(
                        Icons.dashboard_outlined, size: 16),
                    label: const Text('Dashboard organisateur',
                        style: TextStyle(
                            fontFamily: 'Nunito', fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.vertFonce,
                      side: const BorderSide(
                          color: AppTheme.vert, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildTimer(int jours, double pct, Color couleur) {
    final isUrgent = jours <= 3;
    return SizedBox(
      width: 52, height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            backgroundColor: couleur.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(couleur),
            strokeWidth: 3.5,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$jours',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: jours > 99 ? 10 : 14,
                  fontWeight: FontWeight.w700,
                  color: isUrgent ? AppTheme.rouge : AppTheme.texte,
                ),
              ),
              Text('j',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 9,
                      color: AppTheme.grisTexte)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembresPayes(int payes, int total) {
    return Row(children: [
      ...List.generate(payes.clamp(0, 3), (i) => Container(
        width: 20, height: 20,
        margin: EdgeInsets.only(left: i == 0 ? 0 : -6),
        decoration: BoxDecoration(
          color: AppTheme.vert,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: const Icon(Icons.check, size: 10, color: Colors.white),
      )),
      const SizedBox(width: 6),
      Text(
        '$payes/$total payés',
        style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            color: AppTheme.grisTexte),
      ),
    ]);
  }

  Widget _buildBadgeTour(int tourActuel, int totalTours, String statut) {
    final couleur = statut == 'termine'
        ? AppTheme.grisTexte
        : AppTheme.vert;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleur.withOpacity(0.3)),
      ),
      child: Text(
        statut == 'termine' ? 'Terminé' : 'Tour $tourActuel/$totalTours',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: couleur,
        ),
      ),
    );
  }

  String _formatMontant(double montant) {
    if (montant >= 1000000) {
      return '${(montant / 1000000).toStringAsFixed(1)}M';
    } else if (montant >= 1000) {
      return '${(montant / 1000).toStringAsFixed(0)}k';
    }
    return montant.toStringAsFixed(0);
  }

  String _periodiciteLabel(String? p) {
    switch (p) {
      case 'quotidien': return '/jour';
      case 'hebdomadaire': return '/sem.';
      case 'mensuel': return '/mois';
      case 'bimensuel': return '/2 sem.';
      case 'bimestriel': return '/2 mois';
      case 'trimestriel': return '/trim.';
      case 'tous_les_2_jours': return '/2j';
      default: return p ?? '';
    }
  }

  String _typeEmoji(String? type) {
    switch (type) {
      case 'epargne': return '💰';
      case 'investissement': return '📈';
      case 'urgence': return '🆘';
      case 'education': return '📚';
      case 'sante': return '🏥';
      case 'immobilier': return '🏠';
      case 'mariage': return '💍';
      case 'business': return '💼';
      default: return '🤝';
    }
  }
}
