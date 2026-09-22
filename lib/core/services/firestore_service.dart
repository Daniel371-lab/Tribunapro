import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/partido.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _partidos => _db.collection('partidos');

  // Helper: un partido se considera "válido para mostrar al usuario" solo
  // si tiene al menos una predicción cargada. Se aplica en las 3 queries
  // del usuario (dashboard, competencias, historial).
  bool _tienePredicciones(Partido p) {
    final preds = p.predicciones;
    return preds != null && preds.isNotEmpty;
  }

  Stream<List<Partido>> proximosPartidos({int limite = 10}) {
    // Nota: NO filtramos por DateTime.now() acá. El filtro
    // finalizado == false ya garantiza "próximos partidos", y así
    // la query no depende del reloj ni de la zona horaria del
    // dispositivo del usuario.
    return _partidos
        .where('publicado', isEqualTo: true)
        .where('finalizado', isEqualTo: false)
        .orderBy('fecha')
        .limit(limite)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Partido.fromMap(d.id, d.data() as Map<String, dynamic>))
            .where(_tienePredicciones)
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
            .where(_tienePredicciones)
            .toList());
  }

  Stream<List<Partido>> historial({int limite = 100}) {
    return _partidos
        .where('publicado', isEqualTo: true)
        .where('finalizado', isEqualTo: true)
        .orderBy('fecha', descending: true)
        .limit(limite)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Partido.fromMap(d.id, d.data() as Map<String, dynamic>))
            .where(_tienePredicciones)
            .toList());
  }

  // Panel de administrador: NO filtra por predicciones. El admin ve todos
  // los pendientes para decidir cuáles marcar como Pro antes de publicar.
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