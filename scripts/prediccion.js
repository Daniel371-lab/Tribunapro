// ==== CONFIGURACIÓN DE LA PREDICCIÓN ====
// Tocá estos números para cambiar cómo se calcula. PESO_H2H + PESO_FORMA + PESO_TABLA debe dar 100.
// Aviso: en el plan free, el dato de "forma reciente" siempre viene vacío (null),
// así que PESO_FORMA en la práctica no aporta nada por ahora — queda listo por si
// en el futuro cambian de plan o se calcula la forma por otra vía.
const PESO_H2H = 45;
const PESO_FORMA = 15;
const PESO_TABLA = 40;

// Si nunca se enfrentaron, usamos esta base neutral (el local parte con algo de ventaja)
const BASE_LOCAL = 40;
const BASE_EMPATE = 26;
const BASE_VISITANTE = 34;

// Si la diferencia entre el 1° y 2° puesto del pick es menor a esto, el resultado pasa a ser "Empate"
const UMBRAL_EMPATE_TECNICO = 8;
// =========================================

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
  if (!formaCruda) return 50; // en el plan free casi siempre viene null
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
  h2h, idLocal, formaLocal, formaVisitante,
  posicionLocal, posicionVisitante, totalEquipos,
  nombreLocal, nombreVisitante,
}) {
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

  const ordenado = [
    { nombre: nombreLocal, valor: local },
    { nombre: "Empate", valor: empate },
    { nombre: nombreVisitante, valor: visitante },
  ].sort((a, b) => b.valor - a.valor);

  const ganador = (ordenado[0].valor - ordenado[1].valor) < UMBRAL_EMPATE_TECNICO ? "Empate" : ordenado[0].nombre;

  let consejo = null;
  if (local + empate >= 65) {
    consejo = `Doble oportunidad ${nombreLocal} o empate`;
  } else if (visitante + empate >= 65) {
    consejo = `Doble oportunidad ${nombreVisitante} o empate`;
  } else if (Math.max(local, visitante) >= 55) {
    consejo = `Gana ${local > visitante ? nombreLocal : nombreVisitante}`;
  }

  return { ganador, porcentajeLocal: local, porcentajeEmpate: empate, porcentajeVisitante: visitante, consejo };
}

module.exports = { calcularPrediccion };