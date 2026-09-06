const COPAS_IDS = ["2", "3", "13", "11"];

function esDeCopas(fixture) {
  return COPAS_IDS.includes(String(fixture.league.id));
}

module.exports = { esDeCopas, COPAS_IDS };