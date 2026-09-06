import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/partido.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/competencias/competencias_screen.dart';
import '../../features/competencias/ligas_list_screen.dart';
import '../../features/competencias/copas_list_screen.dart';
import '../../features/competencias/competencia_detail_screen.dart';
import '../../features/favoritos/favoritos_screen.dart';
import '../../features/historial/historial_screen.dart';
import '../../features/ajustes/ajustes_screen.dart';
import '../../features/partido/partido_detail_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
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
                    path: 'ligas',
                    builder: (context, state) => const LigasListScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => CompetenciaDetailScreen(
                          competenciaId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'copas',
                    builder: (context, state) => const CopasListScreen(),
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
        bottomNavigationBar: NavigationBar(
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
      ),
    );
  }
}