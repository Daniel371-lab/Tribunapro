// ==== CONFIGURACIÓN DE LA PREDICCIÓN ====
const PESO_H2H   = 25;
const PESO_FORMA = 32;
const PESO_TABLA = 43;

const BASE_LOCAL = 44;
const BASE_EMPATE = 26;
const BASE_VISITANTE = 30;

const PROMEDIO_GOLES_LIGA = 1.35;
const PARTIDOS_PARA_CONFIANZA_PLENA = 5;
const PARTIDOS_MINIMOS_PROMEDIO_REAL = 6;
const PARTIDOS_MINIMOS_RESULTADO = 5;

const VENTAJA_LOCAL_LAMBDA = 1.15;
const H2H_SUAVIZADO_K = 5;

const DEFENSAS_MALAS_UMBRAL = 4.0;
const ATAQUES_BAJOS_UMBRAL = 3.5;
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
  promedioLiga,
}) {
  // Partidos jugados por cada equipo: se usan en toda la función (goles,
  // resultado y quién marca), por eso se declaran una sola vez, arriba de todo.
  const pjL = statsLocal?.partidosJugados || 0;
  const pjV = statsVisitante?.partidosJugados || 0;

  // ---- 1. Probabilidad 1X2 ----
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
    empate = BASE_EMPATE;
  }

  const suma = local + empate + visitante;
  local = Math.round((local / suma) * 100);
  empate = Math.round((empate / suma) * 100);
  visitante = 100 - local - empate;

  // ---- 2. Goles esperados con Poisson ----
  let probOver25 = 50;
  let probBTTS = 50;
  let ataqueL = 1.0, defensaV = 1.0;
  let ataqueV = 1.0, defensaL = 1.0;
  const muestraChica = pjL < 5 || pjV < 5;

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

    // El límite del loop depende del lambda. Cuando lambda es alto (muchos
    // goles esperados), hay que sumar más marcadores o se pierde
    // probabilidad y el modelo da resultados absurdos (por ejemplo, -2.5
    // cuando el total esperado es 8 goles). Se calcula como
    // lambda + 5*√lambda, con tope de 20 para no explotar el cómputo.
    const limiteL = Math.min(20, Math.ceil(lambdaLocal + 5 * Math.sqrt(lambdaLocal)));
    const limiteV = Math.min(20, Math.ceil(lambdaVisitante + 5 * Math.sqrt(lambdaVisitante)));

    let probOver25Sum = 0;
    let probBTTSSum = 0;

    for (let gL = 0; gL <= limiteL; gL++) {
      for (let gV = 0; gV <= limiteV; gV++) {
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
  const brecha = local - visitante;

  const ambosConMinimoPartidos = pjL >= PARTIDOS_MINIMOS_RESULTADO && pjV >= PARTIDOS_MINIMOS_RESULTADO;

  const hayDatosTabla = posicionLocal != null && posicionVisitante != null;
  const localVentajaPuestos = hayDatosTabla && (posicionVisitante - posicionLocal) >= 5;
  const visitanteVentajaPuestos = hayDatosTabla && (posicionLocal - posicionVisitante) >= 5;

  if (ambosConMinimoPartidos && brecha >= (localVentajaPuestos ? 28 : 33)) {
    predicciones.push({
      tipo: "resultado",
      texto: `Gana ${nombreLocal}`,
      criterio: { resultados: ["local"] },
    });
  } else if (ambosConMinimoPartidos && -brecha >= (visitanteVentajaPuestos ? 28 : 33)) {
    predicciones.push({
      tipo: "resultado",
      texto: `Gana ${nombreVisitante}`,
      criterio: { resultados: ["visitante"] },
    });
  } else if (local + empate >= (localVentajaPuestos ? 70 : 73)) {
    predicciones.push({
      tipo: "resultado",
      texto: `Doble oportunidad ${nombreLocal} o empate`,
      criterio: { resultados: ["local", "empate"] },
    });
  } else if (visitante + empate >= (visitanteVentajaPuestos ? 70 : 73)) {
    predicciones.push({
      tipo: "resultado",
      texto: `Doble oportunidad ${nombreVisitante} o empate`,
      criterio: { resultados: ["visitante", "empate"] },
    });
  }

  // Categoría: Goles totales
  const defensasMalas = (defensaL + defensaV) > DEFENSAS_MALAS_UMBRAL;
  const ataquesBajos = (ataqueL + ataqueV) < ATAQUES_BAJOS_UMBRAL;
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
    (probOver25 >= 50) ||
    (ataqueL + ataqueV >= 2.5) ||
    (probBTTS >= 55)
  ) {
    predicciones.push({
      tipo: "goles_totales",
      texto: "+1.5 goles en el partido",
      criterio: { umbral: 1.5, direccion: "mas" },
    });
  }

  // Si ya dijimos "Gana X", no repetimos "X va a marcar"
  const yaGanaLocal = predicciones.some(
    (p) => p.tipo === "resultado" && p.criterio.resultados.length === 1 && p.criterio.resultados[0] === "local"
  );
  const yaGanaVisitante = predicciones.some(
    (p) => p.tipo === "resultado" && p.criterio.resultados.length === 1 && p.criterio.resultados[0] === "visitante"
  );

  // Umbrales de ataque/defensa: más exigentes cuando el equipo tiene pocos
  // partidos jugados, para no confiar en un dato aislado y ruidoso.
  const umbralAtaqueL = pjL < 5 ? 1.7 : 1.4;
  const umbralDefensaL = pjL < 5 ? 1.7 : 1.3;
  const umbralDefensaLRival = pjL < 5 ? 1.7 : 1.35;
  const umbralAtaqueV = pjV < 5 ? 1.7 : 1.4;
  const umbralDefensaV = pjV < 5 ? 1.7 : 1.3;
  const umbralDefensaVRival = pjV < 5 ? 1.7 : 1.35;

  // Categoría: Ambos marcan / marca un equipo puntual
  if (probBTTS >= 60 && (defensaL >= umbralDefensaL || defensaV >= umbralDefensaV)) {
    predicciones.push({
      tipo: "ambos_marcan",
      texto: "Ambos equipos van a marcar",
      criterio: {},
    });
  } else {
    const localMarca =
      !yaGanaLocal && probBTTS >= 55 && ataqueL >= umbralAtaqueL && defensaV >= umbralDefensaVRival;
    const visitanteMarca =
      !yaGanaVisitante && probBTTS >= 55 && ataqueV >= umbralAtaqueV && defensaL >= umbralDefensaLRival;

    if (localMarca && visitanteMarca) {
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

  return {
    porcentajeLocal: local,
    porcentajeEmpate: empate,
    porcentajeVisitante: visitante,
    predicciones,
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