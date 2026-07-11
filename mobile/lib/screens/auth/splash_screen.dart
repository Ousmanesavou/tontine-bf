import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../../main.dart';

// ── SPLASH ───────────────────────────────────────────
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
        vsync: this, duration: const Duration(milliseconds: 1400));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeIn)));
    _scaleAnim = Tween<double>(begin: 0.7, end: 1).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.7, curve: Curves.elasticOut)));
    _slideAnim = Tween<double>(begin: 30, end: 0).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1, curve: Curves.easeOut)));
    _controller.forward();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    final langue = StorageService.getLangue();
    final token = StorageService.getToken();
    final premiereVisite = true; // FORCE TEST
    if (premiereVisite) {
      context.go('/onboarding');
    } else if (langue == null) {
      context.go('/langue');
    } else if (token == null) {
      context.go('/connexion');
    } else {
      context.go('/home');
    }
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
          Positioned(
            top: -sh * 0.1, right: -sw * 0.2,
            child: Container(
              width: sw * 0.7, height: sw * 0.7,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle),
            ),
          ),
          Positioned(
            bottom: -sh * 0.05, left: -sw * 0.15,
            child: Container(
              width: sw * 0.55, height: sw * 0.55,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle),
            ),
          ),
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
                        Container(
                          width: sw * 0.38, height: sw * 0.38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 24, offset: const Offset(0, 8))],
                          ),
                          child: CustomPaint(
                              size: Size(sw * 0.38, sw * 0.38),
                              painter: _LogoPainter()),
                        ),
                        SizedBox(height: sh * 0.04),
                        RichText(text: TextSpan(children: [
                          TextSpan(text: 'Tonti', style: TextStyle(
                              fontFamily: 'Nunito', fontSize: sw * 0.09,
                              fontWeight: FontWeight.w800, color: Colors.white)),
                          TextSpan(text: 'Ligdi', style: TextStyle(
                              fontFamily: 'Nunito', fontSize: sw * 0.09,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFF5A623))),
                        ])),
                        const SizedBox(height: 6),
                        Text('Lagem Ligdi', style: TextStyle(
                            fontFamily: 'Nunito', fontSize: sw * 0.045,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF5A623), letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text('Rassemblons l\'argent', style: TextStyle(
                            fontFamily: 'Nunito', fontSize: sw * 0.035,
                            color: Colors.white70)),
                        SizedBox(height: sh * 0.07),
                        SizedBox(
                          width: 28, height: 28,
                          child: CircularProgressIndicator(
                              color: const Color(0xFFF5A623), strokeWidth: 2.5),
                        ),
                        SizedBox(height: sh * 0.05),
                        Wrap(
                          spacing: 4,
                          children: ['BF','SN','CI','ML','GN','CM','CD','TG','BJ','NE']
                              .map((c) => Text(_flagEmoji(c),
                                  style: TextStyle(fontSize: sw * 0.042)))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20, left: 0, right: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(children: [
                const Text('by Toeeg Digital SARL',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Nunito',
                        fontSize: 11, color: Colors.white38)),
                const SizedBox(height: 2),
                const Text('v1.0.0 • 20+ pays africains',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Nunito',
                        fontSize: 10, color: Colors.white24)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _flagEmoji(String code) {
    final map = {
      'BF': '🇧🇫', 'SN': '🇸🇳', 'CI': '🇨🇮', 'ML': '🇲🇱',
      'GN': '🇬🇳', 'CM': '🇨🇲', 'CD': '🇨🇩', 'TG': '🇹🇬',
      'BJ': '🇧🇯', 'NE': '🇳🇪',
    };
    return map[code] ?? code;
  }
}

// ── LOGO PAINTER ─────────────────────────────────────
class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = const Color(0xFFF5A623));
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..color = const Color(0xFF1D9E75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.1);
    canvas.drawCircle(Offset(cx, cy), r * 0.86, Paint()
      ..color = const Color(0xFF1D9E75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.03);
    canvas.drawCircle(Offset(cx, cy), r * 0.72, Paint()..color = const Color(0xFF1D9E75));
    canvas.drawCircle(Offset(cx, cy), r * 0.72, Paint()
      ..color = const Color(0xFFF5A623)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.025);
    _drawLosange(canvas, cx, cy, r * 0.62, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.06
      ..strokeJoin = StrokeJoin.round);
    _drawLosange(canvas, cx, cy, r * 0.50, Paint()
      ..color = const Color(0xFFF5A623)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.04
      ..strokeJoin = StrokeJoin.round);
    _drawLosange(canvas, cx, cy, r * 0.38, Paint()..color = const Color(0xFF0D5C3A));
    _drawLosange(canvas, cx, cy, r * 0.38, Paint()
      ..color = const Color(0xFFF5A623)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.025);
    final pOr = Paint()..color = const Color(0xFF1D9E75);
    _drawPetitLosange(canvas, Offset(cx, cy - r * 0.66), r * 0.07, pOr);
    _drawPetitLosange(canvas, Offset(cx, cy + r * 0.66), r * 0.07, pOr);
    _drawPetitLosange(canvas, Offset(cx - r * 0.66, cy), r * 0.07, pOr);
    _drawPetitLosange(canvas, Offset(cx + r * 0.66, cy), r * 0.07, pOr);
    _drawEtoile(canvas, Offset(cx, cy), r * 0.22, Paint()..color = const Color(0xFFF5A623));
  }

  void _drawLosange(Canvas c, double cx, double cy, double r, Paint p) {
    c.drawPath(Path()
      ..moveTo(cx, cy - r)..lineTo(cx + r, cy)
      ..lineTo(cx, cy + r)..lineTo(cx - r, cy)..close(), p);
  }

  void _drawPetitLosange(Canvas c, Offset center, double s, Paint p) {
    c.drawPath(Path()
      ..moveTo(center.dx, center.dy - s)..lineTo(center.dx + s, center.dy)
      ..lineTo(center.dx, center.dy + s)..lineTo(center.dx - s, center.dy)..close(), p);
  }

  void _drawEtoile(Canvas c, Offset center, double r, Paint p) {
    const branches = 5;
    final petitR = r * 0.45;
    final path = Path();
    for (int i = 0; i < branches * 2; i++) {
      final angle = (i * 3.14159 / branches) - 3.14159 / 2;
      final ray = i.isEven ? r : petitR;
      final x = center.dx + ray * _cos(angle);
      final y = center.dy + ray * _sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    c.drawPath(path, p);
  }

  double _cos(double x) {
    double r = 1, t = 1;
    for (int i = 1; i <= 10; i++) { t *= -x * x / ((2*i-1)*(2*i)); r += t; }
    return r;
  }

  double _sin(double x) {
    double r = x, t = x;
    for (int i = 1; i <= 10; i++) { t *= -x * x / ((2*i)*(2*i+1)); r += t; }
    return r;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── ONBOARDING ───────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  late AnimationController _animCtrl;
  late Animation<double> _anim;
  int _page = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      painter: _LogoPainter(),
      titre: 'Bienvenue sur TontiLigdi',
      description: 'La première application africaine de gestion de tontines numériques. '
          'Gérez vos cotisations, suivez vos membres et recevez vos fonds en toute sécurité.',
      couleur: const Color(0xFF1D9E75),
      couleurSecondaire: const Color(0xFF0D5C3A),
      iconeWidget: null,
      tag: 'NOUVEAU',
    ),
    _OnboardingPage(
      emoji: '🤝',
      titre: 'Créez ou rejoignez\nune tontine',
      description: 'Créez votre groupe d\'épargne en quelques minutes. '
          'Invitez vos amis, famille ou collègues. '
          'Définissez le montant, la fréquence et l\'ordre de rotation.',
      couleur: const Color(0xFF2196F3),
      couleurSecondaire: const Color(0xFF1565C0),
      features: ['Tontines publiques et privées', 'Jusqu\'à 50 membres', 'Rotation automatique'],
      tag: 'SIMPLE',
    ),
    _OnboardingPage(
      emoji: '💰',
      titre: 'Paiements sécurisés\net traçables',
      description: 'Chaque cotisation est enregistrée et vérifiée. '
          'Payez via Orange Money, Moov Money ou envoyez une capture d\'écran. '
          'Historique complet disponible à tout moment.',
      couleur: const Color(0xFFFF8F00),
      couleurSecondaire: const Color(0xFFE65100),
      features: ['Orange Money & Moov Money', 'Validation par l\'organisateur', 'Historique complet'],
      tag: 'SÉCURISÉ',
    ),
    _OnboardingPage(
      emoji: '📊',
      titre: 'Dashboard organisateur\npuissant',
      description: 'Les organisateurs ont accès à un tableau de bord complet. '
          'Suivez les paiements en temps réel, gérez les membres, '
          'envoyez des rappels et générez des rapports.',
      couleur: const Color(0xFF7B1FA2),
      couleurSecondaire: const Color(0xFF4A148C),
      features: ['Suivi en temps réel', 'Rappels automatiques', 'Score de fiabilité'],
      tag: 'PUISSANT',
    ),
    _OnboardingPage(
      emoji: '🌍',
      titre: 'Disponible dans\n20+ pays africains',
      description: 'TontiLigdi est disponible au Burkina Faso, Sénégal, '
          'Côte d\'Ivoire, Mali, Guinée et bien plus encore. '
          'Interface en français, mooré, bambara et wolof.',
      couleur: const Color(0xFF00897B),
      couleurSecondaire: const Color(0xFF004D40),
      features: ['5 langues disponibles', 'Adapté à chaque pays', 'Support Mobile Money local'],
      tag: 'PANAFRICAIN',
    ),
    _OnboardingPage(
      emoji: '🔒',
      titre: 'Votre argent\nen sécurité',
      description: 'KYC obligatoire pour les organisateurs. '
          'Code PIN secret pour accéder à votre compte. '
          'Toutes les transactions sont chiffrées et supervisées par TontiLigdi.',
      couleur: const Color(0xFF37474F),
      couleurSecondaire: const Color(0xFF102027),
      features: ['Vérification KYC', 'Code PIN sécurisé', 'Supervision TontiLigdi'],
      tag: 'FIABLE',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _terminer() async {
    await StorageService.setPremiereConnexion(false);
    if (mounted) {
      final langue = StorageService.getLangue();
      if (langue == null) {
        context.go('/langue');
      } else {
        context.go('/connexion');
      }
    }
  }

  void _nextPage() {
    if (_page < _pages.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _terminer();
    }
  }

  void _onPageChanged(int i) {
    setState(() => _page = i);
    _animCtrl.reset();
    _animCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final page = _pages[_page];
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      backgroundColor: page.couleur,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicateurs de page
                  Row(
                    children: List.generate(_pages.length, (i) =>
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 5),
                          width: i == _page ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? Colors.white
                                : Colors.white.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )),
                  ),
                  // Bouton Passer
                  if (!isLast)
                    TextButton(
                      onPressed: _terminer,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.15),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Passer',
                          style: TextStyle(fontFamily: 'Nunito',
                              color: Colors.white, fontSize: 13)),
                    ),
                ],
              ),
            ),

            // ── CONTENU PRINCIPAL ────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (ctx, i) => _buildPage(_pages[i], sw, sh),
              ),
            ),

            // ── FOOTER ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  // Bouton principal
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: page.couleur,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLast ? 'Commencer maintenant' : 'Continuer',
                            style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 8),
                          Icon(isLast ? Icons.rocket_launch_outlined
                              : Icons.arrow_forward_rounded,
                              size: 20),
                        ],
                      ),
                    ),
                  ),

                  // Lien connexion si déjà compte
                  if (isLast) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _terminer,
                      child: const Text(
                        'J\'ai déjà un compte → Se connecter',
                        style: TextStyle(fontFamily: 'Nunito',
                            color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page, double sw, double sh) {
    return FadeTransition(
      opacity: _anim,
      child: SlideTransition(
        position: Tween<Offset>(
            begin: const Offset(0, 0.05), end: Offset.zero).animate(_anim),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              SizedBox(height: sh * 0.03),

              // ── ILLUSTRATION ──────────────────────
              Stack(
                alignment: Alignment.center,
                children: [
                  // Cercle de fond décoratif
                  Container(
                    width: sw * 0.65,
                    height: sw * 0.65,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: sw * 0.52,
                    height: sw * 0.52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Logo ou emoji
                  if (page.painter != null)
                    Container(
                      width: sw * 0.42,
                      height: sw * 0.42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: CustomPaint(
                          size: Size(sw * 0.42, sw * 0.42),
                          painter: page.painter!),
                    )
                  else
                    Text(page.emoji ?? '✨',
                        style: TextStyle(fontSize: sw * 0.22)),
                ],
              ),

              SizedBox(height: sh * 0.03),

              // ── TAG ───────────────────────────────
              if (page.tag != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.4), width: 1),
                  ),
                  child: Text(page.tag!,
                      style: const TextStyle(
                          fontFamily: 'Nunito', fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white, letterSpacing: 1.5)),
                ),

              const SizedBox(height: 16),

              // ── TITRE ─────────────────────────────
              Text(page.titre,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: sw < 360 ? 22 : 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  )),

              const SizedBox(height: 14),

              // ── DESCRIPTION ───────────────────────
              Text(page.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: sw < 360 ? 14 : 15,
                    color: Colors.white.withOpacity(0.88),
                    height: 1.6,
                  )),

              // ── FEATURES ──────────────────────────
              if (page.features != null && page.features!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  child: Column(
                    children: page.features!.map((f) =>
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check,
                                    color: Colors.white, size: 14),
                              ),
                              const SizedBox(width: 12),
                              Text(f,
                                  style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                            ],
                          ),
                        )).toList(),
                  ),
                ),
              ],

              SizedBox(height: sh * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}

// ── MODELE PAGE ONBOARDING ───────────────────────────
class _OnboardingPage {
  final CustomPainter? painter;
  final String? emoji;
  final String titre;
  final String description;
  final Color couleur;
  final Color couleurSecondaire;
  final List<String>? features;
  final String? tag;
  final Widget? iconeWidget;

  const _OnboardingPage({
    this.painter,
    this.emoji,
    required this.titre,
    required this.description,
    required this.couleur,
    required this.couleurSecondaire,
    this.features,
    this.tag,
    this.iconeWidget,
  });
}
