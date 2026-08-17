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

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
  echo "Verwendung: $(basename "$0") [-h|--help]"
  echo
  echo "Beendet den lokalen Pacman-Docker-Compose-Stack."
  echo "Persistente Volumes bleiben erhalten."
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
elif [[ $# -gt 0 ]]; then
  echo "Fehler: unbekannter Parameter '${1}'" >&2
  usage >&2
  exit 2
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Fehler: Docker ist nicht installiert oder nicht im PATH verfügbar." >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "Fehler: Docker-Daemon ist nicht erreichbar. Läuft Docker Desktop?" >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "Fehler: Docker Compose ist nicht verfügbar." >&2
  exit 1
fi

if [[ ! -f "${PROJECT_DIR}/compose.yaml" ]]; then
  echo "Fehler: compose.yaml wurde in '${PROJECT_DIR}' nicht gefunden." >&2
  exit 1
fi

cd "${PROJECT_DIR}"

echo "Beende Pacman-Compose-Stack ..."
if ! docker compose down; then
  echo "Fehler: Docker-Compose-Stack konnte nicht beendet werden." >&2
  exit 1
fi

echo
echo "Pacman-Compose-Stack wurde erfolgreich beendet."
echo "Persistente Volumes wurden nicht entfernt."
exit 0