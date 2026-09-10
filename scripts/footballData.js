const axios = require("axios");

const API_TOKEN = process.env.FOOTBALL_DATA_TOKEN;
const ESPERA_ENTRE_LLAMADAS_MS = 6500; // límite free: 10 req/min, dejamos margen

const cliente = axios.create({
  baseURL: "https://api.football-data.org/v4",
  headers: { "X-Auth-Token": API_TOKEN },
});

function esperar(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function llamar(ruta, params, contexto) {
  await esperar(ESPERA_ENTRE_LLAMADAS_MS);
  try {
    const respuesta = await cliente.get(ruta, { params });
    return respuesta.data;
  } catch (err) {
    const detalle = err.response?.data?.message || err.message;
    throw new Error(`football-data.org devolvió un error en ${contexto}: ${detalle}`);
  }
}

async function obtenerPartidos(dateFrom, dateTo) {
  const data = await llamar("/matches", { dateFrom, dateTo }, `matches ${dateFrom}→${dateTo}`);
  return data.matches || [];
}

async function obtenerHeadToHead(matchId) {
  return llamar(`/matches/${matchId}/head2head`, { limit: 5 }, `head2head match=${matchId}`);
}

async function obtenerTabla(competicionCodigo) {
  return llamar(`/competitions/${competicionCodigo}/standings`, {}, `standings ${competicionCodigo}`);
}

module.exports = { obtenerPartidos, obtenerHeadToHead, obtenerTabla };