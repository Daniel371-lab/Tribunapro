import 'package:flutter/material.dart';

// Opción 1 (verde cancha) - mismos colores de marca en claro y oscuro,
// solo cambian fondo, superficie y texto.
class AppColors {
  // Marca (igual en ambos modos)
  static const acento = Color(0xFF00A859);
  static const acentoOscuro = Color(0xFF00D26A);
  static const error = Color(0xFFE63946);
  static const pro = Color(0xFF7A5B00);
  static const proBg = Color(0xFFFDF3DB);

  // Claro
  static const fondoClaro = Color(0xFFFFFFFF);
  static const superficieClaro = Color(0xFFF5F7FA);
  static const textoClaro = Color(0xFF1A1A1A);
  static const textoSecundarioClaro = Color(0xFF6B7280);
  static const bordeClaro = Color(0xFFE1E4E8);

  // Oscuro
  static const fondoOscuro = Color(0xFF0D1117);
  static const superficieOscuro = Color(0xFF161B22);
  static const textoOscuro = Color(0xFFF0F2F5);
  static const textoSecundarioOscuro = Color(0xFF9CA3AF);
  static const bordeOscuro = Color(0xFF30363D);
}