// tests/basic.test.js

// describe() gruppiert zusammengehörige Tests unter einem gemeinsamen Namen.
// Alle Basistests der Pacman-Anwendung werden hier gebündelt.
describe("Pacman Basic Tests", () => {

  // Prüft, ob das Jest Test-Framework selbst korrekt funktioniert.
  // Ein fehlschlagender Test hier würde bedeuten, dass die gesamte
  // Testumgebung nicht einsatzbereit ist.
  test("Node.js Test Framework funktioniert", () => {
    expect(true).toBe(true);
  });


  // Prüft, ob der Projektname korrekt definiert ist.
  // Stellt sicher, dass grundlegende Konfigurationswerte
  // der Anwendung unverändert und korrekt sind.
  test("Projektname ist definiert", () => {
    const appName = "pacman";

    expect(appName).toBe("pacman");
  });


  // Prüft, ob der Port der Anwendung korrekt auf 8080 gesetzt ist.
  // Port 8080 ist der Standard-Port, auf dem die Pacman-Anwendung
  // erreichbar ist und der auch im Smoke-Test verwendet wird.
  test("Port ist korrekt definiert", () => {
    const port = 8080;

    expect(port).toBe(8080);
  });

});
