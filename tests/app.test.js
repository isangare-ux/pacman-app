// axios ist eine HTTP-Bibliothek, die HTTP-Anfragen aus Node.js heraus
// ermöglicht. Sie wird hier verwendet, um die laufende Anwendung
// per GET-Request zu testen.
const axios = require("axios");

// Prüft, ob die Pacman-Anwendung unter Port 8080 erreichbar ist
// und mit dem HTTP-Statuscode 200 (OK) antwortet.
test("Pacman Anwendung ist erreichbar", async () => {

  // Sendet einen HTTP GET-Request an die laufende Anwendung.
  // "await" wartet auf die Antwort, bevor der Test weiterläuft.
  const response = await axios.get(
    "http://localhost:8080"
  );

  // Stellt sicher, dass der Server mit HTTP 200 (OK) geantwortet hat.
  // Schlägt der Server fehl oder ist er nicht erreichbar, schlägt
  // dieser Test fehl und die CI-Pipeline wird abgebrochen.
  expect(response.status).toBe(200);

});
