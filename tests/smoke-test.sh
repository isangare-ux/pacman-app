#!/bin/bash

# Prüft die grundlegende Erreichbarkeit der Pacman-Anwendung.
if ! curl -fsS --max-time 5 http://localhost:8080 >/dev/null; then
    echo "Smoke Test fehlgeschlagen: Startseite nicht erreichbar"
    exit 1
fi

echo "Smoke Test erfolgreich"
exit 0