import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../services/vocal_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final VocalService _vocal = VocalService();

  final List<Map<String, dynamic>> _notifications = [
    {
      'type': 'paiement',
      'titre': 'Paiement confirmé',
      'message': 'Fatima a payé sa cotisation pour la tontine Frigo Samsung.',
      'temps': 'Il y a 2 heures',
      'lu': false,
      'couleur': AppTheme.vert,
      'icon': Icons.check_circle_outline,
    },
    {
      'type': 'rappel',
      'titre': 'Rappel cotisation',
      'message': 'Votre cotisation de 15 000F pour "Salon complet" est due dans 2 jours.',
      'temps': 'Il y a 4 heures',
      'lu': false,
      'couleur': AppTheme.orange,
      'icon': Icons.timer_outlined,
    },
    {
      'type': 'tour',
      'titre': 'Bientôt votre tour !',
      'message': 'Vous serez le prochain bénéficiaire de la tontine Frigo Samsung.',
      'temps': 'Hier à 10:30',
      'lu': true,
      'couleur': AppTheme.vert,
      'icon': Icons.emoji_events_outlined,
    },
    {
      'type': 'membre',
      'titre': 'Nouveau membre',
      'message': 'Koumi Adama a rejoint votre tontine Caisse commune.',
      'temps': 'Hier à 08:15',
      'lu': true,
      'couleur': AppTheme.gris,
      'icon': Icons.person_add_outlined,
    },
    {
      'type': 'rapport',
      'titre': 'Rapport mensuel',
      'message': 'Votre rapport de mai est disponible. Taux de paiement : 95%.',
      'temps': 'Il y a 3 jours',
      'lu': true,
      'couleur': AppTheme.gris,
      'icon': Icons.bar_chart_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final nonLues = _notifications.where((n) => !n['lu']).length;

    return Scaffold(
      backgroundColor: AppTheme.fond,
      appBar: AppBar(
        backgroundColor: AppTheme.vert,
        foregroundColor: Colors.white,
        title: Text('Alertes${nonLues > 0 ? ' ($nonLues)' : ''}',
            style: const TextStyle(
                fontFamily: 'Nunito', color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: Colors.white70),
            onPressed: () => _vocal.parler(
                '$nonLues nouvelles alertes. Vérifiez vos cotisations.'),
          ),
          if (nonLues > 0)
            TextButton(
              onPressed: () => setState(() {
                for (var n in _notifications) n['lu'] = true;
              }),
              child: const Text('Tout lire',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white70,
                      fontSize: 13)),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEtatVide()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (ctx, i) => _buildCarteNotif(_notifications[i], i),
            ),
    );
  }

  Widget _buildCarteNotif(Map<String, dynamic> notif, int index) {
    final nonLu = !notif['lu'];

    return GestureDetector(
      onTap: () {
        setState(() => notif['lu'] = true);
        _vocal.parler(notif['message']);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: nonLu ? AppTheme.vertTresClair : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: nonLu
                ? AppTheme.vert.withOpacity(0.3)
                : const Color(0xFFE8E8E5),
            width: nonLu ? 1 : 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (notif['couleur'] as Color).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notif['icon'] as IconData,
                color: notif['couleur'] as Color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif['titre'],
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: nonLu
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: AppTheme.texte,
                          ),
                        ),
                      ),
                      if (nonLu)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.vert,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif['message'],
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: AppTheme.grisTexte,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_outlined,
                          size: 12, color: AppTheme.gris),
                      const SizedBox(width: 4),
                      Text(
                        notif['temps'],
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          color: AppTheme.gris,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _vocal.parler(notif['message']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.vertClair,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.volume_up_rounded,
                                  size: 12, color: AppTheme.vert),
                              SizedBox(width: 3),
                              Text('Écouter',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.vertFonce,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEtatVide() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🔔', style: TextStyle(fontSize: 56)),
          SizedBox(height: 16),
          Text('Aucune alerte',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.texte,
              )),
          SizedBox(height: 8),
          Text(
            'Vous recevrez ici toutes vos\nnotifications de tontine',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: AppTheme.grisTexte),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _vocal.stop();
    super.dispose();
  }
}