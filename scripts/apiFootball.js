const axios = require("axios");

const API_KEY = process.env.API_FOOTBALL_KEY;

const cliente = axios.create({
  baseURL: "https://v3.football.api-sports.io",
  headers: { "x-apisports-key": API_KEY },
});

function verificarErrores(data, contexto) {
  const errores = data.errors;
  const tieneErrores = Array.isArray(errores) ? errores.length > 0 : Object.keys(errores || {}).length > 0;
  if (tieneErrores) {
    throw new Error(`API-Football devolvió un error en ${contexto}: ${JSON.stringify(errores)}`);
  }
}

async function obtenerFixturesPorFecha(fecha) {
  const respuesta = await cliente.get("/fixtures", { params: { date: fecha } });
  verificarErrores(respuesta.data, `fixtures fecha=${fecha}`);
  return respuesta.data.response;
}

async function obtenerPrediccion(fixtureId) {
  const respuesta = await cliente.get("/predictions", { params: { fixture: fixtureId } });
  verificarErrores(respuesta.data, `predictions fixture=${fixtureId}`);
  return respuesta.data.response[0];
}

module.exports = { obtenerFixturesPorFecha, obtenerPrediccion };