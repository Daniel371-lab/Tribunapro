// ==== CONFIGURACIÓN DE LA PREDICCIÓN ====
// Pesos: forma más relevante (refleja el momento actual), H2H con menos
// peso (muestra chica, cambia entre temporadas), tabla como señal dominante.
const PESO_H2H   = 25;
const PESO_FORMA = 32;
const PESO_TABLA = 43;

// Promedios reales del fútbol: local gana ~45%, empate ~26%, visitante ~29%.
// Se usan solo cuando no hay H2H entre los dos equipos.
const BASE_LOCAL = 44;
const BASE_EMPATE = 26;
const BASE_VISITANTE = 30;

const UMBRAL_EMPATE_TECNICO = 8;

// Valor por defecto cuando la liga todavía no tiene suficientes datos.
const PROMEDIO_GOLES_LIGA = 1.35;
// A partir del 5to partido jugado, el promedio del equipo se usa al 100%.
const PARTIDOS_PARA_CONFIANZA_PLENA = 5;
// Desde cuántos partidos jugados (mínimo entre ambos equipos) se usa el
// promedio real de la liga en vez del valor por defecto (1.35).
const PARTIDOS_MINIMOS_PROMEDIO_REAL = 6;

// Ventaja de jugar en casa, aplicada al modelo de goles (Poisson).
const VENTAJA_LOCAL_LAMBDA = 1.15;

// Pseudo-partidos para suavizar H2H con muestras chicas.
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

function suavizarPromedio(promedioReal, partidosJugados, promedioLiga) {
  const peso = Math.min(partidosJugados, PARTIDOS_PARA_CONFIANZA_PLENA) / PARTIDOS_PARA_CONFIANZA_PLENA;
  return promedioReal * peso + promedioLiga * (1 - peso);
}

function puntosDeH2H(h2h, idLocal) {
  const agregados = h2h?.aggregates;
  const total = agregados?.numberOfMatches || 0;
  if (!agregados || total === 0) return { local: 0, empate: 0, visitante: 0, total: 0 };

  const equipoEsLocalEnAgregado = agregados.homeTeam?.id === idLocal;
  const victoriasLocal = equipoEsLocalEnAgregado ? agregados.homeTeam.wins : agregados.awayTeam.wins;
  const victoriasVisitante = equipoEsLocalEnAgregado ? agregados.awayTeam.wins : agregados.homeTeam.wins;
  const empates = agregados.homeTeam?.draws ?? 0;

  // Suavizado Laplace: K pseudo-partidos "neutros" para evitar que un H2H
  // con pocos partidos dispare valores extremos (100%, 0%).
  const totalSuav = total + 3 * H2H_SUAVIZADO_K;

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
  promedioLiga,   // promedio real de la liga (puede ser null)
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
    // Sin H2H, el empate usa todo su valor base.
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

  // Decidimos qué promedio de liga usar:
  // - Si la liga ya tiene datos suficientes (ambos equipos jugaron 6+),
  //   usamos el promedio real que viene desde sync.js.
  // - Si no, usamos el valor por defecto (1.35).
  const partidosMinimos = Math.min(pjL, pjV);
  const promedioActivo =
    (promedioLiga != null && partidosMinimos >= PARTIDOS_MINIMOS_PROMEDIO_REAL)
      ? promedioLiga
      : PROMEDIO_GOLES_LIGA;

  if (pjL > 0 && pjV > 0) {
    const gFavorLocal = suavizarPromedio((statsLocal.golesFavor || 0) / pjL, pjL, promedioActivo);
    const gContraLocal = suavizarPromedio((statsLocal.golesContra || 0) / pjL, pjL, promedioActivo);
    const gFavorVisita = suavizarPromedio((statsVisitante.golesFavor || 0) / pjV, pjV, promedioActivo);
    const gContraVisita = suavizarPromedio((statsVisitante.golesContra || 0) / pjV, pjV, promedioActivo);

    const lambdaLocal = Math.max(0.2, (gFavorLocal * gContraVisita * VENTAJA_LOCAL_LAMBDA) / promedioActivo);
    const lambdaVisitante = Math.max(0.2, (gFavorVisita * gContraLocal) / promedioActivo);

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

  // ---- 3. Armado de la lista de predicciones (solo se agregan si hay confianza) ----
  const predicciones = [];

  // Categoría: Resultado
  const brecha = local - visitante;

  // Regla única: "Gana X" solo se dispara cuando la diferencia entre
  // local y visitante es de 25 puntos o más. Se eliminó la condición
  // alternativa (favorito >= 48 con empate bajo) porque en la muestra
  // analizada no aportó ningún acierto y sí varios fallos.
  if (brecha >= 25) {
    predicciones.push({
      tipo: "resultado",
      texto: `Gana ${nombreLocal}`,
      criterio: { resultados: ["local"] },
    });
  } else if (-brecha >= 25) {
    predicciones.push({
      tipo: "resultado",
      texto: `Gana ${nombreVisitante}`,
      criterio: { resultados: ["visitante"] },
    });
  } else if (local + empate >= 70) {
    predicciones.push({
      tipo: "resultado",
      texto: `Doble oportunidad ${nombreLocal} o empate`,
      criterio: { resultados: ["local", "empate"] },
    });
  } else if (visitante + empate >= 70) {
    predicciones.push({
      tipo: "resultado",
      texto: `Doble oportunidad ${nombreVisitante} o empate`,
      criterio: { resultados: ["visitante", "empate"] },
    });
  } else if (empate >= 30 && empate > local && empate > visitante) {
    predicciones.push({
      tipo: "resultado",
      texto: "Empate probable",
      criterio: { resultados: ["empate"] },
    });
  }

  // Categoría: Goles totales del partido
  // Filtro compuesto: bloqueamos +2.5 solo si las defensas son malas Y los
  // ataques son bajos. Con defensas malas pero ataques buenos, dejamos pasar
  // porque el partido probablemente sí tenga goles.
  const defensasMalas = (defensaL + defensaV) > 4.0;
  const ataquesBajos = (ataqueL + ataqueV) < 3.5;
  const partidoCerrado = defensasMalas && ataquesBajos;

  if (probOver25 >= 60 && !partidoCerrado) {
    predicciones.push({
      tipo: "goles_totales",
      texto: "+2.5 goles en el partido",
      criterio: { umbral: 2.5, direccion: "mas" },
    });
  } else if (probOver25 <= 35) {
    predicciones.push({
      tipo: "goles_totales",
      texto: "-2.5 goles en el partido",
      criterio: { umbral: 2.5, direccion: "menos" },
    });
  } else if (
    (probBTTS >= 55 && probOver25 >= 50) ||
    (probOver25 >= 48) ||
    (ataqueL + ataqueV >= 2.5) ||
    (probBTTS >= 50)
  ) {
    predicciones.push({
      tipo: "goles_totales",
      texto: "+1.5 goles en el partido",
      criterio: { umbral: 1.5, direccion: "mas" },
    });
  }

  // Si ya dijimos "Gana X" en la categoría de Resultado, no tiene sentido
  // repetir "X va a marcar" por separado — va implícito en que ganó.
  const yaGanaLocal = predicciones.some(
    (p) => p.tipo === "resultado" && p.criterio.resultados.length === 1 && p.criterio.resultados[0] === "local"
  );
  const yaGanaVisitante = predicciones.some(
    (p) => p.tipo === "resultado" && p.criterio.resultados.length === 1 && p.criterio.resultados[0] === "visitante"
  );

  // Categoría: Ambos marcan / marca un equipo puntual
  if (probBTTS >= 60) {
    predicciones.push({
      tipo: "ambos_marcan",
      texto: "Ambos equipos van a marcar",
      criterio: {},
    });
  } else {
    // Evaluamos primero si cada equipo marca por separado.
    const localMarca =
      !yaGanaLocal && probBTTS >= 50 && ataqueL >= 1.3 && defensaV >= 1.3;
    const visitanteMarca =
      !yaGanaVisitante && probBTTS >= 50 && ataqueV >= 1.3 && defensaL >= 1.3;

    if (localMarca && visitanteMarca) {
      // Si los dos marcan, se combinan en una sola predicción de "ambos marcan".
      predicciones.push({
        tipo: "ambos_marcan",
        texto: "Ambos equipos van a marcar",
        criterio: {},
      });
    } else {
      if (localMarca) {
        predicciones.push({
          tipo: "gol_equipo",
          texto: `${nombreLocal} va a marcar`,
          criterio: { equipo: "local" },
        });
      }
      if (visitanteMarca) {
        predicciones.push({
          tipo: "gol_equipo",
          texto: `${nombreVisitante} va a marcar`,
          criterio: { equipo: "visitante" },
        });
      }
    }
  }

  // Si la muestra es chica (menos de 5 partidos jugados por algún equipo),
  // no publicamos predicciones de goles: son ruido puro.
  const prediccionesFiltradas = muestraChica
    ? predicciones.filter((p) => p.tipo !== "goles_totales")
    : predicciones;

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