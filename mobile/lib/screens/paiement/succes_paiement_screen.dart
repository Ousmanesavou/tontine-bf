import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../services/vocal_service.dart';

class SuccesPaiementScreen extends StatefulWidget {
  const SuccesPaiementScreen({super.key});

  @override
  State<SuccesPaiementScreen> createState() => _SuccesPaiementScreenState();
}

class _SuccesPaiementScreenState extends State<SuccesPaiementScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  final VocalService _vocal = VocalService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0)),
    );
    _controller.forward();
    _vocal.parlerMultilingue(
      fr: 'Paiement réussi ! Tous les membres ont été notifiés.',
      moore: 'Paiement sɩda ! Neb fãa sõsg waa.',
      dioula: 'Sarali bɛn ! Mɔgɔ bɛɛ ye kunnafoni sɔrɔ.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: AppTheme.vertClair,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppTheme.vert,
                    size: 56,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    const Text(
                      'Paiement réussi !',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.texte,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Votre cotisation a été enregistrée.',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        color: AppTheme.grisTexte,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildNotifCard(
                      Icons.volume_up_rounded,
                      AppTheme.vertClair,
                      AppTheme.vert,
                      'Message vocal envoyé à tous les membres en mooré, dioula et français.',
                    ),
                    const SizedBox(height: 10),
                    _buildNotifCard(
                      Icons.chat_outlined,
                      const Color(0xFFE8F5E9),
                      const Color(0xFF25D366),
                      'Notification WhatsApp envoyée au groupe automatiquement.',
                    ),
                    const SizedBox(height: 10),
                    _buildNotifCard(
                      Icons.sms_outlined,
                      AppTheme.orangeClair,
                      AppTheme.orange,
                      'SMS envoyé aux membres sans smartphone.',
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('Retour à l\'accueil'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.receipt_outlined),
                      label: const Text('Voir ma tontine'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotifCard(
      IconData icon, Color bg, Color couleur, String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: couleur, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: couleur,
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