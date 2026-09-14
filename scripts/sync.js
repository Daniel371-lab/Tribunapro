// ==== CONFIGURACIÓN DE LA PREDICCIÓN ====
const PESO_H2H   = 35;
const PESO_FORMA = 25;
const PESO_TABLA = 40;

const BASE_LOCAL = 40;
const BASE_EMPATE = 26;
const BASE_VISITANTE = 34;

const UMBRAL_EMPATE_TECNICO = 8;

const PROMEDIO_GOLES_LIGA = 1.35;
const PARTIDOS_PARA_CONFIANZA_PLENA = 10;

// Ventaja de jugar en casa, aplicada al modelo de goles (Poisson)
const VENTAJA_LOCAL_LAMBDA = 1.15;

// Pseudo-partidos para suavizar H2H con muestras chicas
const H2H_SUAVIZADO_K = 5;
// =========================================

function factorial(n) {
  if (n === 0 || n === 1) return 1;
  let res = 1;
  for (let i = 2; i <= n; i++) res *= i;
  return res;
}

function poisson(k, lambda) {
  return (Math.pow(lambda, k) * Math.exp(-lambda)) / factorial(k);
}

function suavizarPromedio(promedioReal, partidosJugados) {
  const peso = Math.min(partidosJugados, PARTIDOS_PARA_CONFIANZA_PLENA) / PARTIDOS_PARA_CONFIANZA_PLENA;
  return promedioReal * peso + PROMEDIO_GOLES_LIGA * (1 - peso);
}

function puntosDeH2H(h2h, idLocal) {
  const agregados = h2h?.aggregates;
  const total = agregados?.numberOfMatches || 0;
  if (!agregados || total === 0) return { local: 0, empate: 0, visitante: 0, total: 0 };

  const equipoEsLocalEnAgregado = agregados.homeTeam?.id === idLocal;
  const victoriasLocal = equipoEsLocalEnAgregado ? agregados.homeTeam.wins : agregados.awayTeam.wins;
  const victoriasVisitante = equipoEsLocalEnAgregado ? agregados.awayTeam.wins : agregados.homeTeam.wins;
  const empates = agregados.homeTeam?.draws ?? 0;

  // Suavizado Laplace: K pseudo-partidos "neutros" para que un H2H con pocos
  // partidos no dispare valores extremos (100%, 0%).
  const totalSuav = total + 2 * H2H_SUAVIZADO_K;

  return {
    local: ((victoriasLocal + H2H_SUAVIZADO_K) / totalSuav) * 100,
    empate: ((empates + H2H_SUAVIZADO_K) / totalSuav) * 100,
    visitante: ((victoriasVisitante + H2H_SUAVIZADO_K) / totalSuav) * 100,
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
  // ---- 1. Probabilidad 1X2 (esto alimenta la barra de Probabilidades) ----
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
    // Sin H2H el empate usa todo su valor base.
    empate = BASE_EMPATE;
  }

  const suma = local + empate + visitante;
  local = Math.round((local / suma) * 100);
  empate = Math.round((empate / suma) * 100);
  visitante = 100 - local - empate;

  // ---- 2. Goles esperados con distribución de Poisson ----
  let probOver25 = 50;
  let probBTTS = 50;
  let ataqueL = 1.0, defensaV = 1.0;
  let ataqueV = 1.0, defensaL = 1.0;
  const pjL = statsLocal?.partidosJugados || 0;
  const pjV = statsVisitante?.partidosJugados || 0;
  const muestraChica = pjL < 5 || pjV < 5;

  if (pjL > 0 && pjV > 0) {
    const gFavorLocal = suavizarPromedio((statsLocal.golesFavor || 0) / pjL, pjL);
    const gContraLocal = suavizarPromedio((statsLocal.golesContra || 0) / pjL, pjL);
    const gFavorVisita = suavizarPromedio((statsVisitante.golesFavor || 0) / pjV, pjV);
    const gContraVisita = suavizarPromedio((statsVisitante.golesContra || 0) / pjV, pjV);

    const lambdaLocal = Math.max(0.2, (gFavorLocal * gContraVisita * VENTAJA_LOCAL_LAMBDA) / PROMEDIO_GOLES_LIGA);
    const lambdaVisitante = Math.max(0.2, (gFavorVisita * gContraLocal) / PROMEDIO_GOLES_LIGA);

    ataqueL = gFavorLocal;
    defensaL = gContraLocal;
    ataqueV = gFavorVisita;
    defensaV = gContraVisita;

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

  // ---- 3. Armado de la lista de predicciones ----
  const predicciones = [];

  // ===== Categoría: Resultado (1X2) =====
  // Umbrales más laxos que antes para cubrir más partidos.
  const brecha = local - visitante;

  if (brecha >= 18 || (local >= 44 && empate <= 30)) {
    predicciones.push({
      tipo: "resultado",
      texto: `Gana ${nombreLocal}`,
      criterio: { resultados: ["local"] },
    });
  } else if (-brecha >= 18 || (visitante >= 44 && empate <= 30)) {
    predicciones.push({
      tipo: "resultado",
      texto: `Gana ${nombreVisitante}`,
      criterio: { resultados: ["visitante"] },
    });
  } else if (local + empate >= 62) {
    predicciones.push({
      tipo: "resultado",
      texto: `Doble oportunidad ${nombreLocal} o empate`,
      criterio: { resultados: ["local", "empate"] },
    });
  } else if (visitante + empate >= 62) {
    predicciones.push({
      tipo: "resultado",
      texto: `Doble oportunidad ${nombreVisitante} o empate`,
      criterio: { resultados: ["visitante", "empate"] },
    });
  } else if (empate >= 26 && empate > local && empate > visitante) {
    predicciones.push({
      tipo: "resultado",
      texto: "Empate probable",
      criterio: { resultados: ["empate"] },
    });
  }
  // =====================================

  // ---- Categoría: Goles totales del partido (sin cambios) ----
  if (probOver25 >= 60) {
    predicciones.push({
      tipo: "goles_totales",
      texto: "+2.5 goles en el partido",
      criterio: { umbral: 2.5, direccion: "mas" },
    });
  } else if (probOver25 <= 40) {
    predicciones.push({
      tipo: "goles_totales",
      texto: "-2.5 goles en el partido",
      criterio: { umbral: 2.5, direccion: "menos" },
    });
  } else if (probBTTS >= 55 && probOver25 >= 50) {
    predicciones.push({
      tipo: "goles_totales",
      texto: "+1.5 goles en el partido",
      criterio: { umbral: 1.5, direccion: "mas" },
    });
  }

  // Si ya dijimos "Gana X" en la categoría de Resultado, no tiene sentido
  // repetir "X va a marcar" por separado.
  const yaGanaLocal = predicciones.some(
    (p) => p.tipo === "resultado" && p.criterio.resultados.length === 1 && p.criterio.resultados[0] === "local"
  );
  const yaGanaVisitante = predicciones.some(
    (p) => p.tipo === "resultado" && p.criterio.resultados.length === 1 && p.criterio.resultados[0] === "visitante"
  );

  // ---- Categoría: Ambos marcan / marca un equipo puntual (sin cambios) ----
  if (probBTTS >= 65) {
    predicciones.push({
      tipo: "ambos_marcan",
      texto: "Ambos equipos van a marcar",
      criterio: {},
    });
  } else {
    if (!yaGanaLocal && probBTTS >= 50 && ataqueL >= 1.3 && defensaV >= 1.3) {
      predicciones.push({
        tipo: "gol_equipo",
        texto: `${nombreLocal} va a marcar`,
        criterio: { equipo: "local" },
      });
    }
    if (!yaGanaVisitante && probBTTS >= 50 && ataqueV >= 1.3 && defensaL >= 1.3) {
      predicciones.push({
        tipo: "gol_equipo",
        texto: `${nombreVisitante} va a marcar`,
        criterio: { equipo: "visitante" },
      });
    }
  }

  // Filtro muestra chica (igual que antes: solo quita goles totales)
  let prediccionesFiltradas = muestraChica
    ? predicciones.filter((p) => p.tipo !== "goles_totales")
    : predicciones;

  // ===== FALLBACK: garantizar al menos 1 predicción de resultado =====
  // Si tras todo el análisis no quedó ninguna predicción de tipo "resultado",
  // agregamos la más probable según el modelo 1X2. Así ningún partido queda
  // vacío. Puede que sea una predicción débil, pero la app ya muestra el aviso
  // de "inicio de temporada" cuando corresponde.
  const tieneResultado = prediccionesFiltradas.some((p) => p.tipo === "resultado");
  if (!tieneResultado) {
    if (local >= visitante && local >= empate) {
      prediccionesFiltradas.push({
        tipo: "resultado",
        texto: `Gana ${nombreLocal}`,
        criterio: { resultados: ["local"] },
      });
    } else if (visitante >= local && visitante >= empate) {
      prediccionesFiltradas.push({
        tipo: "resultado",
        texto: `Gana ${nombreVisitante}`,
        criterio: { resultados: ["visitante"] },
      });
    } else {
      prediccionesFiltradas.push({
        tipo: "resultado",
        texto: "Empate probable",
        criterio: { resultados: ["empate"] },
      });
    }
  }
  // ==================================================================

  return {
    porcentajeLocal: local,
    porcentajeEmpate: empate,
    porcentajeVisitante: visitante,
    predicciones: prediccionesFiltradas,
    muestraChica,
  };
}

function evaluarPrediccion(prediccion, { resultadoReal, golesLocal, golesVisitante }) {
  switch (prediccion.tipo) {
    case "resultado":
      return prediccion.criterio.resultados.includes(resultadoReal);
    case "goles_totales": {
      const total = golesLocal + golesVisitante;
      return prediccion.criterio.direccion === "mas"
        ? total > prediccion.criterio.umbral
        : total < prediccion.criterio.umbral;
    }
    case "ambos_marcan":
      return golesLocal > 0 && golesVisitante > 0;
    case "gol_equipo":
      return prediccion.criterio.equipo === "local" ? golesLocal > 0 : golesVisitante > 0;
    default:
      return null;
  }
}

module.exports = { calcularPrediccion, evaluarPrediccion };