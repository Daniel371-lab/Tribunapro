class PrediccionItem {
  final String tipo;
  final String texto;
  final bool? cumplida;

  PrediccionItem({required this.tipo, required this.texto, this.cumplida});

  static PrediccionItem? fromDynamic(dynamic dato) {
    if (dato is! Map) return null;
    final mapa = Map<String, dynamic>.from(dato);
    if (mapa['tipo'] == null || mapa['texto'] == null) return null;
    return PrediccionItem(
      tipo: mapa['tipo'],
      texto: mapa['texto'],
      cumplida: mapa['cumplida'] is bool ? mapa['cumplida'] : null,
    );
  }
}

class EstadisticaEquipo {
  final int? posicion;
  final int? puntos;
  final int? partidosJugados;
  final int? ganados;
  final int? empatados;
  final int? perdidos;
  final int? golesFavor;
  final int? golesContra;
  final int? diferenciaGol;

  EstadisticaEquipo({
    this.posicion,
    this.puntos,
    this.partidosJugados,
    this.ganados,
    this.empatados,
    this.perdidos,
    this.golesFavor,
    this.golesContra,
    this.diferenciaGol,
  });

  static int? _comoInt(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return null;
  }

  static EstadisticaEquipo? fromMap(dynamic data) {
    if (data == null || data is! Map) return null;
    final mapa = Map<String, dynamic>.from(data);
    return EstadisticaEquipo(
      posicion: _comoInt(mapa['posicion']),
      puntos: _comoInt(mapa['puntos']),
      partidosJugados: _comoInt(mapa['partidosJugados']),
      ganados: _comoInt(mapa['ganados']),
      empatados: _comoInt(mapa['empatados']),
      perdidos: _comoInt(mapa['perdidos']),
      golesFavor: _comoInt(mapa['golesFavor']),
      golesContra: _comoInt(mapa['golesContra']),
      diferenciaGol: _comoInt(mapa['diferenciaGol']),
    );
  }
}

class EnfrentamientoH2H {
  final String equipoLocal;
  final int golesLocal;
  final String equipoVisitante;
  final int golesVisitante;

  EnfrentamientoH2H({
    required this.equipoLocal,
    required this.golesLocal,
    required this.equipoVisitante,
    required this.golesVisitante,
  });

  static EnfrentamientoH2H? fromDynamic(dynamic dato) {
    if (dato is! Map) return null;
    final mapa = Map<String, dynamic>.from(dato);
    if (mapa['equipoLocal'] == null || mapa['equipoVisitante'] == null) return null;
    final golesLocal = mapa['golesLocal'];
    final golesVisitante = mapa['golesVisitante'];
    return EnfrentamientoH2H(
      equipoLocal: mapa['equipoLocal'],
      golesLocal: golesLocal is int ? golesLocal : (golesLocal as num?)?.toInt() ?? 0,
      equipoVisitante: mapa['equipoVisitante'],
      golesVisitante: golesVisitante is int ? golesVisitante : (golesVisitante as num?)?.toInt() ?? 0,
    );
  }
}

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
  final int? porcentajeLocal;
  final int? porcentajeEmpate;
  final int? porcentajeVisitante;
  final List<PrediccionItem>? predicciones;
  final bool muestraChica;
  final List<EnfrentamientoH2H>? h2h;
  final int? corners;
  final int? tarjetas;
  final bool esPro;
  final bool finalizado;
  final String? resultado;
  final int? jornada;
  final int? medioTiempoLocal;
  final int? medioTiempoVisitante;
  final EstadisticaEquipo? statsLocal;
  final EstadisticaEquipo? statsVisitante;

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
    this.porcentajeLocal,
    this.porcentajeEmpate,
    this.porcentajeVisitante,
    this.predicciones,
    this.muestraChica = false,
    this.h2h,
    this.corners,
    this.tarjetas,
    this.esPro = false,
    this.finalizado = false,
    this.resultado,
    this.jornada,
    this.medioTiempoLocal,
    this.medioTiempoVisitante,
    this.statsLocal,
    this.statsVisitante,
  });

  static int? _comoInt(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return null;
  }

  static List<PrediccionItem>? _comoPredicciones(dynamic valor) {
    if (valor == null || valor is! List) return null;
    final lista = valor
        .map((e) => PrediccionItem.fromDynamic(e))
        .whereType<PrediccionItem>()
        .toList();
    return lista.isEmpty ? null : lista;
  }

  static List<EnfrentamientoH2H>? _comoH2H(dynamic valor) {
    if (valor == null || valor is! List) return null;
    final lista = valor
        .map((e) => EnfrentamientoH2H.fromDynamic(e))
        .whereType<EnfrentamientoH2H>()
        .toList();
    return lista.isEmpty ? null : lista;
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
      porcentajeLocal: _comoInt(data['porcentajeLocal']),
      porcentajeEmpate: _comoInt(data['porcentajeEmpate']),
      porcentajeVisitante: _comoInt(data['porcentajeVisitante']),
      predicciones: _comoPredicciones(data['predicciones']),
      muestraChica: data['muestraChica'] ?? false,
      h2h: _comoH2H(data['h2h']),
      corners: _comoInt(data['corners']),
      tarjetas: _comoInt(data['tarjetas']),
      esPro: data['esPro'] ?? false,
      finalizado: data['finalizado'] ?? false,
      resultado: data['resultado'],
      jornada: _comoInt(data['jornada']),
      medioTiempoLocal: _comoInt(data['medioTiempoLocal']),
      medioTiempoVisitante: _comoInt(data['medioTiempoVisitante']),
      statsLocal: EstadisticaEquipo.fromMap(data['statsLocal']),
      statsVisitante: EstadisticaEquipo.fromMap(data['statsVisitante']),
    );
  }
}