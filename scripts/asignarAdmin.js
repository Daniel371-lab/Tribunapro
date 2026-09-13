const admin = require("firebase-admin");

const EMAIL_ADMIN = "jplabscreator@gmail.com";

let serviceAccount;
try {
  const decodificado = Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64, "base64").toString("utf-8");
  serviceAccount = JSON.parse(decodificado);
} catch (err) {
  console.error("La credencial no se pudo leer correctamente:", err.message);
  process.exit(1);
}

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

async function main() {
  const usuario = await admin.auth().getUserByEmail(EMAIL_ADMIN);
  await admin.auth().setCustomUserClaims(usuario.uid, { admin: true });
  console.log(`Listo — ${EMAIL_ADMIN} (uid: ${usuario.uid}) ahora tiene el claim admin:true`);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });