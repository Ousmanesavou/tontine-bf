import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/tontine/compte_virtuel_screen.dart';

import 'screens/catalogue/espace_commercant_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/langue_screen.dart';
import 'screens/auth/inscription_screen.dart';
import 'screens/auth/connexion_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/tontine/tontine_detail_screen.dart';
import 'screens/tontine/dashboard_organisateur_screen.dart';
import 'screens/tontine/creer_tontine_screen.dart';
import 'screens/tontine/membres_screen.dart';
import 'screens/paiement/paiement_screen.dart';
import 'screens/paiement/paiement_capture_screen.dart';
import 'screens/paiement/succes_paiement_screen.dart';
import 'screens/catalogue/catalogue_screen.dart';
import 'screens/profil/profil_screen.dart';
import 'screens/profil/reglages_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'utils/app_theme.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientation portrait uniquement
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Barre de statut transparente
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await StorageService.init();

  // Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  runApp(const ProviderScope(child: TontineAfricaApp()));
}

// ── PROVIDERS ─────────────────────────────────────────
final langueProvider = StateProvider<String>((ref) {
  return StorageService.getLangue() ?? 'fr';
});

final paysProvider = StateProvider<String>((ref) {
  return StorageService.getPays() ?? 'BF';
});

final fontSizeProvider = StateProvider<double>((ref) {
  return StorageService.getFontSize() ?? 14.0;
});

// ── APP ───────────────────────────────────────────────
class TontineAfricaApp extends ConsumerWidget {
  const TontineAfricaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langue = ref.watch(langueProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final factor = (fontSize / 14.0).clamp(0.8, 1.4);
    final baseText = AppTheme.lightTheme.textTheme;

    // Locale selon la langue choisie
    Locale locale;
    switch (langue) {
      case 'en': locale = const Locale('en'); break;
      case 'ar': locale = const Locale('ar'); break;
      case 'sw': locale = const Locale('sw'); break;
      case 'pt': locale = const Locale('pt'); break;
      default: locale = const Locale('fr');
    }

    return MaterialApp.router(
      title: 'TontiLigdi',
      debugShowCheckedModeBanner: false,
      key: ValueKey(langue), // Force rebuild quand langue change
      //fixes to the font size issue when changing the font size in settings
      theme: AppTheme.lightTheme.copyWith(
      textTheme: baseText.copyWith(
           
      bodyLarge: baseText.bodyLarge?.copyWith(fontSize: (baseText.bodyLarge?.fontSize ?? 16) * factor), // Body Text (Standard content)
      bodyMedium: baseText.bodyMedium?.copyWith(fontSize: (baseText.bodyMedium?.fontSize ?? 14) * factor),
       bodySmall: baseText.bodySmall?.copyWith(fontSize: (baseText.bodySmall?.fontSize ?? 12) * factor),   
            
      titleLarge: baseText.titleLarge?.copyWith(fontSize: (baseText.titleLarge?.fontSize ?? 22) * factor),// Headings & Titles (AppBars, Section Headers)
      titleMedium: baseText.titleMedium?.copyWith(fontSize: (baseText.titleMedium?.fontSize ?? 16) * factor),
      titleSmall: baseText.titleSmall?.copyWith(fontSize: (baseText.titleSmall?.fontSize ?? 14) * factor),
           
      labelLarge: baseText.labelLarge?.copyWith(fontSize: (baseText.labelLarge?.fontSize ?? 14) * factor),// Labels & Buttons (TextFields, TabBars, Buttons)
      labelMedium: baseText.labelMedium?.copyWith(fontSize: (baseText.labelMedium?.fontSize ?? 12) * factor),
      labelSmall: baseText.labelSmall?.copyWith(fontSize: (baseText.labelSmall?.fontSize ?? 11) * factor),
        ),
    ),

      locale: locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('ar'),
        Locale('sw'),
        Locale('pt'),
      ],
      routerConfig: _router,
    );
  }
}
// ── ROUTER ────────────────────────────────────────────
final _router = GoRouter(
  initialLocation: '/splash',
  errorBuilder: (ctx, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Page introuvable',
              style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ctx.go('/home'),
            child: const Text('Retour à l\'accueil'),
          ),
        ],
      ),
    ),
  ),
  routes: [
    GoRoute(
      path: '/splash',
      builder: (ctx, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (ctx, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/langue',
      builder: (ctx, state) => const LangueScreen(),
    ),
    GoRoute(
      path: '/inscription',
      builder: (ctx, state) => const InscriptionScreen(),
    ),
    GoRoute(
      path: '/connexion',
      builder: (ctx, state) => const ConnexionScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (ctx, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/catalogue',
      builder: (ctx, state) => const CatalogueScreen(),
    ),

    GoRoute(
      path: '/espace-commercant',
      builder: (ctx, state) => const EspaceCommercantScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (ctx, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/profil',
      builder: (ctx, state) => const ProfilScreen(),
    ),
    GoRoute(
      path: '/reglages',
      builder: (ctx, state) => const ReglagesScreen(),
    ),
    GoRoute(
      path: '/paiement/capture/:tontineId',
      builder: (ctx, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return PaiementCaptureScreen(
          tontineId: state.pathParameters['tontineId']!,
          montant: extra['montant'] ?? 0.0,
          numeroOrganisateur: extra['numeroOrganisateur'] ?? '',
          operateur: extra['operateur'] ?? 'Orange Money',
          nomTontine: extra['nomTontine'] ?? 'Tontine',
        );
      },
    ),
    GoRoute(
      path: '/paiement/succes',
      builder: (ctx, state) => const SuccesPaiementScreen(),
    ),
    GoRoute(
      path: '/paiement/:cotisationId',
      builder: (ctx, state) => PaiementScreen(
          cotisationId: state.pathParameters['cotisationId']!),
    ),

    // ── TONTINES (routes spécifiques AVANT /:id) ──────
    GoRoute(
  path: '/tontine/creer',
  builder: (ctx, state) {
    // Safely extract the optional product map
    final Map<String, dynamic>? produitSelectionne = state.extra as Map<String, dynamic>?;
    
    // Pass the nullable map to your screen widget
    return CreerTontineScreen(produit: produitSelectionne);
  },
),

    GoRoute(
      path: '/tontine/:id/compte-virtuel', // ✅ AVANT /:id
      builder: (ctx, state) => CompteVirtuelScreen(
        tontineId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/tontine/:id/membres', // ✅ AVANT /:id
      builder: (ctx, state) => MembresScreen(
          tontineId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/tontine/:id/dashboard',
      builder: (ctx, state) => DashboardOrganisateurScreen(
        tontineId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/tontine/:id', // ✅ EN DERNIER
      builder: (ctx, state) => TontineDetailScreen(
          id: state.pathParameters['id']!),
    ),


  ],
);


