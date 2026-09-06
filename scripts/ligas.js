const LIGAS_IDS = ["39", "140", "135", "78", "61", "71", "128", "250", "253", "262"];

function esDeLigas(fixture) {
  return LIGAS_IDS.includes(String(fixture.league.id));
}

module.exports = { esDeLigas, LIGAS_IDS };