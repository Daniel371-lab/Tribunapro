const { obtenerFixturesPorFecha, obtenerPrediccion } = require("./apiFootball");
const { db } = require("./firebaseAdmin");

const COPAS_IDS = ["2", "3", "13", "11"];

async function procesarFixturesDeCopas(fecha) {
  const todosLosFixtures = await obtenerFixturesPorFecha(fecha);
  const deCopas = todosLosFixtures.filter((f) =>
    COPAS_IDS.includes(String(f.league.id))
  );

  for (const fixture of deCopas) {
    const yaExiste = await db.collection("partidos").doc(String(fixture.fixture.id)).get();
    if (yaExiste.exists) continue;

    const prediccion = await obtenerPrediccion(fixture.fixture.id);

    await db.collection("partidos").doc(String(fixture.fixture.id)).set({
      tipo: "copa",
      competenciaId: String(fixture.league.id),
      competenciaNombre: fixture.league.name,
      equipoLocal: fixture.teams.home.name,
      equipoVisitante: fixture.teams.away.name,
      fecha: fixture.fixture.date,
      prediccionGanador: prediccion?.predictions?.winner?.name ?? "Sin datos",
      prediccionGoles: prediccion?.predictions?.goals?.home ?? null,
      esPro: true,
      finalizado: false,
      resultado: null,
      acertado: null,
    });
  }

  return deCopas.length;
}

module.exports = { procesarFixturesDeCopas, COPAS_IDS };