#!/usr/bin/env bash
#
# local-start.sh
# Startet den lokalen Pacman-Docker-Compose-Stack kontrolliert.
#
# Exit Codes:
#   0 - Stack erfolgreich gestartet
#   1 - Voraussetzung oder Start fehlgeschlagen
#   2 - ungültiger Aufruf

# Bewusst KEIN "set -e": jeder kritische Schritt wird explizit per "if ! ..."
# geprueft und gibt bei Fehlschlag eine eigene, verstaendliche Fehlermeldung
# samt passendem Exit-Code aus, statt das Skript stillschweigend mit einer
# generischen Bash-Fehlermeldung abzubrechen. "-u" faengt Tippfehler bei
# Variablennamen ab, "pipefail" sorgt dafuer, dass Fehler in Pipes nicht
# verschluckt werden.
set -uo pipefail

# Absoluter Pfad zum Skriptverzeichnis und daraus abgeleitet das
# Projekt-Root (eine Ebene hoeher). So funktioniert das Skript unabhaengig
# davon, aus welchem Verzeichnis heraus es aufgerufen wird (z. B.
# "./scripts/local-start.sh" vs. Aufruf per absolutem Pfad von woanders).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
  echo "Verwendung: $(basename "$0") [-h|--help]"
  echo
  echo "Startet den lokalen Pacman-Docker-Compose-Stack und zeigt"
  echo "anschließend den Status der Services an."
}

# --- Argument-Handling ------------------------------------------------------
# Das Skript kennt bewusst nur "-h/--help" als Option. Jeder andere
# Parameter ist ein Bedienfehler des Aufrufers und wird mit Exit-Code 2
# quittiert (Konvention dieses Skripts: 2 = ungueltiger Aufruf, siehe
# Kopfkommentar), damit CI/Automatisierung klar zwischen "falsch benutzt"
# und "fehlgeschlagen" (Exit-Code 1) unterscheiden kann.
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
elif [[ $# -gt 0 ]]; then
  echo "Fehler: unbekannter Parameter '${1}'" >&2
  usage >&2
  exit 2
fi

# --- Voraussetzungen pruefen -------------------------------------------------
# Alle Vorbedingungen werden VOR jeder Aenderung am System geprueft
# (Fail-Fast-Prinzip), damit z. B. kein halb gestarteter Stack entsteht,
# nur weil erst mitten im Ablauf auffaellt, dass Docker fehlt.

# 1) Ist die docker-CLI ueberhaupt installiert/im PATH?
if ! command -v docker >/dev/null 2>&1; then
  echo "Fehler: Docker ist nicht installiert oder nicht im PATH verfügbar." >&2
  exit 1
fi

# 2) Laeuft der Docker-Daemon tatsaechlich? "docker info" schlaegt fehl,
#    wenn z. B. Docker Desktop nicht gestartet ist, auch wenn die CLI
#    vorhanden ist.
if ! docker info >/dev/null 2>&1; then
  echo "Fehler: Docker-Daemon ist nicht erreichbar. Läuft Docker Desktop?" >&2
  exit 1
fi

# 3) Ist das Compose-Plugin (v2, "docker compose ...") verfuegbar? Ohne das
#    Plugin schlagen alle folgenden "docker compose"-Aufrufe fehl.
if ! docker compose version >/dev/null 2>&1; then
  echo "Fehler: Docker Compose ist nicht verfügbar." >&2
  exit 1
fi

# 4) Existiert die compose.yaml im Projekt-Root? Ohne sie kann weder
#    validiert noch gestartet werden.
if [[ ! -f "${PROJECT_DIR}/compose.yaml" ]]; then
  echo "Fehler: compose.yaml wurde in '${PROJECT_DIR}' nicht gefunden." >&2
  exit 1
fi

# Ab hier arbeiten alle "docker compose"-Aufrufe relativ zum Projekt-Root,
# damit compose.yaml und referenzierte relative Pfade (Volumes, .env etc.)
# unabhaengig vom urspruenglichen Aufrufverzeichnis korrekt aufgeloest werden.
cd "${PROJECT_DIR}"

# --- Konfiguration validieren ------------------------------------------------
# "docker compose config" parst/rendert die compose.yaml (inkl. Variablen-
# Interpolation) ohne etwas zu starten. So wird ein Syntax-/Referenzfehler
# in der Datei erkannt, BEVOR Container erstellt werden.
echo "Validiere Docker-Compose-Konfiguration ..."
if ! docker compose config --quiet; then
  echo "Fehler: compose.yaml ist ungültig." >&2
  exit 1
fi

# --- Stack starten -----------------------------------------------------------
# "-d" (detached) startet die Container im Hintergrund, damit das Skript
# terminiert statt im Vordergrund auf Logs zu warten.
echo "Starte Pacman-Compose-Stack ..."
if ! docker compose up -d; then
  echo "Fehler: Docker-Compose-Stack konnte nicht gestartet werden." >&2
  exit 1
fi

# --- Status anzeigen ---------------------------------------------------------
# Dient als sofortiges visuelles Feedback, ob und mit welchem Status
# (running/healthy/restarting ...) die einzelnen Services tatsaechlich
# hochgekommen sind, statt sich allein auf den Exit-Code von "up" zu
# verlassen.
echo
echo "Aktueller Service-Status:"
if ! docker compose ps; then
  echo "Fehler: Service-Status konnte nicht abgefragt werden." >&2
  exit 1
fi

echo
echo "Pacman-Compose-Stack wurde erfolgreich gestartet."
exit 0