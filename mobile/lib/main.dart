import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/auth/splash_screen.dart';
import 'screens/auth/langue_screen.dart';
import 'screens/auth/inscription_screen.dart';
import 'screens/auth/connexion_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/tontine/tontine_detail_screen.dart';
import 'screens/tontine/creer_tontine_screen.dart';
import 'screens/tontine/membres_screen.dart';
import 'screens/paiement/paiement_screen.dart';
import 'screens/paiement/succes_paiement_screen.dart';
import 'screens/catalogue/catalogue_screen.dart';
import 'screens/profil/profil_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'utils/app_theme.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await StorageService.init();
  runApp(const ProviderScope(child: TontineBFApp()));
}

final langueProvider = StateProvider<String>((ref) {
  return StorageService.getLangue() ?? 'fr';
});

class TontineBFApp extends ConsumerWidget {
  const TontineBFApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Tontine BF',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
      ],
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (ctx, state) => const SplashScreen(),
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
      path: '/tontine/creer',
      builder: (ctx, state) => const CreerTontineScreen(),
    ),
    GoRoute(
      path: '/tontine/:id',
      builder: (ctx, state) =>
          TontineDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/tontine/:id/membres',
      builder: (ctx, state) =>
          MembresScreen(tontineId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/paiement/succes',
      builder: (ctx, state) => const SuccesPaiementScreen(),
    ),
    GoRoute(
      path: '/paiement/:cotisationId',
      builder: (ctx, state) =>
          PaiementScreen(cotisationId: state.pathParameters['cotisationId']!),
    ),
    GoRoute(
      path: '/catalogue',
      builder: (ctx, state) => const CatalogueScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (ctx, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/profil',
      builder: (ctx, state) => const ProfilScreen(),
    ),
  ],
);