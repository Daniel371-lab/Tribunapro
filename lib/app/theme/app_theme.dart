import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.fondoClaro,
        colorScheme: const ColorScheme.light(
          primary: AppColors.acento,
          error: AppColors.error,
          surface: AppColors.superficieClaro,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: AppColors.textoClaro),
        ),
        dividerColor: AppColors.bordeClaro,
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.fondoOscuro,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.acentoOscuro,
          error: AppColors.error,
          surface: AppColors.superficieOscuro,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: AppColors.textoOscuro),
        ),
        dividerColor: AppColors.bordeOscuro,
      );
}