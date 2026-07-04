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
      CurvedAnimation(parent: _controller,
          curve: const Interval(0, 0.6, curve: Curves.easeIn)),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _controller,
          curve: const Interval(0, 0.7, curve: Curves.elasticOut)),
    );
    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _controller,
          curve: const Interval(0.3, 1, curve: Curves.easeOut)),
    );
    _controller.forward();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;
    final langue = StorageService.getLangue();
    final token = StorageService.getToken();
    final premiereVisite = StorageService.isPremiereConnexion();
    if (langue == null) {
      context.go('/langue');
    } else if (premiereVisite && token == null) {
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
          Positioned(
            top: -sh * 0.1, right: -sw * 0.2,
            child: Container(
              width: sw * 0.7, height: sw * 0.7,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -sh * 0.05, left: -sw * 0.15,
            child: Container(
              width: sw * 0.55, height: sw * 0.55,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
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
                        // ✅ LOGO TontiLigdi
                        Container(
                          width: sw * 0.38,
                          height: sw * 0.38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: CustomPaint(
                            size: Size(sw * 0.38, sw * 0.38),
                            painter: _LogoPainter(),
                          ),
                        ),
                        SizedBox(height: sh * 0.04),
                        // ✅ Nom TontiLigdi bicolore
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Tonti',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: sw * 0.09,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              TextSpan(
                                text: 'Ligdi',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: sw * 0.09,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFF5A623),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Lagem Ligdi',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: sw * 0.045,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF5A623),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getSlogan(),
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: sw * 0.035,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: sh * 0.07),
                        const SizedBox(
                          width: 28, height: 28,
                          child: CircularProgressIndicator(
                            color: Color(0xFFF5A623),
                            strokeWidth: 2.5,
                          ),
                        ),
                        SizedBox(height: sh * 0.05),
                        _buildPaysSupports(sw),
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
              child: Column(
                children: [
                  const Text(
                    'by Toeeg Digital SARL',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'v1.0.0 • 20+ pays africains',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 10,
                      color: Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSlogan() {
    final langue = StorageService.getLangue() ?? 'fr';
    const slogans = {
      'fr': 'Rassemblons l\'argent',
      'en': 'Let\'s gather money',
      'mos': 'Tond na lagem ligdi',
      'bm': 'An ka wari lagem',
      'wo': 'Nan lagem xaalis',
    };
    return slogans[langue] ?? slogans['fr']!;
  }

  Widget _buildPaysSupports(double sw) {
    const drapeaux = ['🇧🇫','🇸🇳','🇨🇮','🇲🇱','🇬🇳','🇨🇲','🇨🇩','🇹🇬','🇧🇯','🇳🇪'];
    return Column(
      children: [
        const Text('Disponible dans',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 10, color: Colors.white38)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          children: drapeaux.map((d) =>
              Text(d, style: TextStyle(fontSize: sw * 0.042))).toList(),
        ),
      ],
    );
  }
}

// ✅ PEINTRE DU LOGO TontiLigdi
class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Cercle or
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = const Color(0xFFF5A623));

    // Anneaux verts
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = const Color(0xFF1D9E75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.1);
    canvas.drawCircle(Offset(cx, cy), r * 0.86,
        Paint()..color = const Color(0xFF1D9E75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.03);

    // Cercle intérieur vert
    canvas.drawCircle(Offset(cx, cy), r * 0.72,
        Paint()..color = const Color(0xFF1D9E75));
    canvas.drawCircle(Offset(cx, cy), r * 0.72,
        Paint()..color = const Color(0xFFF5A623)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.025);

    // Grand losange blanc
    _drawLosange(canvas, cx, cy, r * 0.62,
        Paint()..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.06
          ..strokeJoin = StrokeJoin.round);

    // Losange moyen or
    _drawLosange(canvas, cx, cy, r * 0.50,
        Paint()..color = const Color(0xFFF5A623)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.04
          ..strokeJoin = StrokeJoin.round);

    // Losange intérieur foncé
    _drawLosange(canvas, cx, cy, r * 0.38,
        Paint()..color = const Color(0xFF0D5C3A));
    _drawLosange(canvas, cx, cy, r * 0.38,
        Paint()..color = const Color(0xFFF5A623)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.025);

    // 4 losanges aux coins
    final pOr = Paint()..color = const Color(0xFF1D9E75);
    _drawPetitLosange(canvas, Offset(cx, cy - r * 0.66), r * 0.07, pOr);
    _drawPetitLosange(canvas, Offset(cx, cy + r * 0.66), r * 0.07, pOr);
    _drawPetitLosange(canvas, Offset(cx - r * 0.66, cy), r * 0.07, pOr);
    _drawPetitLosange(canvas, Offset(cx + r * 0.66, cy), r * 0.07, pOr);

    // Etoile Burkina
    _drawEtoile(canvas, Offset(cx, cy), r * 0.22,
        Paint()..color = const Color(0xFFF5A623));
  }

  void _drawLosange(Canvas c, double cx, double cy, double r, Paint p) {
    final path = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r, cy)
      ..lineTo(cx, cy + r)
      ..lineTo(cx - r, cy)
      ..close();
    c.drawPath(path, p);
  }

  void _drawPetitLosange(Canvas c, Offset center, double s, Paint p) {
    final path = Path()
      ..moveTo(center.dx, center.dy - s)
      ..lineTo(center.dx + s, center.dy)
      ..lineTo(center.dx, center.dy + s)
      ..lineTo(center.dx - s, center.dy)
      ..close();
    c.drawPath(path, p);
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
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    c.drawPath(path, p);
  }

  double _cos(double x) {
    double r = 1, t = 1;
    for (int i = 1; i <= 10; i++) {
      t *= -x * x / ((2 * i - 1) * (2 * i));
      r += t;
    }
    return r;
  }

  double _sin(double x) {
    double r = x, t = x;
    for (int i = 1; i <= 10; i++) {
      t *= -x * x / ((2 * i) * (2 * i + 1));
      r += t;
    }
    return r;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        {'widget': 'logo', 'titre': 'Bienvenue sur TontiLigdi',
          'desc': 'Gerez vos tontines facilement avec votre telephone, meme sans connexion internet.',
          'couleur': AppTheme.vert},
        {'emoji': '🌍', 'titre': '20+ pays africains',
          'desc': 'Disponible au Burkina Faso, Senegal, Cote d\'Ivoire, Mali, Guinee et bien plus.',
          'couleur': const Color(0xFF378ADD)},
        {'emoji': '📱', 'titre': 'Mobile Money integre',
          'desc': 'Payez vos cotisations avec Orange Money, Moov Money, Wave et d\'autres.',
          'couleur': AppTheme.orange},
        {'emoji': '🔔', 'titre': 'Rappels automatiques',
          'desc': 'Recevez des notifications dans votre langue : francais, moore, bambara, wolof.',
          'couleur': const Color(0xFF9B59B6)},
        {'emoji': '🔒', 'titre': 'Securise et fiable',
          'desc': 'Vos donnees sont protegees. Acces avec votre code PIN secret.',
          'couleur': AppTheme.vertFonce},
      ],
      'en': [
        {'widget': 'logo', 'titre': 'Welcome to TontiLigdi',
          'desc': 'Manage your tontines easily with your phone, even without internet.',
          'couleur': AppTheme.vert},
        {'emoji': '🌍', 'titre': '20+ African countries',
          'desc': 'Available in Burkina Faso, Senegal, Ivory Coast, Mali, Guinea and more.',
          'couleur': const Color(0xFF378ADD)},
        {'emoji': '📱', 'titre': 'Integrated Mobile Money',
          'desc': 'Pay with Orange Money, Moov Money, Wave and others.',
          'couleur': AppTheme.orange},
        {'emoji': '🔔', 'titre': 'Automatic reminders',
          'desc': 'Get notifications in your language: French, Moore, Bambara, Wolof.',
          'couleur': const Color(0xFF9B59B6)},
        {'emoji': '🔒', 'titre': 'Secure and reliable',
          'desc': 'Your data is protected. Access with your secret PIN code.',
          'couleur': AppTheme.vertFonce},
      ],
      'mos': [
        {'widget': 'logo', 'titre': 'Aw laafi TontiLigdi',
          'desc': 'Ti maand f tontines f telefon zugu, biiy internet ka be ye.',
          'couleur': AppTheme.vert},
        {'emoji': '🌍', 'titre': 'Tens 20+ Afrik pugẽ',
          'desc': 'Bee Burkina, Senegaal, Cote d\'Ivoire, Mali la tens a taab.',
          'couleur': const Color(0xFF378ADD)},
        {'emoji': '📱', 'titre': 'Mobile Money',
          'desc': 'Ko f cotisation Orange Money, Moov Money wall a taab zugu.',
          'couleur': AppTheme.orange},
        {'emoji': '🔔', 'titre': 'Ko-kaasa',
          'desc': 'Paam ko-kaasa SMS, WhatsApp la vocal pugẽ f buudo.',
          'couleur': const Color(0xFF9B59B6)},
        {'emoji': '🔒', 'titre': 'Ziil la kaseto',
          'desc': 'F yela maana sida. Zags f kaont f PIN code zugu.',
          'couleur': AppTheme.vertFonce},
      ],
    };
    return pages[langue] ?? pages['fr']!;
  }

  String _getBtnSuivant(String l) =>
      {'fr':'Suivant','en':'Next','mos':'Ti zag','bm':'Taa nɛ','wo':'Dem ëntë'}[l] ?? 'Suivant';

  String _getBtnCommencer(String l) =>
      {'fr':'Commencer','en':'Get started','mos':'Sing','bm':'Daminɛ','wo':'Dëkk'}[l] ?? 'Commencer';

  String _getBtnIgnorer(String l) =>
      {'fr':'Ignorer','en':'Skip','mos':'Bas','bm':'Tɛmɛ','wo':'Làq'}[l] ?? 'Ignorer';

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
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 16 : 20,
                  vertical: isSmall ? 8 : 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(pages.length, (i) =>
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _page ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page ? Colors.white : Colors.white38,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )),
                  ),
                  if (!dernierePage)
                    TextButton(
                      onPressed: _terminer,
                      child: Text(_getBtnIgnorer(langue),
                          style: const TextStyle(
                              fontFamily: 'Nunito',
                              color: Colors.white70, fontSize: 14)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: pages.length,
                itemBuilder: (ctx, i) =>
                    _buildPage(pages[i], sw, sh, isSmall),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  isSmall ? 20 : 24, 0,
                  isSmall ? 20 : 24, isSmall ? 24 : 32),
              child: SizedBox(
                width: double.infinity,
                height: isSmall ? 48 : 54,
                child: ElevatedButton(
                  onPressed: () {
                    if (dernierePage) {
                      _terminer();
                    } else {
                      _pageCtrl.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: pages[_page]['couleur'] as Color,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    dernierePage ? _getBtnCommencer(langue) : _getBtnSuivant(langue),
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(Map p, double sw, double sh, bool isSmall) {
    final isLogoPage = p['widget'] == 'logo';
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 24 : 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLogoPage)
            CustomPaint(
              size: Size(sw * 0.42, sw * 0.42),
              painter: _LogoPainter(),
            )
          else
            Container(
              width: sw * 0.35, height: sw * 0.35,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(child: Text(p['emoji'],
                  style: TextStyle(fontSize: sw * 0.18))),
            ),
          SizedBox(height: sh * 0.05),
          Text(p['titre'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmall ? 22 : 26,
              fontWeight: FontWeight.w800,
              color: Colors.white, height: 1.2,
            ),
          ),
          SizedBox(height: sh * 0.02),
          if (isLogoPage) ...[
            const Text('Lagem Ligdi',
              style: TextStyle(
                fontFamily: 'Nunito', fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF5A623), letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            const Text('Rassemblons l\'argent',
              style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 12,
                  color: Colors.white60),
            ),
            const SizedBox(height: 12),
          ],
          Text(p['desc'],
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
