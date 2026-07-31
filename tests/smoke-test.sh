#!/bin/bash
# Smoke-Test: Prüft, ob die Anwendung unter http://localhost:8080 erreichbar ist.
# Wird nach dem Start des Containers ausgeführt, um die grundlegende
# Funktionsfähigkeit sicherzustellen (kein 4xx/5xx-Fehler, kein Connection-Refused).

curl -f http://localhost:8080

if [ $? -eq 0 ]; then
    echo "Smoke Test erfolgreich"
else
    echo "Smoke Test fehlgeschlagen"
    exit 1
fi
