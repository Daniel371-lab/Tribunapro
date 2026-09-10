const admin = require("firebase-admin");
const { obtenerPartidos, obtenerHeadToHead, obtenerTabla } = require("./footballData");
const { esCompetenciaValida, datosCompetencia } = require("./competencias");
const { calcularPrediccion } = require("./prediccion");

let serviceAccount;
try {
  const decodificado = Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64, "base64").toString("utf-8");
  serviceAccount = JSON.parse(decodificado);
  console.log("Credencial OK — proyecto:", serviceAccount.project_id, "| cuenta:", serviceAccount.client_email);
} catch (err) {
  console.error("La credencial no se pudo leer correctamente:", err.message);
  process.exit(1);
}

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const tablasCache = {};

function formatearFecha(date) {
  return date.toISOString().split("T")[0];
}

async function obtenerTablaCacheada(codigo) {
  if (tablasCache[codigo] !== undefined) return tablasCache[codigo];
  try {
    const tabla = await obtenerTabla(codigo);
    tablasCache[codigo] = tabla;
    return tabla;
  } catch (err) {
    console.error(`No se pudo traer tabla de ${codigo}:`, err.message);
    tablasCache[codigo] = null;
    return null;
  }
}

function statsDeEquipoEnTabla(tabla, equipoId) {
  if (!tabla || !tabla.standings) return null;
  const grupoTotal = tabla.standings.find((s) => s.type === "TOTAL");
  if (!grupoTotal) return null;
  const fila = grupoTotal.table.find((f) => f.team.id === equipoId);
  if (!fila) return null;
  return {
    posicion: fila.position,
    puntos: fila.points,
    partidosJugados: fila.playedGames,
    ganados: fila.won,
    empatados: fila.draw,
    perdidos: fila.lost,
    golesFavor: fila.goalsFor,
    golesContra: fila.goalsAgainst,
    diferenciaGol: fila.goalDifference,
    forma: fila.form,
    totalEquipos: grupoTotal.table.length,
  };
}

async function armarPrediccion(match) {
  let h2h = null;
  try {
    h2h = await obtenerHeadToHead(match.id);
  } catch (err) {
    console.error(`No se pudo traer head2head de match=${match.id}:`, err.message);
  }

  const tabla = await obtenerTablaCacheada(match.competition.code);
  const statsLocal = statsDeEquipoEnTabla(tabla, match.homeTeam.id);
  const statsVisitante = statsDeEquipoEnTabla(tabla, match.awayTeam.id);

  const prediccion = calcularPrediccion({
    h2h,
    idLocal: match.homeTeam.id,
    formaLocal: statsLocal?.forma,
    formaVisitante: statsVisitante?.forma,
    posicionLocal: statsLocal?.posicion,
    posicionVisitante: statsVisitante?.posicion,
    totalEquipos: statsLocal?.totalEquipos,
    nombreLocal: match.homeTeam.name,
    nombreVisitante: match.awayTeam.name,
  });

  const h2hDatos = (h2h?.matches ?? [])
    .slice(0, 5)
    .map((p) => ({
      equipoLocal: p.homeTeam.name,
      golesLocal: p.score.fullTime.home,
      equipoVisitante: p.awayTeam.name,
      golesVisitante: p.score.fullTime.away,
    }));

  return { prediccion, h2hDatos };
}

function statsParaGuardar(stats) {
  if (!stats) return null;
  return {
    posicion: stats.posicion,
    puntos: stats.puntos,
    partidosJugados: stats.partidosJugados,
    ganados: stats.ganados,
    empatados: stats.empatados,
    perdidos: stats.perdidos,
    golesFavor: stats.golesFavor,
    golesContra: stats.golesContra,
    diferenciaGol: stats.diferenciaGol,
  };
}

async function datosExtraDelPartido(match) {
  const tabla = await obtenerTablaCacheada(match.competition.code);
  const statsLocal = statsDeEquipoEnTabla(tabla, match.homeTeam.id);
  const statsVisitante = statsDeEquipoEnTabla(tabla, match.awayTeam.id);

  return {
    jornada: match.matchday ?? null,
    medioTiempoLocal: match.score?.halfTime?.home ?? null,
    medioTiempoVisitante: match.score?.halfTime?.away ?? null,
    statsLocal: statsParaGuardar(statsLocal),
    statsVisitante: statsParaGuardar(statsVisitante),
  };
}

async function procesarPartidos(matches) {
  let nuevos = 0;
  let actualizadosExtra = 0;

  for (const match of matches) {
    if (!esCompetenciaValida(match)) continue;

    const id = String(match.id);
    const ref = db.collection("partidos").doc(id);
    const doc = await ref.get();

    const escudoLocal = match.homeTeam.crest || null;
    const escudoVisitante = match.awayTeam.crest || null;
    const extra = await datosExtraDelPartido(match);

    if (!doc.exists) {
      const { prediccion, h2hDatos } = await armarPrediccion(match);
      const { nombre, tipo } = datosCompetencia(match.competition.code);

      await ref.set({
        tipo,
        competenciaId: match.competition.code,
        competenciaNombre: nombre,
        equipoLocal: match.homeTeam.name,
        escudoLocal,
        equipoVisitante: match.awayTeam.name,
        escudoVisitante,
        fecha: match.utcDate,
        prediccionGanador: prediccion.ganador,
        prediccionGoles: null,
        porcentajeLocal: prediccion.porcentajeLocal,
        porcentajeEmpate: prediccion.porcentajeEmpate,
        porcentajeVisitante: prediccion.porcentajeVisitante,
        consejo: prediccion.consejo,
        h2h: h2hDatos.length > 0 ? h2hDatos : null,
        esPro: false,
        finalizado: false,
        resultado: null,
        acertado: null,
        ...extra,
      });
      nuevos++;
    } else {
      // Actualiza escudos y los datos extra (posición, stats, medio tiempo, etc.)
      // en partidos que ya existían, sin tocar la predicción ni el h2h original.
      await ref.set({
        escudoLocal,
        escudoVisitante,
        ...extra,
      }, { merge: true });
      actualizadosExtra++;
    }
  }
  return { nuevos, actualizadosExtra };
}

async function actualizarResultados(matches) {
  const finalizados = matches.filter((m) => m.status === "FINISHED");

  let actualizados = 0;
  for (const match of finalizados) {
    const id = String(match.id);
    const ref = db.collection("partidos").doc(id);
    const doc = await ref.get();
    if (!doc.exists || doc.data().finalizado) continue;

    const golesLocal = match.score.fullTime.home;
    const golesVisitante = match.score.fullTime.away;
    const ganadorReal =
      golesLocal > golesVisitante ? match.homeTeam.name
      : golesVisitante > golesLocal ? match.awayTeam.name
      : "Empate";

    const acerto = doc.data().prediccionGanador === ganadorReal;

    await ref.update({
      finalizado: true,
      resultado: `${golesLocal}-${golesVisitante}`,
      acertado: acerto,
      escudoLocal: match.homeTeam.crest || null,
      escudoVisitante: match.awayTeam.crest || null,
      medioTiempoLocal: match.score?.halfTime?.home ?? null,
      medioTiempoVisitante: match.score?.halfTime?.away ?? null,
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
  const dentroDeDosDias = new Date(hoy);
  dentroDeDosDias.setDate(dentroDeDosDias.getDate() + 2);

  const desde = formatearFecha(hoy);
  const hasta = formatearFecha(dentroDeDosDias);

  console.log(`Trayendo partidos de ${desde} a ${hasta}...`);
  const partidos = await obtenerPartidos(desde, hasta);
  console.log(`Total partidos recibidos: ${partidos.length}`);

  const actualizadosResultados = await actualizarResultados(partidos);
  const { nuevos, actualizadosExtra } = await procesarPartidos(partidos);
  const borrados = await purgarVencidos();

  console.log(`Nuevos: ${nuevos} | Actualizados con datos extra: ${actualizadosExtra} | Resultados actualizados: ${actualizadosResultados} | Purgados: ${borrados}`);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });