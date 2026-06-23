import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../../main.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.6, curve: Curves.easeIn)),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.7, curve: Curves.elasticOut)),
    );
    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.3, 1, curve: Curves.easeOut)),
    );
    _controller.forward();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final langue = StorageService.getLangue();
    final token = StorageService.getToken();
    final premiereVisite = StorageService.isPremiereConnexion();

    if (langue == null) {
      context.go('/langue');
    } else if (premiereVisite && token == null) {
      // Afficher onboarding
      _showOnboarding();
    } else if (token == null) {
      context.go('/connexion');
    } else {
      context.go('/home');
    }
  }

  void _showOnboarding() {
    final langue = StorageService.getLangue() ?? 'fr';
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => OnboardingScreen(langue: langue),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.vert,
      body: Stack(
        children: [
          // Cercles décoratifs
          Positioned(
            top: -sh * 0.1,
            right: -sw * 0.2,
            child: Container(
              width: sw * 0.6,
              height: sw * 0.6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -sh * 0.05,
            left: -sw * 0.15,
            child: Container(
              width: sw * 0.5,
              height: sw * 0.5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Contenu principal
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => FadeTransition(
                opacity: _fadeAnim,
                child: Transform.translate(
                  offset: Offset(0, _slideAnim.value),
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Container(
                          width: sw * 0.28,
                          height: sw * 0.28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(sw * 0.07),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text('💰',
                                style: TextStyle(
                                    fontSize: sw * 0.13)),
                          ),
                        ),
                        SizedBox(height: sh * 0.03),
                        // Nom app
                        const Text(
                          'Tontine Africa',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Slogan multilingue
                        _buildSlogan(),
                        SizedBox(height: sh * 0.08),
                        // Loader
                        const SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            color: Colors.white54,
                            strokeWidth: 2.5,
                          ),
                        ),
                        SizedBox(height: sh * 0.06),
                        // Pays supportés
                        _buildPaysSupports(sw),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Version en bas
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: const Text(
                'v1.0.0 • 20+ pays africains',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  color: Colors.white38,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlogan() {
    final langue = StorageService.getLangue() ?? 'fr';
    final slogans = {
      'fr': 'Ensemble, on grandit 🌍',
      'en': 'Together, we grow 🌍',
      'mos': 'Tõnd fãa, tõnd zagsame 🌍',
      'bm': 'An bɛɛ ye dɔn 🌍',
      'wo': 'Ci dekk, danu dem yëgël 🌍',
      'ar': 'معاً ننمو 🌍',
      'sw': 'Pamoja tunakua 🌍',
    };
    return Text(
      slogans[langue] ?? slogans['fr']!,
      style: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 16,
        color: Colors.white70,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildPaysSupports(double sw) {
    const drapeaux = ['🇧🇫', '🇸🇳', '🇨🇮', '🇲🇱', '🇬🇳',
                      '🇨🇲', '🇨🇩', '🇹🇬', '🇧🇯', '🇳🇪'];
    return Column(
      children: [
        const Text(
          'Disponible dans',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            color: Colors.white38,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          children: drapeaux
              .map((d) => Text(d,
                  style: TextStyle(fontSize: sw * 0.045)))
              .toList(),
        ),
      ],
    );
  }
}

// ── ONBOARDING ────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  final String langue;
  const OnboardingScreen({super.key, required this.langue});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _page = 0;

  List<Map<String, dynamic>> _getPages(String langue) {
    final pages = {
      'fr': [
        {
          'emoji': '💰',
          'titre': 'Bienvenue sur Tontine Africa',
          'desc': 'Gérez vos tontines facilement avec votre téléphone, même sans connexion internet.',
          'couleur': AppTheme.vert,
        },
        {
          'emoji': '🌍',
          'titre': '20+ pays africains',
          'desc': 'Disponible au Burkina Faso, Sénégal, Côte d\'Ivoire, Mali, Guinée et bien plus encore.',
          'couleur': const Color(0xFF378ADD),
        },
        {
          'emoji': '📱',
          'titre': 'Mobile Money intégré',
          'desc': 'Payez vos cotisations avec Orange Money, Moov Money, MTN Money et d\'autres.',
          'couleur': AppTheme.orange,
        },
        {
          'emoji': '🔔',
          'titre': 'Rappels automatiques',
          'desc': 'Recevez des notifications par SMS, WhatsApp et vocal dans votre langue.',
          'couleur': const Color(0xFF9B59B6),
        },
        {
          'emoji': '🔒',
          'titre': 'Sécurisé et fiable',
          'desc': 'Vos données sont protégées. Accédez à votre compte avec votre code PIN secret.',
          'couleur': AppTheme.vertFonce,
        },
      ],
      'en': [
        {
          'emoji': '💰',
          'titre': 'Welcome to Tontine Africa',
          'desc': 'Manage your tontines easily with your phone, even without internet.',
          'couleur': AppTheme.vert,
        },
        {
          'emoji': '🌍',
          'titre': '20+ African countries',
          'desc': 'Available in Burkina Faso, Senegal, Ivory Coast, Mali, Guinea and more.',
          'couleur': const Color(0xFF378ADD),
        },
        {
          'emoji': '📱',
          'titre': 'Integrated Mobile Money',
          'desc': 'Pay your contributions with Orange Money, Moov Money, MTN Money and others.',
          'couleur': AppTheme.orange,
        },
        {
          'emoji': '🔔',
          'titre': 'Automatic reminders',
          'desc': 'Receive notifications by SMS, WhatsApp and voice in your language.',
          'couleur': const Color(0xFF9B59B6),
        },
        {
          'emoji': '🔒',
          'titre': 'Secure and reliable',
          'desc': 'Your data is protected. Access your account with your secret PIN code.',
          'couleur': AppTheme.vertFonce,
        },
      ],
      'mos': [
        {
          'emoji': '💰',
          'titre': 'Aw laafi Tontine Africa',
          'desc': 'Tɩ maand f tontines f tɛlɛfõ zugu, bɩɩ internet ka be ye.',
          'couleur': AppTheme.vert,
        },
        {
          'emoji': '🌍',
          'titre': 'Tẽns 20+ Afrik pʋgẽ',
          'desc': 'Bee Burkina, Senegaal, Côte d\'Ivoire, Mali la tẽns a taab.',
          'couleur': const Color(0xFF378ADD),
        },
        {
          'emoji': '📱',
          'titre': 'Mobile Money',
          'desc': 'Kõ f cotisation Orange Money, Moov Money wall a taab zugu.',
          'couleur': AppTheme.orange,
        },
        {
          'emoji': '🔔',
          'titre': 'Kõ-kaasã',
          'desc': 'Paam kõ-kaasã SMS, WhatsApp la vocal pʋgẽ f bʋʋdo.',
          'couleur': const Color(0xFF9B59B6),
        },
        {
          'emoji': '🔒',
          'titre': 'Zɩɩl la kaseto',
          'desc': 'F yɛla maana sɩda. Zãgs f kaont f PIN code zugu.',
          'couleur': AppTheme.vertFonce,
        },
      ],
      'bm': [
        {
          'emoji': '💰',
          'titre': 'Bisimila Tontine Africa',
          'desc': 'I ka tontinew mara i ka telefɔni la, internet tɛ ni fana.',
          'couleur': AppTheme.vert,
        },
        {
          'emoji': '🌍',
          'titre': 'Jamana 20+ Afiriki',
          'desc': 'Burkina, Senegali, Kódiwari, Mali, Gine ni olu.',
          'couleur': const Color(0xFF378ADD),
        },
        {
          'emoji': '📱',
          'titre': 'Mobile Money',
          'desc': 'I ka sarali sara Orange Money, Moov Money ni olu la.',
          'couleur': AppTheme.orange,
        },
        {
          'emoji': '🔔',
          'titre': 'Kibaruye',
          'desc': 'Kibaru sɔrɔ SMS, WhatsApp ni kuma la i ka kan na.',
          'couleur': const Color(0xFF9B59B6),
        },
        {
          'emoji': '🔒',
          'titre': 'Dɔnni ni danbe',
          'desc': 'I ka kunnafoni bɛ kɔlɔsi. I ka konto sɔrɔ PIN la.',
          'couleur': AppTheme.vertFonce,
        },
      ],
      'wo': [
        {
          'emoji': '💰',
          'titre': 'Dalal Tontine Africa',
          'desc': 'Tëral sa tontine yi ak sa telefon, internet amul ni fana.',
          'couleur': AppTheme.vert,
        },
        {
          'emoji': '🌍',
          'titre': 'Dëkk 20+ Afrik',
          'desc': 'Am na Burkina, Senegaal, Kodiwaar, Mali, Gine ak yeneen.',
          'couleur': const Color(0xFF378ADD),
        },
        {
          'emoji': '📱',
          'titre': 'Mobile Money',
          'desc': 'Fay sa cotisations ak Orange Money, Moov Money ak yeneen.',
          'couleur': AppTheme.orange,
        },
        {
          'emoji': '🔔',
          'titre': 'Xibaar yi',
          'desc': 'Jot xibaar SMS, WhatsApp ak kàddu ci sa làkk.',
          'couleur': const Color(0xFF9B59B6),
        },
        {
          'emoji': '🔒',
          'titre': 'Dëgër ak laaj',
          'desc': 'Say données yi dëgër na. Dugg sa kont ak PIN bi.',
          'couleur': AppTheme.vertFonce,
        },
      ],
    };
    return pages[langue] ?? pages['fr']!;
  }

  String _getBtnSuivant(String langue) {
    const labels = {
      'fr': 'Suivant', 'en': 'Next', 'mos': 'Tɩ zãg',
      'bm': 'Taa ɲɛ', 'wo': 'Dem ëntë',
    };
    return labels[langue] ?? 'Suivant';
  }

  String _getBtnCommencer(String langue) {
    const labels = {
      'fr': 'Commencer', 'en': 'Get started',
      'mos': 'Sɩng', 'bm': 'Daminɛ', 'wo': 'Dëkk',
    };
    return labels[langue] ?? 'Commencer';
  }

  String _getBtnIgnorer(String langue) {
    const labels = {
      'fr': 'Ignorer', 'en': 'Skip',
      'mos': 'Bas', 'bm': 'Tɛmɛ', 'wo': 'Làq',
    };
    return labels[langue] ?? 'Ignorer';
  }

  Future<void> _terminer() async {
    await StorageService.setPremiereConnexion(false);
    if (mounted) context.go('/connexion');
  }

  @override
  Widget build(BuildContext context) {
    final langue = widget.langue;
    final pages = _getPages(langue);
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final isSmall = sw < 360;
    final dernierePage = _page == pages.length - 1;

    return Scaffold(
      backgroundColor: pages[_page]['couleur'] as Color,
      body: SafeArea(
        child: Column(
          children: [
            // Header avec ignorer
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 16 : 20,
                  vertical: isSmall ? 8 : 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicateurs de page
                  Row(
                    children: List.generate(pages.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: i == _page ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? Colors.white
                              : Colors.white38,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  if (!dernierePage)
                    TextButton(
                      onPressed: _terminer,
                      child: Text(
                        _getBtnIgnorer(langue),
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: pages.length,
                itemBuilder: (ctx, i) {
                  final p = pages[i];
                  return _buildPage(p, sw, sh, isSmall);
                },
              ),
            ),

            // Bouton suivant/commencer
            Padding(
              padding: EdgeInsets.fromLTRB(
                  isSmall ? 20 : 24,
                  0,
                  isSmall ? 20 : 24,
                  isSmall ? 24 : 32),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: isSmall ? 48 : 54,
                    child: ElevatedButton(
                      onPressed: () {
                        if (dernierePage) {
                          _terminer();
                        } else {
                          _pageCtrl.nextPage(
                            duration:
                                const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor:
                            pages[_page]['couleur'] as Color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        dernierePage
                            ? _getBtnCommencer(langue)
                            : _getBtnSuivant(langue),
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(Map p, double sw, double sh, bool isSmall) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 24 : 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji dans cercle
          Container(
            width: sw * 0.35,
            height: sw * 0.35,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(p['emoji'],
                  style: TextStyle(fontSize: sw * 0.18)),
            ),
          ),
          SizedBox(height: sh * 0.06),
          // Titre
          Text(
            p['titre'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmall ? 22 : 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          SizedBox(height: sh * 0.025),
          // Description
          Text(
            p['desc'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmall ? 14 : 16,
              color: Colors.white.withOpacity(0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }
}