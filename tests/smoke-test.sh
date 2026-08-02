#!/bin/bash

# ==========================================================
# Pacman Smoke-Test
# Automatisierter Integrationstest für Docker Compose Umgebung
#
# Prüft:
# - Start der Docker Compose Umgebung
# - Healthcheck-Status der Services
# - HTTP-Erreichbarkeit der Pacman-Anwendung
# - Verbindung zur MongoDB
# - Schreiben und Lesen eines Testdatensatzes
#
# Ziel:
# Sicherstellen, dass die komplette lokale Integrationsumgebung
# funktionsfähig ist.
# ==========================================================


# Bricht das Skript beim ersten fehlgeschlagenen Befehl ab,
# damit ein Fehler nicht unbemerkt bleibt.
set -e


echo "======================================"
echo "Starte Pacman Smoke-Test"
echo "======================================"


# ----------------------------------------------------------
# 1. Docker Compose Stack starten
# ----------------------------------------------------------

echo "Starte Docker Compose Umgebung..."

docker compose up -d


# ----------------------------------------------------------
# 2. Warten auf Healthchecks
# ----------------------------------------------------------

echo "Warte auf gestartete Services..."

# Pollt alle 5 Sekunden den Compose-Status, bis beide Container den
# Healthcheck-Status "healthy" melden. Bricht nach 60 Sekunden ab,
# falls ein Service nicht rechtzeitig gesund wird.
timeout 60 bash -c '
until docker compose ps | grep -q "pacman.*(healthy)" &&
      docker compose ps | grep -q "mongodb.*(healthy)"; do

    echo "Services noch nicht bereit..."
    sleep 5

done
'


echo "Services sind bereit."


docker compose ps


# ----------------------------------------------------------
# 3. HTTP Smoke-Test
# ----------------------------------------------------------

echo ""
echo "Prüfe HTTP-Erreichbarkeit..."

# "-f" lässt curl mit einem Fehlercode abbrechen, sobald der Server
# einen HTTP-Fehlerstatus (z.B. 4xx/5xx) zurückgibt.
curl -f http://localhost:8080


echo ""
echo "HTTP-Test erfolgreich."


# ----------------------------------------------------------
# 4. MongoDB Testdatensatz schreiben
# ----------------------------------------------------------

echo ""
echo "Schreibe Testdatensatz in MongoDB..."

# Das Image mongo:4.4.30-focal enthält nur das alte "mongo"-Shell,
# nicht das neuere "mongosh" (erst ab MongoDB 5/6 Images enthalten).
docker exec mongodb mongo pacman --eval '
db.smoke_test.insertOne({
    test: "Smoke-Test",
    status: "successful"
});
'


echo "Testdatensatz erfolgreich geschrieben."


# ----------------------------------------------------------
# 5. MongoDB Testdatensatz lesen
# ----------------------------------------------------------

echo ""
echo "Lese Testdatensatz aus MongoDB..."


# Liest den zuvor geschriebenen Testdatensatz wieder aus,
# um zu verifizieren, dass der Schreibvorgang tatsächlich
# persistiert wurde und nicht nur ohne Fehler durchlief.
docker exec mongodb mongo pacman --eval '
result=db.smoke_test.findOne({
    test:"Smoke-Test"
});

// quit(1) beendet das Shell-Skript mit Exitcode 1, wodurch
// "docker exec" fehlschlägt und "set -e" das gesamte Skript stoppt.
if(result == null)
{
    quit(1);
}
'


echo "MongoDB-Test erfolgreich."


# ----------------------------------------------------------
# Ergebnis
# ----------------------------------------------------------

echo ""
echo "======================================"
echo "Smoke-Test erfolgreich abgeschlossen"
echo "======================================"