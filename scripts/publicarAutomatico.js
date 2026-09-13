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
  const snap = await db.collection("partidos").where("publicado", "==", false).get();

  if (snap.empty) {
    console.log("No hay partidos pendientes de publicar.");
    return;
  }

  const batch = db.batch();
  snap.docs.forEach((doc) => {
    batch.update(doc.ref, { publicado: true, esPro: false });
  });
  await batch.commit();

  console.log(`Publicados automáticamente ${snap.docs.length} partido(s) sin revisión manual (esPro: false).`);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });