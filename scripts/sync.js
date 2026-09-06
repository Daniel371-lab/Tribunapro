const admin = require("firebase-admin");
const { obtenerFixturesPorFecha, obtenerPrediccion } = require("./apiFootball");
const { esDeLigas } = require("./ligas");
const { esDeCopas } = require("./copas");

const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

function formatearFecha(date) {
  return date.toISOString().split("T")[0];
}

async function procesarFixturesNuevos(fecha) {
  const fixtures = await obtenerFixturesPorFecha(fecha);
  const relevantes = fixtures.filter((f) => esDeLigas(f) || esDeCopas(f));

  let nuevos = 0;
  for (const fixture of relevantes) {
    const id = String(fixture.fixture.id);
    const doc = await db.collection("partidos").doc(id).get();
    if (doc.exists) continue;

    const prediccion = await obtenerPrediccion(fixture.fixture.id);
    const tipo = esDeLigas(fixture) ? "liga" : "copa";

    const h2h = (prediccion?.h2h ?? [])
      .slice(0, 5)
      .map((p) => `${p.teams.home.name} ${p.goals.home}-${p.goals.away} ${p.teams.away.name}`);

    await db.collection("partidos").doc(id).set({
      tipo,
      competenciaId: String(fixture.league.id),
      competenciaNombre: fixture.league.name,
      equipoLocal: fixture.teams.home.name,
      equipoVisitante: fixture.teams.away.name,
      fecha: fixture.fixture.date,
      prediccionGanador: prediccion?.predictions?.winner?.name ?? "Sin datos",
      prediccionGoles: prediccion?.predictions?.goals?.home ?? null,
      porcentajeLocal: prediccion?.predictions?.percent?.home ?? null,
      porcentajeEmpate: prediccion?.predictions?.percent?.draw ?? null,
      porcentajeVisitante: prediccion?.predictions?.percent?.away ?? null,
      consejo: prediccion?.predictions?.advice ?? null,
      h2h: h2h.length > 0 ? h2h : null,
      esPro: tipo === "copa",
      finalizado: false,
      resultado: null,
      acertado: null,
    });
    nuevos++;
  }
  return nuevos;
}

async function actualizarResultados(fecha) {
  const fixtures = await obtenerFixturesPorFecha(fecha);
  const finalizados = fixtures.filter((f) => f.fixture.status.short === "FT");

  let actualizados = 0;
  for (const fixture of finalizados) {
    const id = String(fixture.fixture.id);
    const ref = db.collection("partidos").doc(id);
    const doc = await ref.get();
    if (!doc.exists || doc.data().finalizado) continue;

    const golesLocal = fixture.goals.home;
    const golesVisitante = fixture.goals.away;
    const ganadorReal =
      golesLocal > golesVisitante
        ? fixture.teams.home.name
        : golesVisitante > golesLocal
        ? fixture.teams.away.name
        : "Empate";

    const acerto = doc.data().prediccionGanador === ganadorReal;

    await ref.update({
      finalizado: true,
      resultado: `${golesLocal}-${golesVisitante}`,
      acertado: acerto,
    });
    actualizados++;
  }
  return actualizados;
}

async function purgarVencidos() {
  const limite = new Date();
  limite.setDate(limite.getDate() - 1);
  const snap = await db
    .collection("partidos")
    .where("finalizado", "==", true)
    .where("fecha", "<", limite.toISOString())
    .get();

  let borrados = 0;
  for (const doc of snap.docs) {
    await doc.ref.delete();
    borrados++;
  }
  return borrados;
}

async function main() {
  const hoy = new Date();

  await actualizarResultados(formatearFecha(hoy));

  let totalNuevos = 0;
  for (let i = 0; i <= 2; i++) {
    const fecha = new Date(hoy);
    fecha.setDate(fecha.getDate() + i);
    totalNuevos += await procesarFixturesNuevos(formatearFecha(fecha));
  }

  const borrados = await purgarVencidos();

  console.log(`Nuevos: ${totalNuevos} | Purgados: ${borrados}`);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });