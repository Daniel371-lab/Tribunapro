console.log(">>> sync.js arrancando...");

const admin = require("firebase-admin");
const { obtenerPartidos, obtenerHeadToHead, obtenerTabla } = require("./footballData");
const { esCompetenciaValida, datosCompetencia } = require("./competencias");
const { calcularPrediccion, evaluarPrediccion } = require("./prediccion");

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

// Calcula el promedio real de goles por equipo por partido en una liga,
// usando la tabla completa. Devuelve null si no hay datos suficientes.
function promedioGolesDeTabla(tabla) {
  if (!tabla || !tabla.standings) return null;
  const grupoTotal = tabla.standings.find((s) => s.type === "TOTAL");
  if (!grupoTotal) return null;

  let totalGoles = 0;
  let totalPartidos = 0;

  for (const fila of grupoTotal.table) {
    totalGoles += fila.goalsFor || 0;
    totalPartidos += fila.playedGames || 0;
  }

  if (totalPartidos === 0) return null;
  return totalGoles / totalPartidos;
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

async function datosDelPartido(match) {
  let h2h = null;
  try {
    h2h = await obtenerHeadToHead(match.id);
  } catch (err) {
    console.error(`No se pudo traer head2head de match=${match.id}:`, err.message);
  }

  const tabla = await obtenerTablaCacheada(match.competition.code);
  const statsLocal = statsDeEquipoEnTabla(tabla, match.homeTeam.id);
  const statsVisitante = statsDeEquipoEnTabla(tabla, match.awayTeam.id);
  const promedioLiga = promedioGolesDeTabla(tabla);

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
    statsLocal,
    statsVisitante,
    promedioLiga,
  });

  const h2hDatos = (h2h?.matches ?? [])
    .slice(0, 5)
    .map((p) => ({
      equipoLocal: p.homeTeam.name,
      golesLocal: p.score.fullTime.home,
      equipoVisitante: p.awayTeam.name,
      golesVisitante: p.score.fullTime.away,
    }));

  return {
    jornada: match.matchday ?? null,
    medioTiempoLocal: match.score?.halfTime?.home ?? null,
    medioTiempoVisitante: match.score?.halfTime?.away ?? null,
    statsLocal: statsParaGuardar(statsLocal),
    statsVisitante: statsParaGuardar(statsVisitante),
    porcentajeLocal: prediccion.porcentajeLocal,
    porcentajeEmpate: prediccion.porcentajeEmpate,
    porcentajeVisitante: prediccion.porcentajeVisitante,
    predicciones: prediccion.predicciones.map((p) => ({ ...p, cumplida: null })),
    muestraChica: prediccion.muestraChica,
    h2h: h2hDatos.length > 0 ? h2hDatos : null,
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

    if (!doc.exists) {
      const datos = await datosDelPartido(match);
      const { nombre, tipo } = datosCompetencia(match.competition.code);

      const yaFinalizo = match.status === "FINISHED";
      const golesLocal = match.score?.fullTime?.home ?? null;
      const golesVisitante = match.score?.fullTime?.away ?? null;

      let prediccionesFinales = datos.predicciones;
      let resultado = null;
      let finalizado = false;

      if (yaFinalizo && golesLocal !== null && golesVisitante !== null) {
        const resultadoReal =
          golesLocal > golesVisitante
            ? "local"
            : golesVisitante > golesLocal
            ? "visitante"
            : "empate";

        prediccionesFinales = datos.predicciones.map((p) => ({
          ...p,
          cumplida: evaluarPrediccion(p, { resultadoReal, golesLocal, golesVisitante }),
        }));

        resultado = `${golesLocal}-${golesVisitante}`;
        finalizado = true;
      }

      await ref.set({
        tipo,
        competenciaId: match.competition.code,
        competenciaNombre: nombre,
        equipoLocal: match.homeTeam.name,
        escudoLocal,
        equipoVisitante: match.awayTeam.name,
        escudoVisitante,
        fecha: match.utcDate,
        esPro: false,
        finalizado,
        resultado,
        publicado: false,
        ...datos,
        predicciones: prediccionesFinales,
      });
      nuevos++;
    } else if (!doc.data().finalizado) {
      // IMPORTANTE: acá NO se recalculan predicciones, porcentajes, stats ni H2H.
      // Todo eso queda congelado desde el momento en que se creó el partido.
      const update = { escudoLocal, escudoVisitante };

      const medioL = match.score?.halfTime?.home;
      const medioV = match.score?.halfTime?.away;
      if (medioL != null && medioV != null && doc.data().medioTiempoLocal == null) {
        update.medioTiempoLocal = medioL;
        update.medioTiempoVisitante = medioV;
      }

      await ref.set(update, { merge: true });
      actualizadosExtra++;
    } else {
      await ref.set({ escudoLocal, escudoVisitante }, { merge: true });
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
    const resultadoReal =
      golesLocal > golesVisitante ? "local" : golesVisitante > golesLocal ? "visitante" : "empate";

    const predicciones = (doc.data().predicciones || []).map((p) => ({
      ...p,
      cumplida: evaluarPrediccion(p, { resultadoReal, golesLocal, golesVisitante }),
    }));

    await ref.update({
      finalizado: true,
      resultado: `${golesLocal}-${golesVisitante}`,
      predicciones,
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
  limite.setDate(limite.getDate() - 3);
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
  const ayer = new Date(hoy);
  ayer.setDate(ayer.getDate() - 3);
  const dentroDeDosDias = new Date(hoy);
  dentroDeDosDias.setDate(dentroDeDosDias.getDate() + 2);

  const desde = formatearFecha(ayer);
  const hasta = formatearFecha(dentroDeDosDias);

  console.log(`Trayendo partidos de ${desde} a ${hasta}...`);
  const partidos = await obtenerPartidos(desde, hasta);
  console.log(`Total partidos recibidos: ${partidos.length}`);

  if (partidos.length > 0) {
    console.log(
      "Primeros 3:",
      partidos.slice(0, 3).map((p) => `${p.id} | ${p.status} | ${p.utcDate}`)
    );
  } else {
    console.log("La API no devolvió partidos en este rango de fechas.");
  }

  const { nuevos, actualizadosExtra } = await procesarPartidos(partidos);
  const actualizadosResultados = await actualizarResultados(partidos);
  const borrados = await purgarVencidos();

  console.log(
    `Nuevos: ${nuevos} | Actualizados con datos extra: ${actualizadosExtra} | Resultados actualizados: ${actualizadosResultados} | Purgados: ${borrados}`
  );
}

main()
  .then(() => {})
  .catch((err) => {
    console.error("ERROR en sync.js:", err);
    process.exitCode = 1;
  });