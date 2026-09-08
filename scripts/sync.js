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

function datosDeEquipoEnTabla(tabla, equipoId) {
  if (!tabla || !tabla.standings) return null;
  const grupoTotal = tabla.standings.find((s) => s.type === "TOTAL");
  if (!grupoTotal) return null;
  const fila = grupoTotal.table.find((f) => f.team.id === equipoId);
  if (!fila) return null;
  return { posicion: fila.position, forma: fila.form, totalEquipos: grupoTotal.table.length };
}

async function armarPrediccion(match) {
  let h2h = null;
  try {
    h2h = await obtenerHeadToHead(match.id);
  } catch (err) {
    console.error(`No se pudo traer head2head de match=${match.id}:`, err.message);
  }

  const tabla = await obtenerTablaCacheada(match.competition.code);
  const datosLocal = datosDeEquipoEnTabla(tabla, match.homeTeam.id);
  const datosVisitante = datosDeEquipoEnTabla(tabla, match.awayTeam.id);

  const prediccion = calcularPrediccion({
    h2h,
    idLocal: match.homeTeam.id,
    formaLocal: datosLocal?.forma,
    formaVisitante: datosVisitante?.forma,
    posicionLocal: datosLocal?.posicion,
    posicionVisitante: datosVisitante?.posicion,
    totalEquipos: datosLocal?.totalEquipos,
    nombreLocal: match.homeTeam.name,
    nombreVisitante: match.awayTeam.name,
  });

  const h2hTexto = (h2h?.matches ?? [])
    .slice(0, 5)
    .map((p) => `${p.homeTeam.name} ${p.score.fullTime.home}-${p.score.fullTime.away} ${p.awayTeam.name}`);

  return { prediccion, h2hTexto };
}

async function procesarPartidosNuevos(matches) {
  let nuevos = 0;
  for (const match of matches) {
    if (!esCompetenciaValida(match)) continue;

    const id = String(match.id);
    const doc = await db.collection("partidos").doc(id).get();
    if (doc.exists) continue;

    const { prediccion, h2hTexto } = await armarPrediccion(match);
    const { nombre, tipo } = datosCompetencia(match.competition.code);

    await db.collection("partidos").doc(id).set({
      tipo,
      competenciaId: match.competition.code,
      competenciaNombre: nombre,
      equipoLocal: match.homeTeam.name,
      escudoLocal: match.homeTeam.crest || null,
      equipoVisitante: match.awayTeam.name,
      escudoVisitante: match.awayTeam.crest || null,
      fecha: match.utcDate,
      prediccionGanador: prediccion.ganador,
      prediccionGoles: null,
      porcentajeLocal: prediccion.porcentajeLocal,
      porcentajeEmpate: prediccion.porcentajeEmpate,
      porcentajeVisitante: prediccion.porcentajeVisitante,
      consejo: prediccion.consejo,
      h2h: h2hTexto.length > 0 ? h2hTexto : null,
      esPro: false,
      finalizado: false,
      resultado: null,
      acertado: null,
    });
    nuevos++;
  }
  return nuevos;
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

  const actualizados = await actualizarResultados(partidos);
  const nuevos = await procesarPartidosNuevos(partidos);
  const borrados = await purgarVencidos();

  console.log(`Nuevos: ${nuevos} | Resultados actualizados: ${actualizados} | Purgados: ${borrados}`);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
