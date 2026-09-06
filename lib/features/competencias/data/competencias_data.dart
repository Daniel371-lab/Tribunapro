class Competencia {
  final String id;
  final String nombre;
  const Competencia(this.id, this.nombre);
}

class CompetenciasData {
  static const ligas = [
    Competencia('39', 'Premier League'),
    Competencia('140', 'La Liga'),
    Competencia('135', 'Serie A'),
    Competencia('78', 'Bundesliga'),
    Competencia('61', 'Ligue 1'),
    Competencia('71', 'Brasileirão'),
    Competencia('128', 'Liga Profesional Argentina'),
    Competencia('250', 'Primera División Paraguay'),
    Competencia('253', 'MLS'),
    Competencia('262', 'Liga MX'),
  ];

  static const copas = [
    Competencia('2', 'Champions League'),
    Competencia('3', 'Europa League'),
    Competencia('13', 'Copa Libertadores'),
    Competencia('11', 'Copa Sudamericana'),
  ];

  static String nombrePorId(String id) {
    final todas = [...ligas, ...copas];
    return todas.firstWhere((c) => c.id == id, orElse: () => Competencia(id, id)).nombre;
  }
}