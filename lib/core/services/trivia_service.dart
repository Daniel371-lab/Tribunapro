import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trivia_pregunta.dart';

class TriviaService {
  static const _kVistos = 'trivia_preguntas_vistas';
  static const _kFecha = 'trivia_fecha_ultimo_reto';
  static const _kAciertosHoy = 'trivia_aciertos_hoy';
  static const _kHistorial = 'trivia_historial_dias';
  static const _maxVistosGuardados = 200;
  static const _maxHistorialDias = 60;

  List<TriviaPregunta>? _todas;

  Future<List<TriviaPregunta>> _cargarTodas() async {
    if (_todas != null) return _todas!;
    final raw = await rootBundle.loadString('assets/trivia/preguntas.json');
    final lista = jsonDecode(raw) as List;
    _todas = lista.map((e) => TriviaPregunta.fromJson(e as Map<String, dynamic>)).toList();
    return _todas!;
  }

  String _fechaHoy() {
    final ahora = DateTime.now();
    return '${ahora.year.toString().padLeft(4, '0')}-${ahora.month.toString().padLeft(2, '0')}-${ahora.day.toString().padLeft(2, '0')}';
  }

  Future<bool> yaJugoHoy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kFecha) == _fechaHoy();
  }

  Future<int> aciertosDeHoy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kAciertosHoy) ?? 0;
  }

  /// Arma las 10 preguntas del reto de hoy, priorizando las que el usuario
  /// nunca vio, y si no alcanzan, rellena con las vistas hace más tiempo.
  Future<List<TriviaPregunta>> armarRetoDeHoy() async {
    final todas = await _cargarTodas();
    final prefs = await SharedPreferences.getInstance();
    final vistos = prefs.getStringList(_kVistos) ?? [];

    final candidatas = todas.where((p) => !vistos.contains(p.id)).toList()..shuffle();
    final seleccion = candidatas.take(10).toList();

    if (seleccion.length < 10) {
      final faltan = 10 - seleccion.length;
      final yaVistas = todas.where((p) => vistos.contains(p.id)).toList();
      // Ordenamos de la más vieja a la más nueva (vistos ya está en ese orden).
      yaVistas.sort((a, b) => vistos.indexOf(a.id).compareTo(vistos.indexOf(b.id)));
      final mitadMasVieja = yaVistas.take((yaVistas.length / 2).ceil()).toList()..shuffle();
      seleccion.addAll(mitadMasVieja.take(faltan));
    }

    seleccion.shuffle();
    return seleccion;
  }

  Future<void> guardarResultado(int aciertos, List<String> idsUsados) async {
    final prefs = await SharedPreferences.getInstance();
    final hoy = _fechaHoy();

    await prefs.setString(_kFecha, hoy);
    await prefs.setInt(_kAciertosHoy, aciertos);

    final vistos = prefs.getStringList(_kVistos) ?? [];
    for (final id in idsUsados) {
      vistos.remove(id);
      vistos.add(id);
    }
    final recortados = vistos.length > _maxVistosGuardados
        ? vistos.sublist(vistos.length - _maxVistosGuardados)
        : vistos;
    await prefs.setStringList(_kVistos, recortados);

    final user = FirebaseAuth.instance.currentUser;
    final esInvitado = user == null || user.isAnonymous;

    // Las insignias (y su historial) son solo para cuentas registradas,
    // porque los invitados inactivos se borran a los 7 días.
    if (!esInvitado) {
      final historialRaw = prefs.getString(_kHistorial);
      final List<dynamic> historial = historialRaw != null ? jsonDecode(historialRaw) as List : [];
      historial.removeWhere((e) => e['fecha'] == hoy);
      historial.add({'fecha': hoy, 'aciertos': aciertos});
      historial.sort((a, b) => (a['fecha'] as String).compareTo(b['fecha'] as String));
      final recortado = historial.length > _maxHistorialDias
          ? historial.sublist(historial.length - _maxHistorialDias)
          : historial;
      await prefs.setString(_kHistorial, jsonEncode(recortado));
    }
  }

  Future<List<Map<String, dynamic>>> obtenerHistorial() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kHistorial);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<Set<String>> obtenerInsigniasDesbloqueadas() async {
    final historial = await obtenerHistorial();
    final desbloqueadas = <String>{};

    final rachaJugados = _calcularRachaConsecutiva(historial, (e) => true);
    if (rachaJugados >= 3) desbloqueadas.add('racha_3');
    if (rachaJugados >= 7) desbloqueadas.add('racha_7');
    if (rachaJugados >= 30) desbloqueadas.add('racha_30');

    final racha6 = _calcularRachaConsecutiva(historial, (e) => (e['aciertos'] as int) >= 6);
    if (racha6 >= 3) desbloqueadas.add('rendimiento_3');

    final racha8 = _calcularRachaConsecutiva(historial, (e) => (e['aciertos'] as int) >= 8);
    if (racha8 >= 7) desbloqueadas.add('rendimiento_7');

    if (historial.any((e) => (e['aciertos'] as int) == 10)) desbloqueadas.add('perfecto_10');

    if (historial.length >= 10) desbloqueadas.add('volumen_10');
    if (historial.length >= 50) desbloqueadas.add('volumen_50');
    if (historial.length >= 100) desbloqueadas.add('volumen_100');

    return desbloqueadas;
  }

  int _calcularRachaConsecutiva(
    List<Map<String, dynamic>> historial,
    bool Function(Map<String, dynamic>) cumple,
  ) {
    if (historial.isEmpty) return 0;
    final ordenado = [...historial]..sort((a, b) => (a['fecha'] as String).compareTo(b['fecha'] as String));

    int mejorRacha = 0;
    int rachaActual = 0;
    DateTime? fechaAnterior;

    for (final entrada in ordenado) {
      final fecha = DateTime.parse(entrada['fecha'] as String);
      final cumpleHoy = cumple(entrada);

      if (!cumpleHoy) {
        rachaActual = 0;
        fechaAnterior = null;
        continue;
      }

      if (fechaAnterior != null && fecha.difference(fechaAnterior).inDays == 1) {
        rachaActual++;
      } else {
        rachaActual = 1;
      }

      if (rachaActual > mejorRacha) mejorRacha = rachaActual;
      fechaAnterior = fecha;
    }

    return mejorRacha;
  }
}