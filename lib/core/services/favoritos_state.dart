import 'package:flutter/material.dart';

// Estado en memoria por ahora (se pierde al cerrar la app).
// Cuando conectemos login, esto pasa a leer/escribir Firestore por usuario.
final favoritosNotifier = ValueNotifier<Set<String>>({});

void alternarFavorito(String competenciaId) {
  final actual = Set<String>.from(favoritosNotifier.value);
  if (actual.contains(competenciaId)) {
    actual.remove(competenciaId);
  } else {
    actual.add(competenciaId);
  }
  favoritosNotifier.value = actual;
}