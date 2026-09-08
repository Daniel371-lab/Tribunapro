const COMPETENCIAS = {
  PL: { nombre: "Premier League", tipo: "liga" },
  PD: { nombre: "La Liga", tipo: "liga" },
  SA: { nombre: "Serie A", tipo: "liga" },
  BL1: { nombre: "Bundesliga", tipo: "liga" },
  FL1: { nombre: "Ligue 1", tipo: "liga" },
  DED: { nombre: "Eredivisie", tipo: "liga" },
  PPL: { nombre: "Primeira Liga", tipo: "liga" },
  ELC: { nombre: "Championship", tipo: "liga" },
  BSA: { nombre: "Brasileirão", tipo: "liga" },
  CL: { nombre: "Champions League", tipo: "copa" },
  WC: { nombre: "Copa Mundial de la FIFA", tipo: "copa" },
  EC: { nombre: "Eurocopa", tipo: "copa" },
};

function esCompetenciaValida(match) {
  return Object.prototype.hasOwnProperty.call(COMPETENCIAS, match.competition.code);
}

function datosCompetencia(codigo) {
  return COMPETENCIAS[codigo] || { nombre: codigo, tipo: "liga" };
}

module.exports = { COMPETENCIAS, esCompetenciaValida, datosCompetencia };