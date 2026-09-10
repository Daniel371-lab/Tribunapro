// ==== CONFIGURACIÓN DE LA PREDICCIÓN ====
const PESO_H2H = 45;
const PESO_FORMA = 15;
const PESO_TABLA = 40;

const BASE_LOCAL = 40;
const BASE_EMPATE = 26;
const BASE_VISITANTE = 34;

const UMBRAL_EMPATE_TECNICO = 8;
const PROMEDIO_GOLES_LIGA = 1.35; // Promedio estándar de goles por equipo por partido
// =========================================

// --- FUNCIONES AUXILIARES MATEMÁTICAS (POISSON) ---
function factorial(n) {
  if (n === 0 || n === 1) return 1;
  let res = 1;
  for (let i = 2; i <= n; i++) res *= i;
  return res;
}

// Calcula la probabilidad de que un equipo marque exactamente 'k' goles con una media 'lambda'
function poisson(k, lambda) {
  return (Math.pow(lambda, k) * Math.exp(-lambda)) / factorial(k);
}

// Limpia nombres de equipos
function limpiarNombre(nombre) {
  if (!nombre) return "";
  return nombre
    .replace(/\b(FC|CF|Real|Club|Deportivo|SD|UD)\b/gi, "")
    .trim();
}

// --- EVALUADORES BÁSICOS 1X2 ---
function puntosDeH2H(h2h, idLocal) {
  const agregados = h2h?.aggregates;
  const total = agregados?.numberOfMatches || 0;
  if (!agregados || total === 0) return { local: 0, empate: 0, visitante: 0, total: 0 };

  const equipoEsLocalEnAgregado = agregados.homeTeam?.id === idLocal;
  const victoriasLocal = equipoEsLocalEnAgregado ? agregados.homeTeam.wins : agregados.awayTeam.wins;
  const victoriasVisitante = equipoEsLocalEnAgregado ? agregados.awayTeam.wins : agregados.homeTeam.wins;
  const empates = agregados.homeTeam?.draws ?? 0;

  return {
    local: (victoriasLocal / total) * 100,
    empate: (empates / total) * 100,
    visitante: (victoriasVisitante / total) * 100,
    total,
  };
}

function puntosDeForma(formaCruda) {
  if (!formaCruda) return 50;
  const letras = formaCruda.toUpperCase().split("").filter((c) => c === "W" || c === "D" || c === "L");
  if (letras.length === 0) return 50;
  const puntos = letras.reduce((acc, letra) => acc + (letra === "W" ? 3 : letra === "D" ? 1 : 0), 0);
  return (puntos / (letras.length * 3)) * 100;
}

function puntosDeTabla(posicionLocal, posicionVisitante, totalEquipos) {
  if (!posicionLocal || !posicionVisitante || !totalEquipos) return { local: 50, visitante: 50 };
  const fuerzaLocal = ((totalEquipos - posicionLocal + 1) / totalEquipos) * 100;
  const fuerzaVisitante = ((totalEquipos - posicionVisitante + 1) / totalEquipos) * 100;
  const suma = fuerzaLocal + fuerzaVisitante;
  return { local: (fuerzaLocal / suma) * 100, visitante: (fuerzaVisitante / suma) * 100 };
}

// --- FUNCIÓN PRINCIPAL DE PREDICCIÓN ---
function calcularPrediccion({
  h2h,
  idLocal,
  formaLocal,
  formaVisitante,
  posicionLocal,
  posicionVisitante,
  totalEquipos,
  nombreLocal,
  nombreVisitante,
  statsLocal,
  statsVisitante,
}) {
  // 1. CÁLCULO DE PROBABILIDAD 1X2 (GANADOR)
  const datosH2H = puntosDeH2H(h2h, idLocal);
  const tieneH2H = datosH2H.total > 0;

  const formaL = puntosDeForma(formaLocal);
  const formaV = puntosDeForma(formaVisitante);
  const totalForma = formaL + formaV || 1;
  const formaLocalPct = (formaL / totalForma) * 100;
  const formaVisitantePct = (formaV / totalForma) * 100;

  const tabla = puntosDeTabla(posicionLocal, posicionVisitante, totalEquipos);

  let local, empate, visitante;

  if (tieneH2H) {
    local = (datosH2H.local * PESO_H2H + formaLocalPct * PESO_FORMA + tabla.local * PESO_TABLA) / 100;
    visitante = (datosH2H.visitante * PESO_H2H + formaVisitantePct * PESO_FORMA + tabla.visitante * PESO_TABLA) / 100;
    empate = (datosH2H.empate * PESO_H2H + BASE_EMPATE * (100 - PESO_H2H)) / 100;
  } else {
    local = (BASE_LOCAL * PESO_H2H + formaLocalPct * PESO_FORMA + tabla.local * PESO_TABLA) / 100;
    visitante = (BASE_VISITANTE * PESO_H2H + formaVisitantePct * PESO_FORMA + tabla.visitante * PESO_TABLA) / 100;
    empate = (BASE_EMPATE * PESO_H2H) / 100;
  }

  const suma = local + empate + visitante;
  local = Math.round((local / suma) * 100);
  empate = Math.round((empate / suma) * 100);
  visitante = 100 - local - empate;

  // Determinar ganador sugerido
  const ordenado = [
    { nombre: nombreLocal, valor: local },
    { nombre: "Empate", valor: empate },
    { nombre: nombreVisitante, valor: visitante },
  ].sort((a, b) => b.valor - a.valor);

  const prediccionGanador =
    ordenado[0].valor - ordenado[1].valor < UMBRAL_EMPATE_TECNICO ? "Empate" : ordenado[0].nombre;

  // 2. CÁLCULO DE GOLES CON DISTRIBUCIÓN DE POISSON
  let probOver25 = 50;
  let probBTTS = 50;
  let ataqueL = 1.0, defensaV = 1.0;
  let ataqueV = 1.0, defensaL = 1.0;
  let pjL = statsLocal?.partidosJugados || 0;
  let pjV = statsVisitante?.partidosJugados || 0;

  if (pjL > 0 && pjV > 0) {
    // Promedios por gol
    const gFavorLocal = (statsLocal.golesFavor || 0) / pjL;
    const gContraLocal = (statsLocal.golesContra || 0) / pjL;
    const gFavorVisita = (statsVisitante.golesFavor || 0) / pjV;
    const gContraVisita = (statsVisitante.golesContra || 0) / pjV;

    // Goles esperados (Lambda)
    const lambdaLocal = Math.max(0.2, (gFavorLocal * gContraVisita) / PROMEDIO_GOLES_LIGA);
    const lambdaVisitante = Math.max(0.2, (gFavorVisita * gContraLocal) / PROMEDIO_GOLES_LIGA);

    ataqueL = gFavorLocal;
    defensaL = gContraLocal;
    ataqueV = gFavorVisita;
    defensaV = gContraVisita;

    // Matriz de marcadores posibles (de 0 a 5 goles cada equipo)
    let probOver25Sum = 0;
    let probBTTSSum = 0;

    for (let gL = 0; gL <= 5; gL++) {
      for (let gV = 0; gV <= 5; gV++) {
        const pL = poisson(gL, lambdaLocal);
        const pV = poisson(gV, lambdaVisitante);
        const pMarcador = pL * pV;

        if (gL + gV > 2.5) probOver25Sum += pMarcador;
        if (gL > 0 && gV > 0) probBTTSSum += pMarcador;
      }
    }

    probOver25 = Math.round(probOver25Sum * 100);
    probBTTS = Math.round(probBTTSSum * 100);
  }

  // 3. SELECCIÓN DEL MERCADO DE GOLES
  let prediccionGoles = "Goles: Mercado reservado";
  if (probOver25 >= 60) {
    prediccionGoles = "+2.5 goles";
  } else if (probOver25 <= 40) {
    prediccionGoles = "-2.5 goles";
  } else if (probBTTS >= 55 && probOver25 >= 50) {
    prediccionGoles = "+1.5 goles";
  }

  // 4. GENERACIÓN DE CONSEJO DETALLADO Y TENDENCIAS
  const consejosExtra = [];
  const nl = limpiarNombre(nombreLocal);
  const nv = limpiarNombre(nombreVisitante);

  // Lógica de Ganador / Empate en texto
  const brecha = local - visitante;
  if (brecha >= 30 || (local >= 50 && empate <= 32)) {
    consejosExtra.push(`Victoria: ${nl}`);
  } else if (-brecha >= 30 || (visitante >= 50 && empate <= 32)) {
    consejosExtra.push(`Victoria: ${nv}`);
  } else if (empate >= 33) {
    consejosExtra.push("Analisis: Alta probabilidad de empate");
  }

  // Anotadores / Ambos anotan
  if (probBTTS >= 65) {
    consejosExtra.push("Ambos van a marcar");
  } else {
    if (probBTTS >= 50 && ataqueL >= 1.3 && defensaV >= 1.3) {
      consejosExtra.push(`${nl} va a marcar`);
    }
    if (probBTTS >= 50 && ataqueV >= 1.3 && defensaL >= 1.3) {
      consejosExtra.push(`${nv} va a marcar`);
    }
  }

  let consejoTexto = consejosExtra.join("\n");

  if (pjL < 5 || pjV < 5) {
    consejoTexto += consejoTexto ? "\n" : "";
    consejoTexto += "DATO: Inicio de temporada (Stats volatiles).";
  }

  // 5. RETORNO DE ESTRUCTURA EXACTA PARA FLUTTER
  return {
    prediccionGanador,
    prediccionGoles,
    porcentajeLocal: `${local}%`,
    porcentajeEmpate: `${empate}%`,
    porcentajeVisitante: `${visitante}%`,
    consejo: consejoTexto || null,
  };
}

module.exports = { calcularPrediccion };
