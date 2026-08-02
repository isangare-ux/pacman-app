#!/bin/bash

# ==========================================================
# Pacman Load-Test
# Führt einen HTTP-Lasttest gegen die Pacman-Anwendung durch.
# Ziel ist die Überprüfung der Stabilität und Erreichbarkeit
# der Anwendung unter paralleler Anfragebelastung.
# ==========================================================


# Beendet das Skript sofort, wenn ein Fehler auftritt.
# Dadurch werden fehlerhafte Testläufe erkannt und nicht
# mit falschem Erfolg beendet.
set -e


# Zieladresse der zu testenden Anwendung.
# Die Pacman-Anwendung stellt den HTTP-Service über Port 8080 bereit.
URL="http://localhost:8080"


# Anzahl der gesamten HTTP-Anfragen während des Lasttests.
REQUESTS=1000


# Anzahl der gleichzeitig ausgeführten parallelen Anfragen.
CONCURRENCY=20


# Verzeichnis und Datei für die Speicherung der Testergebnisse.
# Die Logdatei dient als Nachweis für die Testausführung.
LOG_DIR="logs"
LOG_FILE="$LOG_DIR/load_test.log"



# Ausgabe der Testinformationen im Terminal.
# Dadurch sind Testziel, Anzahl der Requests und Parallelität
# im CI- oder lokalen Testprotokoll nachvollziehbar.
echo "======================================"
echo "Pacman Load-Test"
echo "======================================"

echo "Ziel: $URL"
echo "Requests: $REQUESTS"
echo "Parallelität: $CONCURRENCY"


# Erstellt das Log-Verzeichnis, falls es noch nicht existiert.
mkdir -p "$LOG_DIR"



# Prüft, ob Apache Benchmark (ab) auf dem System installiert ist.
# Apache Benchmark wird verwendet, um HTTP-Anfragen automatisiert
# und mit definierter Parallelität auszuführen.
if ! command -v ab &> /dev/null
then
    echo "Fehler: Apache Benchmark (ab) ist nicht installiert."
    echo "Installation: sudo apt install apache2-utils"
    exit 1
fi



echo ""
echo "Starte Load-Test..."
echo ""



# Führt den HTTP-Lasttest aus.
#
# -n definiert die Gesamtanzahl der Requests.
# -c definiert die Anzahl paralleler Verbindungen.
#
# Die Ausgabe wird gleichzeitig:
# 1. im Terminal angezeigt
# 2. in der Logdatei gespeichert
#
# Dadurch bleibt der Test nachvollziehbar dokumentiert.
ab \
  -n "$REQUESTS" \
  -c "$CONCURRENCY" \
  "$URL/" | tee "$LOG_FILE"



echo ""
echo "======================================"
echo "Load-Test abgeschlossen"
echo "Log gespeichert unter:"
echo "$LOG_FILE"
echo "======================================"