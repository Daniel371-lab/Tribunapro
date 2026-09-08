class Partido {
  final String id;
  final String tipo;
  final String competenciaId;
  final String competenciaNombre;
  final String equipoLocal;
  final String equipoVisitante;
  final DateTime fecha;
  final String? prediccionGanador;
  final String? prediccionGoles;
  final String? porcentajeLocal;
  final String? porcentajeEmpate;
  final String? porcentajeVisitante;
  final String? consejo;
  final List<String>? h2h;
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
    this.prediccionGanador,
    this.prediccionGoles,
    this.porcentajeLocal,
    this.porcentajeEmpate,
    this.porcentajeVisitante,
    this.consejo,
    this.h2h,
    this.corners,
    this.tarjetas,
    this.esPro = false,
    this.finalizado = false,
    this.resultado,
    this.acertado,
  });

  static String? _comoPorcentaje(dynamic valor) {
    if (valor == null) return null;
    if (valor is String) return valor;
    return '$valor%';
  }

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
      porcentajeLocal: _comoPorcentaje(data['porcentajeLocal']),
      porcentajeEmpate: _comoPorcentaje(data['porcentajeEmpate']),
      porcentajeVisitante: _comoPorcentaje(data['porcentajeVisitante']),
      consejo: data['consejo'],
      h2h: data['h2h'] != null ? List<String>.from(data['h2h']) : null,
      corners: data['corners'],
      tarjetas: data['tarjetas'],
      esPro: data['esPro'] ?? false,
      finalizado: data['finalizado'] ?? false,
      resultado: data['resultado'],
      acertado: data['acertado'],
    );
  }
}