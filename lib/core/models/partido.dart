class Partido {
  final String id;
  final String tipo;
  final String competenciaId;
  final String competenciaNombre;
  final String equipoLocal;
  final String? escudoLocal;
  final String equipoVisitante;
  final String? escudoVisitante;
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
  final int? jornada;
  final String? arbitro;
  final int? medioTiempoLocal;
  final int? medioTiempoVisitante;
  final int? posicionLocal;
  final int? posicionVisitante;
  final String? goleadorLocal;
  final String? goleadorVisitante;

  Partido({
    required this.id,
    required this.tipo,
    required this.competenciaId,
    required this.competenciaNombre,
    required this.equipoLocal,
    this.escudoLocal,
    required this.equipoVisitante,
    this.escudoVisitante,
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
    this.jornada,
    this.arbitro,
    this.medioTiempoLocal,
    this.medioTiempoVisitante,
    this.posicionLocal,
    this.posicionVisitante,
    this.goleadorLocal,
    this.goleadorVisitante,
  });

  static String? _comoPorcentaje(dynamic valor) {
    if (valor == null) return null;
    if (valor is String) return valor;
    return '$valor%';
  }

  static int? _comoInt(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return null;
  }

  factory Partido.fromMap(String id, Map<String, dynamic> data) {
    return Partido(
      id: id,
      tipo: data['tipo'],
      competenciaId: data['competenciaId'],
      competenciaNombre: data['competenciaNombre'],
      equipoLocal: data['equipoLocal'],
      escudoLocal: data['escudoLocal'],
      equipoVisitante: data['equipoVisitante'],
      escudoVisitante: data['escudoVisitante'],
      fecha: DateTime.parse(data['fecha']),
      prediccionGanador: data['prediccionGanador'],
      prediccionGoles: data['prediccionGoles'],
      porcentajeLocal: _comoPorcentaje(data['porcentajeLocal']),
      porcentajeEmpate: _comoPorcentaje(data['porcentajeEmpate']),
      porcentajeVisitante: _comoPorcentaje(data['porcentajeVisitante']),
      consejo: data['consejo'],
      h2h: data['h2h'] != null ? List<String>.from(data['h2h']) : null,
      corners: _comoInt(data['corners']),
      tarjetas: _comoInt(data['tarjetas']),
      esPro: data['esPro'] ?? false,
      finalizado: data['finalizado'] ?? false,
      resultado: data['resultado'],
      acertado: data['acertado'],
      jornada: _comoInt(data['jornada']),
      arbitro: data['arbitro'],
      medioTiempoLocal: _comoInt(data['medioTiempoLocal']),
      medioTiempoVisitante: _comoInt(data['medioTiempoVisitante']),
      posicionLocal: _comoInt(data['posicionLocal']),
      posicionVisitante: _comoInt(data['posicionVisitante']),
      goleadorLocal: data['goleadorLocal'],
      goleadorVisitante: data['goleadorVisitante'],
    );
  }
}