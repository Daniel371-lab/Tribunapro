const axios = require("axios");

const API_KEY = process.env.API_FOOTBALL_KEY;

const cliente = axios.create({
  baseURL: "https://v3.football.api-sports.io",
  headers: { "x-apisports-key": API_KEY },
});

async function obtenerFixturesPorFecha(fecha) {
  const respuesta = await cliente.get("/fixtures", { params: { date: fecha } });
  return respuesta.data.response;
}

async function obtenerPrediccion(fixtureId) {
  const respuesta = await cliente.get("/predictions", { params: { fixture: fixtureId } });
  return respuesta.data.response[0];
}

module.exports = { obtenerFixturesPorFecha, obtenerPrediccion };