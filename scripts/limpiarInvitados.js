const admin = require("firebase-admin");

const DIAS_INACTIVIDAD = 7;

let serviceAccount;
try {
  const decodificado = Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64, "base64").toString("utf-8");
  serviceAccount = JSON.parse(decodificado);
  console.log("Credencial OK — proyecto:", serviceAccount.project_id);
} catch (err) {
  console.error("La credencial no se pudo leer correctamente:", err.message);
  process.exit(1);
}

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

function esInvitado(usuario) {
  return usuario.providerData.length === 0;
}

function inactivoHaceMas(usuario, dias) {
  const ultimoAcceso = new Date(usuario.metadata.lastSignInTime).getTime();
  const limite = Date.now() - dias * 24 * 60 * 60 * 1000;
  return ultimoAcceso < limite;
}

async function listarTodosLosUsuarios() {
  const usuarios = [];
  let paginaSiguiente;
  do {
    const resultado = await admin.auth().listUsers(1000, paginaSiguiente);
    usuarios.push(...resultado.users);
    paginaSiguiente = resultado.pageToken;
  } while (paginaSiguiente);
  return usuarios;
}

async function main() {
  const todos = await listarTodosLosUsuarios();
  const paraBorrar = todos.filter((u) => esInvitado(u) && inactivoHaceMas(u, DIAS_INACTIVIDAD));

  if (paraBorrar.length === 0) {
    console.log("No hay invitados inactivos para borrar.");
    return;
  }

  for (const usuario of paraBorrar) {
    await db.collection("usuarios").doc(usuario.uid).delete().catch(() => {});
    await admin.auth().deleteUser(usuario.uid);
  }

  console.log(`Borrados ${paraBorrar.length} invitado(s) inactivos hace más de ${DIAS_INACTIVIDAD} días.`);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });