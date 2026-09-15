import 'package:flutter/material.dart';
import '../core/widgets/verificar_conexion.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';

final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

class TribunaProApp extends StatelessWidget {
  const TribunaProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp.router(
          title: 'Tribuna pro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          routerConfig: AppRouter.router,
          builder: (context, child) {
            return VerificarConexion(child: child ?? const SizedBox.shrink());
          },
        );
      },
    );
  }
}