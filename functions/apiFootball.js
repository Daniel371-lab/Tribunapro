const axios = require("axios");
const { defineSecret } = require("firebase-functions/params");

const API_FOOTBALL_KEY = defineSecret("API_FOOTBALL_KEY");

const cliente = axios.create({
  baseURL: "https://v3.football.api-sports.io",
});

async function obtenerFixturesPorFecha(fecha) {
  const respuesta = await cliente.get("/fixtures", {
    params: { date: fecha },
    headers: { "x-apisports-key": API_FOOTBALL_KEY.value() },
  });
  return respuesta.data.response;
}

async function obtenerPrediccion(fixtureId) {
  const respuesta = await cliente.get("/predictions", {
    params: { fixture: fixtureId },
    headers: { "x-apisports-key": API_FOOTBALL_KEY.value() },
  });
  return respuesta.data.response[0];
}

module.exports = { obtenerFixturesPorFecha, obtenerPrediccion, API_FOOTBALL_KEY };