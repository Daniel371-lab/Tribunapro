import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'pro_state.dart';

/// Escucha en tiempo real el documento usuarios/{uid} en Firestore y
/// mantiene el estado de suscripción Pro, partidos desbloqueados, y el
/// límite diario del anuncio recompensado.
class UsuarioState {
  UsuarioState._();
  static final UsuarioState instance = UsuarioState._();

  final ValueNotifier<Set<String>> partidosDesbloqueados = ValueNotifier<Set<String>>({});
  final ValueNotifier<String?> ultimoDesbloqueoAnuncio = ValueNotifier<String?>(null);

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  void iniciar() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _sub?.cancel();
      if (user == null) {
        esProNotifier.value = false;
        partidosDesbloqueados.value = {};
        ultimoDesbloqueoAnuncio.value = null;
        return;
      }

      final ref = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);
      _sub = ref.snapshots().listen((snap) {
        final data = snap.data();
        esProNotifier.value = data?['suscripcionProActiva'] ?? false;
        final lista = (data?['partidosDesbloqueados'] as List?)?.cast<String>() ?? <String>[];
        partidosDesbloqueados.value = lista.toSet();
        ultimoDesbloqueoAnuncio.value = data?['ultimoDesbloqueoAnuncioFecha'] as String?;
      });
    });
  }

  String _fechaHoy() {
    final hoy = DateTime.now();
    return '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
  }

  bool yaUsoAnuncioHoy() => ultimoDesbloqueoAnuncio.value == _fechaHoy();

  Future<void> desbloquearPorAnuncio(String partidoId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);
    await ref.set({
      'partidosDesbloqueados': FieldValue.arrayUnion([partidoId]),
      'ultimoDesbloqueoAnuncioFecha': _fechaHoy(),
    }, SetOptions(merge: true));
  }

  Future<void> desbloquearPorCompra(String partidoId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);
    await ref.set({
      'partidosDesbloqueados': FieldValue.arrayUnion([partidoId]),
    }, SetOptions(merge: true));
  }

  Future<void> activarSuscripcion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);
    await ref.set({'suscripcionProActiva': true}, SetOptions(merge: true));
  }

  Future<void> desactivarSuscripcion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);
    await ref.set({'suscripcionProActiva': false}, SetOptions(merge: true));
  }
}