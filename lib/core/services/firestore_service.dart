import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/partido.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _partidos => _db.collection('partidos');

  Stream<List<Partido>> proximosPartidos({int limite = 10}) {
    final ahora = DateTime.now().toIso8601String();
    return _partidos
        .where('publicado', isEqualTo: true)
        .where('finalizado', isEqualTo: false)
        .where('fecha', isGreaterThan: ahora)
        .orderBy('fecha')
        .limit(limite)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Partido.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<Partido>> partidosPorCompetencia(String competenciaId) {
    return _partidos
        .where('publicado', isEqualTo: true)
        .where('competenciaId', isEqualTo: competenciaId)
        .where('finalizado', isEqualTo: false)
        .orderBy('fecha')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Partido.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<Partido>> historial({int limite = 30}) {
    return _partidos
        .where('publicado', isEqualTo: true)
        .where('finalizado', isEqualTo: true)
        .orderBy('fecha', descending: true)
        .limit(limite)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Partido.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  // Solo para el panel de administrador: partidos pendientes de revisión.
  Stream<List<Partido>> partidosPendientes() {
    return _partidos
        .where('publicado', isEqualTo: false)
        .orderBy('fecha')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Partido.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  // Marca un partido como Pro o no, sin tocar otros campos.
  Future<void> actualizarEsPro(String partidoId, bool esPro) {
    return _partidos.doc(partidoId).update({'esPro': esPro});
  }

  // Publica una lista de partidos de una sola vez (botón "Publicar" del admin).
  Future<void> publicarPartidos(List<String> partidoIds) async {
    final batch = _db.batch();
    for (final id in partidoIds) {
      batch.update(_partidos.doc(id), {'publicado': true});
    }
    await batch.commit();
  }
}