// MongoClient ist die offizielle Klasse aus dem mongodb-Paket,
// um direkt aus Node.js eine Verbindung zur MongoDB herzustellen.
const { MongoClient } = require("mongodb");


// MongoDB-Verbindung:
// - Standard: mongodb://localhost:27017 (Host-Zugriff, lokal und in CI)
// - Überschreibbar per Umgebungsvariable MONGO_URL
//
// "localhost" funktioniert, weil compose.yaml Port 27017 auf den Host freigibt.
// Der Hostname "mongodb" wäre nur innerhalb des Docker-Netzwerks erreichbar.
const mongoUrl = process.env.MONGO_URL || "mongodb://localhost:27017";


// Prüft, ob die MongoDB-Datenbank erreichbar ist und auf Befehle antwortet.
test("MongoDB Verbindung funktioniert", async () => {

  // mongodb v2.x API: MongoClient.connect() gibt direkt ein db-Objekt zurück,
  // kein client-Objekt wie in v3/v4. Deshalb wird db.close() verwendet,
  // nicht client.close().
  const db = await MongoClient.connect(mongoUrl);

  try {

    // Sendet einen Ping-Befehl an MongoDB.
    // Antwortet MongoDB mit { ok: 1 }, ist die Verbindung bestätigt.
    const result = await db.command({
      ping: 1
    });

    // Erwartet erfolgreiche Antwort von MongoDB.
    expect(result.ok).toBe(1);

  } finally {

    // Verbindung immer sauber schließen — auch wenn der Test fehlschlägt.
    await db.close();

  }

});
