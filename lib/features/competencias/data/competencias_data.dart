class Competencia {
  final String id;
  final String nombre;
  final String escudo;
  const Competencia(this.id, this.nombre, this.escudo);
}

class CompetenciasData {
  static const ligas = [
    Competencia('PL', 'Premier League', 'https://crests.football-data.org/PL.png'),
    Competencia('PD', 'La Liga', 'https://crests.football-data.org/PD.png'),
    Competencia('SA', 'Serie A', 'https://crests.football-data.org/SA.png'),
    Competencia('BL1', 'Bundesliga', 'https://crests.football-data.org/BL1.png'),
    Competencia('FL1', 'Ligue 1', 'https://crests.football-data.org/FL1.png'),
    Competencia('DED', 'Eredivisie', 'https://crests.football-data.org/DED.png'),
    Competencia('PPL', 'Primeira Liga', 'https://crests.football-data.org/PPL.png'),
    Competencia('ELC', 'Championship', 'https://crests.football-data.org/ELC.png'),
    Competencia('BSA', 'Brasileirão', 'https://crests.football-data.org/BSA.png'),
  ];

  static const copas = [
    Competencia('CL', 'Champions League', 'https://crests.football-data.org/CL.png'),
    Competencia('WC', 'Copa Mundial de la FIFA', 'https://crests.football-data.org/WC.png'),
    Competencia('EC', 'Eurocopa', 'https://crests.football-data.org/EC.png'),
  ];

  // IDs que no están en juego actualmente: se ocultan de la lista visible,
  // pero se mantienen en el mapeo de nombres para no romper referencias
  // de partidos viejos (Historial, Favoritos) que ya tengan esa competencia.
  static const ocultas = ['WC', 'EC'];

  static List<Competencia> get todas =>
      [...ligas, ...copas].where((c) => !ocultas.contains(c.id)).toList();

  static String nombrePorId(String id) {
    final completa = [...ligas, ...copas];
    return completa.firstWhere((c) => c.id == id, orElse: () => Competencia(id, id, '')).nombre;
  }
}