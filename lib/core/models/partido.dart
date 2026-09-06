class Partido {
  final String id;
  final String tipo;
  final String competenciaId;
  final String competenciaNombre;
  final String equipoLocal;
  final String equipoVisitante;
  final DateTime fecha;
  final String prediccionGanador;
  final String? prediccionGoles;
  final int? corners;
  final int? tarjetas;
  final bool esPro;
  final bool finalizado;
  final String? resultado;
  final bool? acertado;

  Partido({
    required this.id,
    required this.tipo,
    required this.competenciaId,
    required this.competenciaNombre,
    required this.equipoLocal,
    required this.equipoVisitante,
    required this.fecha,
    required this.prediccionGanador,
    this.prediccionGoles,
    this.corners,
    this.tarjetas,
    this.esPro = false,
    this.finalizado = false,
    this.resultado,
    this.acertado,
  });

  factory Partido.fromMap(String id, Map<String, dynamic> data) {
    return Partido(
      id: id,
      tipo: data['tipo'],
      competenciaId: data['competenciaId'],
      competenciaNombre: data['competenciaNombre'],
      equipoLocal: data['equipoLocal'],
      equipoVisitante: data['equipoVisitante'],
      fecha: DateTime.parse(data['fecha']),
      prediccionGanador: data['prediccionGanador'],
      prediccionGoles: data['prediccionGoles'],
      corners: data['corners'],
      tarjetas: data['tarjetas'],
      esPro: data['esPro'] ?? false,
      finalizado: data['finalizado'] ?? false,
      resultado: data['resultado'],
      acertado: data['acertado'],
    );
  }
}