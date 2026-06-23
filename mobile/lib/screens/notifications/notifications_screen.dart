import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_theme.dart';
import '../../services/vocal_service.dart';
import '../../services/api_service.dart';
import '../../main.dart';

// ── TRADUCTIONS ───────────────────────────────────────
const Map<String, Map<String, String>> _tr = {
  'fr': {
    'titre': 'Alertes',
    'tout_lire': 'Tout lire',
    'ecouter': 'Écouter',
    'aucune': 'Aucune alerte',
    'aucune_desc': 'Vous recevrez ici toutes vos\nnotifications de tontine',
    'vocal': 'nouvelles alertes. Vérifiez vos cotisations.',
    'il_y_a': 'Il y a',
    'hier': 'Hier',
    'heures': 'heures',
    'heure': 'heure',
    'jours': 'jours',
    'jour': 'jour',
    'minutes': 'minutes',
    'maintenant': 'À l\'instant',
  },
  'en': {
    'titre': 'Alerts',
    'tout_lire': 'Mark all read',
    'ecouter': 'Listen',
    'aucune': 'No alerts',
    'aucune_desc': 'You will receive all your\ntontine notifications here',
    'vocal': 'new alerts. Check your contributions.',
    'il_y_a': 'ago',
    'hier': 'Yesterday',
    'heures': 'hours',
    'heure': 'hour',
    'jours': 'days',
    'jour': 'day',
    'minutes': 'minutes',
    'maintenant': 'Just now',
  },
  'mos': {
    'titre': 'Kõ-kaasã',
    'tout_lire': 'Karm fãa',
    'ecouter': 'Kelg',
    'aucune': 'Kõ-kaas ka be ye',
    'aucune_desc': 'F tontine kõ-kaasã lʋɩɩ ka',
    'vocal': 'kõ-kaasã wʋsgã. Ges f cotisations.',
    'il_y_a': 'Rasem',
    'hier': 'Zaabre',
    'heures': 'wʋkiri',
    'heure': 'wʋkiri',
    'jours': 'dãmba',
    'jour': 'dãmba',
    'minutes': 'miniti',
    'maintenant': 'Rũnna',
  },
  'bm': {
    'titre': 'Kibaru',
    'tout_lire': 'Bɛɛ kalan',
    'ecouter': 'Lamɛn',
    'aucune': 'Kibaru si be',
    'aucune_desc': 'I ka tontine kibaruye bɛ na yan',
    'vocal': 'kibaru kura. I ka sarali kɔlɔsi.',
    'il_y_a': 'Tuma min',
    'hier': 'Kunu',
    'heures': 'lɛrɛ',
    'heure': 'lɛrɛ',
    'jours': 'tile',
    'jour': 'tile',
    'minutes': 'miniti',
    'maintenant': 'Sisan',
  },
  'wo': {
    'titre': 'Xibaar yi',
    'tout_lire': 'Jàng lëpp',
    'ecouter': 'Dee',
    'aucune': 'Xibaar amul',
    'aucune_desc': 'Ay xibaar yu tontine dina ñëw fii',
    'vocal': 'xibaar yu bees. Xool sa cotisations.',
    'il_y_a': 'Ci kanam',
    'hier': 'Démb',
    'heures': 'waxtu',
    'heure': 'waxtu',
    'jours': 'fan',
    'jour': 'fan',
    'minutes': 'minit',
    'maintenant': 'Leegi',
  },
};

String _t(String langue, String key) {
  final lang = _tr[langue] ?? _tr['fr']!;
  return lang[key] ?? _tr['fr']![key] ?? key;
}

final notificationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    return await ApiService.getNotifications();
  } catch (e) {
    return [];
  }
});

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final VocalService _vocal = VocalService();
  final List<String> _notifLues = [];

  bool _estLue(Map<String, dynamic> notif) {
    return notif['lu'] == true ||
        _notifLues.contains(notif['id']?.toString());
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'paiement': return Icons.check_circle_outline;
      case 'rappel': return Icons.timer_outlined;
      case 'tour': return Icons.emoji_events_outlined;
      case 'membre': return Icons.person_add_outlined;
      case 'rapport': return Icons.bar_chart_outlined;
      case 'adhesion': return Icons.group_add_outlined;
      case 'retard': return Icons.warning_amber_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color _getCouleur(String type) {
    switch (type) {
      case 'paiement': return AppTheme.vert;
      case 'rappel': return AppTheme.orange;
      case 'tour': return AppTheme.vert;
      case 'retard': return AppTheme.rouge;
      case 'adhesion': return AppTheme.vert;
      default: return AppTheme.gris;
    }
  }

  String _formatTemps(String? dateStr, String langue) {
    if (dateStr == null) return _t(langue, 'maintenant');
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return _t(langue, 'maintenant');
      if (diff.inMinutes < 60) {
        return langue == 'en'
            ? '${diff.inMinutes} ${_t(langue, 'minutes')} ${_t(langue, 'il_y_a')}'
            : '${_t(langue, 'il_y_a')} ${diff.inMinutes} ${_t(langue, 'minutes')}';
      }
      if (diff.inHours < 24) {
        final h = diff.inHours;
        return langue == 'en'
            ? '$h ${h > 1 ? _t(langue, 'heures') : _t(langue, 'heure')} ${_t(langue, 'il_y_a')}'
            : '${_t(langue, 'il_y_a')} $h ${h > 1 ? _t(langue, 'heures') : _t(langue, 'heure')}';
      }
      if (diff.inDays == 1) return _t(langue, 'hier');
      final d = diff.inDays;
      return langue == 'en'
          ? '$d ${d > 1 ? _t(langue, 'jours') : _t(langue, 'jour')} ${_t(langue, 'il_y_a')}'
          : '${_t(langue, 'il_y_a')} $d ${d > 1 ? _t(langue, 'jours') : _t(langue, 'jour')}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _marquerLue(String? id) async {
    if (id == null) return;
    setState(() => _notifLues.add(id));
    try {
      await ApiService.marquerNotificationLue(id);
    } catch (_) {}
  }

  Future<void> _toutMarquerLu(List<Map<String, dynamic>> notifs) async {
    for (final n in notifs) {
      final id = n['id']?.toString();
      if (id != null) setState(() => _notifLues.add(id));
    }
    try {
      await ApiService.marquerToutesNotificationsLues();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final langue = ref.watch(langueProvider);
    final notifsAsync = ref.watch(notificationsProvider);
    final sw = MediaQuery.of(context).size.width;
    final isSmall = sw < 360;

    return Scaffold(
      backgroundColor: AppTheme.fond,
      appBar: AppBar(
        backgroundColor: AppTheme.vert,
        foregroundColor: Colors.white,
        title: notifsAsync.when(
          data: (notifs) {
            final nonLues = notifs.where((n) => !_estLue(n)).length;
            return Text(
              '${_t(langue, 'titre')}${nonLues > 0 ? ' ($nonLues)' : ''}',
              style: const TextStyle(
                  fontFamily: 'Nunito', color: Colors.white),
            );
          },
          loading: () => Text(_t(langue, 'titre'),
              style: const TextStyle(
                  fontFamily: 'Nunito', color: Colors.white)),
          error: (_, __) => Text(_t(langue, 'titre'),
              style: const TextStyle(
                  fontFamily: 'Nunito', color: Colors.white)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded,
                color: Colors.white70),
            onPressed: () {
              notifsAsync.whenData((notifs) {
                final nonLues =
                    notifs.where((n) => !_estLue(n)).length;
                _vocal.parler(
                    '$nonLues ${_t(langue, 'vocal')}');
              });
            },
          ),
          notifsAsync.when(
            data: (notifs) {
              final nonLues =
                  notifs.where((n) => !_estLue(n)).length;
              if (nonLues == 0) return const SizedBox();
              return TextButton(
                onPressed: () => _toutMarquerLu(notifs),
                child: Text(
                  _t(langue, 'tout_lire'),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => ref.refresh(notificationsProvider),
          ),
        ],
      ),
      body: notifsAsync.when(
        data: (notifs) => notifs.isEmpty
            ? _buildEtatVide(langue)
            : RefreshIndicator(
                color: AppTheme.vert,
                onRefresh: () =>
                    ref.refresh(notificationsProvider.future),
                child: ListView.builder(
                  padding: EdgeInsets.all(isSmall ? 12 : 16),
                  itemCount: notifs.length,
                  itemBuilder: (ctx, i) =>
                      _buildCarteNotif(notifs[i], langue, isSmall),
                ),
              ),
        loading: () => _buildChargement(),
        error: (_, __) => _buildEtatVide(langue),
      ),
    );
  }

  Widget _buildCarteNotif(Map<String, dynamic> notif,
      String langue, bool isSmall) {
    final lu = _estLue(notif);
    final type = notif['type'] ?? 'info';
    final couleur = _getCouleur(type);
    final titre = notif['titre'] ?? notif['title'] ?? '';
    final message = notif['message'] ?? notif['body'] ?? '';
    final temps = _formatTemps(
        notif['created_at'] ?? notif['date'], langue);
    final id = notif['id']?.toString();

    return GestureDetector(
      onTap: () {
        _marquerLue(id);
        _vocal.parler(message);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(isSmall ? 12 : 14),
        decoration: BoxDecoration(
          color: lu ? Colors.white : AppTheme.vertTresClair,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: lu
                ? const Color(0xFFE8E8E5)
                : AppTheme.vert.withOpacity(0.3),
            width: lu ? 0.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: isSmall ? 36 : 42,
              height: isSmall ? 36 : 42,
              decoration: BoxDecoration(
                color: couleur.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(type),
                color: couleur,
                size: isSmall ? 18 : 22,
              ),
            ),
            SizedBox(width: isSmall ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          titre,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: isSmall ? 13 : 14,
                            fontWeight: lu
                                ? FontWeight.w600
                                : FontWeight.w700,
                            color: AppTheme.texte,
                          ),
                        ),
                      ),
                      if (!lu)
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.vert,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: isSmall ? 11 : 13,
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
                        temps,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isSmall ? 10 : 11,
                          color: AppTheme.gris,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _vocal.parler(message),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmall ? 6 : 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.vertClair,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.volume_up_rounded,
                                  size: isSmall ? 10 : 12,
                                  color: AppTheme.vert),
                              const SizedBox(width: 3),
                              Text(
                                _t(langue, 'ecouter'),
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: isSmall ? 9 : 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.vertFonce,
                                ),
                              ),
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

  Widget _buildEtatVide(String langue) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔔', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            _t(langue, 'aucune'),
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.texte,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t(langue, 'aucune_desc'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: AppTheme.grisTexte,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargement() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (ctx, i) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _vocal.stop();
    super.dispose();
  }
}