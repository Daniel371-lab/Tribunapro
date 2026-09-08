class Competencia {
  final String id;
  final String nombre;
  const Competencia(this.id, this.nombre);
}

class CompetenciasData {
  static const ligas = [
    Competencia('PL', 'Premier League'),
    Competencia('PD', 'La Liga'),
    Competencia('SA', 'Serie A'),
    Competencia('BL1', 'Bundesliga'),
    Competencia('FL1', 'Ligue 1'),
    Competencia('DED', 'Eredivisie'),
    Competencia('PPL', 'Primeira Liga'),
    Competencia('ELC', 'Championship'),
    Competencia('BSA', 'Brasileirão'),
  ];

  static const copas = [
    Competencia('CL', 'Champions League'),
    Competencia('WC', 'Copa Mundial de la FIFA'),
    Competencia('EC', 'Eurocopa'),
  ];

  static List<Competencia> get todas => [...ligas, ...copas];

  static String nombrePorId(String id) {
    return todas.firstWhere((c) => c.id == id, orElse: () => Competencia(id, id)).nombre;
  }
}