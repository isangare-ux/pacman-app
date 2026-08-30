#!/usr/bin/env bash
#
# local-stop.sh
# Beendet den lokalen Pacman-Docker-Compose-Stack kontrolliert.
# Persistente Volumes werden standardmäßig NICHT entfernt.
#
# Exit Codes:
#   0 - Stack erfolgreich beendet
#   1 - Voraussetzung oder Stop fehlgeschlagen
#   2 - ungültiger Aufruf

# Bewusst KEIN "set -e", aus denselben Gruenden wie in local-start.sh:
# jeder kritische Schritt wird explizit geprueft und liefert eine eigene,
# verstaendliche Fehlermeldung mit passendem Exit-Code.
set -uo pipefail

# Absoluter Pfad zum Skriptverzeichnis und daraus abgeleitet das
# Projekt-Root, damit das Skript unabhaengig vom Aufrufverzeichnis
# funktioniert (identisches Muster wie in local-start.sh).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
  echo "Verwendung: $(basename "$0") [-h|--help]"
  echo
  echo "Beendet den lokalen Pacman-Docker-Compose-Stack."
  echo "Persistente Volumes bleiben erhalten."
}

# --- Argument-Handling ------------------------------------------------------
# Nur "-h/--help" ist eine gueltige Option. Alles andere ist ein
# Bedienfehler (Exit-Code 2), analog zu local-start.sh.
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
elif [[ $# -gt 0 ]]; then
  echo "Fehler: unbekannter Parameter '${1}'" >&2
  usage >&2
  exit 2
fi

# --- Voraussetzungen pruefen -------------------------------------------------
# Dieselben Fail-Fast-Pruefungen wie beim Start: bevor irgendetwas beendet
# wird, muss sichergestellt sein, dass Docker/Compose ueberhaupt nutzbar
# sind und die compose.yaml existiert. Das verhindert kryptische
# Folgefehler weiter unten.

# 1) docker-CLI vorhanden?
if ! command -v docker >/dev/null 2>&1; then
  echo "Fehler: Docker ist nicht installiert oder nicht im PATH verfügbar." >&2
  exit 1
fi

# 2) Docker-Daemon erreichbar?
if ! docker info >/dev/null 2>&1; then
  echo "Fehler: Docker-Daemon ist nicht erreichbar. Läuft Docker Desktop?" >&2
  exit 1
fi

# 3) Compose-Plugin verfuegbar?
if ! docker compose version >/dev/null 2>&1; then
  echo "Fehler: Docker Compose ist nicht verfügbar." >&2
  exit 1
fi

# 4) compose.yaml im Projekt-Root vorhanden? "docker compose down" braucht
#    dieselbe Compose-Datei wie "up", um Projektname/Ressourcen korrekt
#    zuzuordnen (Container, Netzwerke - Volumes werden bewusst NICHT
#    automatisch mit entfernt, siehe unten).
if [[ ! -f "${PROJECT_DIR}/compose.yaml" ]]; then
  echo "Fehler: compose.yaml wurde in '${PROJECT_DIR}' nicht gefunden." >&2
  exit 1
fi

# Wie beim Start: relativ zum Projekt-Root arbeiten, damit compose.yaml
# unabhaengig vom Aufrufverzeichnis gefunden und korrekt interpretiert wird.
cd "${PROJECT_DIR}"

# --- Stack beenden -----------------------------------------------------------
# "docker compose down" (ohne "-v") stoppt und entfernt Container und
# Netzwerke des Projekts, laesst benannte/persistente Volumes aber
# unangetastet. Das ist bewusst so gewaehlt, damit lokale Entwicklungsdaten
# (z. B. MongoDB-Inhalte) einen "down/up"-Zyklus ueberleben und nicht
# versehentlich durch dieses Skript geloescht werden. Wer Volumes
# tatsaechlich entfernen will, muss das explizit und bewusst separat tun
# (z. B. "docker compose down -v"), nicht als Nebeneffekt dieses Skripts.
echo "Beende Pacman-Compose-Stack ..."
if ! docker compose down; then
  echo "Fehler: Docker-Compose-Stack konnte nicht beendet werden." >&2
  exit 1
fi

echo
echo "Pacman-Compose-Stack wurde erfolgreich beendet."
echo "Persistente Volumes wurden nicht entfernt."
exit 0