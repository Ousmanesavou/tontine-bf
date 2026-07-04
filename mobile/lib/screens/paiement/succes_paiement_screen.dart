import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../services/vocal_service.dart';
import '../../main.dart';

// ── TRADUCTIONS ───────────────────────────────────────
const Map<String, Map<String, String>> _tr = {
  'fr': {
    'titre': 'Paiement réussi !',
    'desc': 'Votre cotisation a été enregistrée avec succès.',
    'vocal': 'Notification vocale envoyée à tous les membres.',
    'whatsapp': 'Notification WhatsApp envoyée au groupe automatiquement.',
    'sms': 'SMS envoyé aux membres sans smartphone.',
    'push': 'Notification push envoyée sur l\'application.',
    'accueil': 'Retour à l\'accueil',
    'voir_tontine': 'Voir ma tontine',
    'partager': 'Partager',
    'merci': 'Merci pour votre paiement ponctuel !',
    'score': 'Votre score de fiabilité a été mis à jour.',
  },
  'en': {
    'titre': 'Payment successful!',
    'desc': 'Your contribution has been successfully recorded.',
    'vocal': 'Voice notification sent to all members.',
    'whatsapp': 'WhatsApp notification sent to the group automatically.',
    'sms': 'SMS sent to members without smartphones.',
    'push': 'Push notification sent on the app.',
    'accueil': 'Back to home',
    'voir_tontine': 'View my tontine',
    'partager': 'Share',
    'merci': 'Thank you for your timely payment!',
    'score': 'Your reliability score has been updated.',
  },
  'mos': {
    'titre': 'Kõ sɩnga sɩda !',
    'desc': 'F cotisation sɩbgame sɩda.',
    'vocal': 'Vocal kõ-kaas tɩɩmame neb fãa.',
    'whatsapp': 'WhatsApp kõ-kaas tɩɩmame.',
    'sms': 'SMS tɩɩmame neb bɩɩ smartphone ka be.',
    'push': 'Kõ-kaas tɩɩmame app pʋgẽ.',
    'accueil': 'Kẽng sẽog-zakẽng',
    'voir_tontine': 'Ges m tontine',
    'partager': 'Wilg',
    'merci': 'Barka f kõ wakatã pʋgẽ !',
    'score': 'F kaseto score yiisi.',
  },
  'bm': {
    'titre': 'Sarali kɛra ka ɲɛ !',
    'desc': 'I ka sarali sɛbɛnna ka ɲɛ.',
    'vocal': 'Kuma kibaru tɔgɔlen mɔgɔw bɛɛ ma.',
    'whatsapp': 'WhatsApp kibaru tɔgɔlen.',
    'sms': 'SMS tɔgɔlen smartphone tɛ mɔgɔw ma.',
    'push': 'Push kibaru tɔgɔlen app la.',
    'accueil': 'Segin sugu ma',
    'voir_tontine': 'N ka tontine ye',
    'partager': 'Labɛn',
    'merci': 'Aw ni baara i ka sara waati la !',
    'score': 'I ka danbe score yɛlɛmana.',
  },
  'wo': {
    'titre': 'Fay bi def naa ko !',
    'desc': 'Sa cotisation bi sɛriñ na.',
    'vocal': 'Xibaar bu kàddu yónneen nit yi bɛɛ.',
    'whatsapp': 'WhatsApp xibaar yónneen.',
    'sms': 'SMS yónneen nit yi smartphone amul.',
    'push': 'Push xibaar yónneen app bi.',
    'accueil': 'Dellu kër',
    'voir_tontine': 'Xool sa tontine',
    'partager': 'Yëgël',
    'merci': 'Jërejëf sa fay bu waxtam !',
    'score': 'Sa diggante score yëlëndi na.',
  },
};

String _t(String langue, String key) {
  final lang = _tr[langue] ?? _tr['fr']!;
  return lang[key] ?? _tr['fr']![key] ?? key;
}

class SuccesPaiementScreen extends ConsumerStatefulWidget {
  const SuccesPaiementScreen({super.key});

  @override
  ConsumerState<SuccesPaiementScreen> createState() =>
      _SuccesPaiementScreenState();
}

class _SuccesPaiementScreenState
    extends ConsumerState<SuccesPaiementScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  final VocalService _vocal = VocalService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.6,
              curve: Curves.elasticOut)),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.4, 1.0,
              curve: Curves.easeIn)),
    );
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.4, 1.0,
              curve: Curves.easeOut)),
    );
    _controller.forward();

    // Message vocal selon langue
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final langue =
            ref.read(langueProvider);
        _vocal.parler(_t(langue, 'titre'));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final langue = ref.watch(langueProvider);
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final isSmall = sw < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 20 : 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: sh * 0.05),

              // ── ANIMATION SUCCÈS ──────────────────────
              ScaleTransition(
                scale: _scaleAnim,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: isSmall ? 100 : 120,
                      height: isSmall ? 100 : 120,
                      decoration: BoxDecoration(
                        color: AppTheme.vertClair,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: isSmall ? 80 : 96,
                      height: isSmall ? 80 : 96,
                      decoration: const BoxDecoration(
                        color: AppTheme.vert,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: isSmall ? 44 : 52,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmall ? 20 : 28),

              // ── TEXTE SUCCÈS ──────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: AnimatedBuilder(
                  animation: _slideAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: child,
                  ),
                  child: Column(
                    children: [
                      Text(
                        _t(langue, 'titre'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isSmall ? 22 : 26,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.texte,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _t(langue, 'desc'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isSmall ? 13 : 15,
                          color: AppTheme.grisTexte,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _t(langue, 'merci'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isSmall ? 12 : 13,
                          color: AppTheme.vert,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: isSmall ? 20 : 28),

                      // ── NOTIFICATIONS ENVOYÉES ────────
                      _buildNotifCard(
                        Icons.volume_up_rounded,
                        AppTheme.vertClair,
                        AppTheme.vert,
                        _t(langue, 'vocal'),
                        isSmall,
                      ),
                      const SizedBox(height: 8),
                      _buildNotifCard(
                        Icons.chat_outlined,
                        const Color(0xFFE8F5E9),
                        const Color(0xFF25D366),
                        _t(langue, 'whatsapp'),
                        isSmall,
                      ),
                      const SizedBox(height: 8),
                      _buildNotifCard(
                        Icons.sms_outlined,
                        AppTheme.orangeClair,
                        AppTheme.orange,
                        _t(langue, 'sms'),
                        isSmall,
                      ),
                      const SizedBox(height: 8),
                      _buildNotifCard(
                        Icons.notifications_outlined,
                        const Color(0xFFEDE7F6),
                        const Color(0xFF7B1FA2),
                        _t(langue, 'push'),
                        isSmall,
                      ),
                      const SizedBox(height: 8),
                      // Score mis à jour
                      Container(
                        padding: EdgeInsets.all(isSmall ? 12 : 14),
                        decoration: BoxDecoration(
                          color: AppTheme.vertClair,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.vert.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppTheme.vert, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _t(langue, 'score'),
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: isSmall ? 12 : 13,
                                  color: AppTheme.vertFonce,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isSmall ? 28 : 36),

                      // ── BOUTONS ───────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: isSmall ? 48 : 54,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/home'),
                          icon: const Icon(Icons.home_outlined),
                          label: Text(
                            _t(langue, 'accueil'),
                            style: TextStyle(
                                fontSize: isSmall ? 14 : 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: isSmall ? 44 : 50,
                        child: OutlinedButton.icon(
                          onPressed: () => context.pop(),
                          icon: const Icon(
                              Icons.receipt_long_outlined),
                          label: Text(
                            _t(langue, 'voir_tontine'),
                            style: TextStyle(
                                fontSize: isSmall ? 13 : 15),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.vert,
                            side: const BorderSide(
                                color: AppTheme.vert),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: sh * 0.03),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotifCard(IconData icon, Color bg,
      Color couleur, String message, bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: couleur, size: isSmall ? 18 : 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: isSmall ? 11 : 13,
                color: couleur,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _vocal.stop();
    super.dispose();
  }
}
