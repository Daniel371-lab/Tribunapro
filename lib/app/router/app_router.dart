import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/ads/banner_ad_widget.dart';
import '../../core/models/partido.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/competencias/competencias_screen.dart';
import '../../features/competencias/competencia_detail_screen.dart';
import '../../features/favoritos/favoritos_screen.dart';
import '../../features/historial/historial_screen.dart';
import '../../features/ajustes/ajustes_screen.dart';
import '../../features/partido/partido_detail_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/login/login_screen.dart';
import '../../features/login/registro_screen.dart';
import '../../features/login/terminos_screen.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
    redirect: (context, state) {
      final enSplash = state.matchedLocation == '/splash';
      final enLogin = state.matchedLocation == '/login';
      final enRegistro = state.matchedLocation == '/registro';
      final enTerminos = state.matchedLocation == '/terminos';
      final logueado = FirebaseAuth.instance.currentUser != null;

      if (enSplash) return null;
      if (enTerminos) return null;
      if (!logueado && !enLogin && !enRegistro) return '/login';
      if (logueado && (enLogin || enRegistro)) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/registro',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegistroScreen(),
      ),
      GoRoute(
        path: '/terminos',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TerminosScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => _AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/competencias',
                builder: (context, state) => const CompetenciasScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => CompetenciaDetailScreen(
                      competenciaId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/favoritos', builder: (context, state) => const FavoritosScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/historial', builder: (context, state) => const HistorialScreen()),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/ajustes',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AjustesScreen(),
      ),
      GoRoute(
        path: '/partido',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PartidoDetailScreen(partido: state.extra as Partido),
      ),
    ],
  );
}

class _AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const _AppShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) navigationShell.goBranch(0);
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
                NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Competencias'),
                NavigationDestination(icon: Icon(Icons.star_outline), label: 'Favoritos'),
                NavigationDestination(icon: Icon(Icons.history), label: 'Historial'),
              ],
            ),
            SafeArea(
              top: false,
              child: BannerAdWidget(),
            ),
          ],
        ),
      ),
    );
  }
}