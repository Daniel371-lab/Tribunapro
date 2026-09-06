const { obtenerFixturesPorFecha, obtenerPrediccion } = require("./apiFootball");
const { db } = require("./firebaseAdmin");

const LIGAS_IDS = ["39", "140", "135", "78", "61", "71", "128", "250", "253", "262"];

async function procesarFixturesDeLigas(fecha) {
  const todosLosFixtures = await obtenerFixturesPorFecha(fecha);
  const deLigas = todosLosFixtures.filter((f) =>
    LIGAS_IDS.includes(String(f.league.id))
  );

  for (const fixture of deLigas) {
    const yaExiste = await db.collection("partidos").doc(String(fixture.fixture.id)).get();
    if (yaExiste.exists) continue;

    const prediccion = await obtenerPrediccion(fixture.fixture.id);

    await db.collection("partidos").doc(String(fixture.fixture.id)).set({
      tipo: "liga",
      competenciaId: String(fixture.league.id),
      competenciaNombre: fixture.league.name,
      equipoLocal: fixture.teams.home.name,
      equipoVisitante: fixture.teams.away.name,
      fecha: fixture.fixture.date,
      prediccionGanador: prediccion?.predictions?.winner?.name ?? "Sin datos",
      prediccionGoles: prediccion?.predictions?.goals?.home ?? null,
      esPro: false,
      finalizado: false,
      resultado: null,
      acertado: null,
    });
  }

  return deLigas.length;
}

module.exports = { procesarFixturesDeLigas, LIGAS_IDS };