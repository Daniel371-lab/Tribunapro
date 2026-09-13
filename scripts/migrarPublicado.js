const admin = require("firebase-admin");

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

async function main() {
  const snap = await db.collection("partidos").get();
  const pendientes = snap.docs.filter((doc) => doc.data().publicado === undefined);

  if (pendientes.length === 0) {
    console.log("No hay partidos sin el campo publicado. Nada que migrar.");
    return;
  }

  const batch = db.batch();
  pendientes.forEach((doc) => batch.update(doc.ref, { publicado: true }));
  await batch.commit();

  console.log(`Migrados ${pendientes.length} partido(s) existentes a publicado: true.`);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });