#!/usr/bin/env bash
#
# local-start.sh
# Startet den lokalen Pacman-Docker-Compose-Stack kontrolliert.
#
# Exit Codes:
#   0 - Stack erfolgreich gestartet
#   1 - Voraussetzung oder Start fehlgeschlagen
#   2 - ungültiger Aufruf

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
  echo "Verwendung: $(basename "$0") [-h|--help]"
  echo
  echo "Startet den lokalen Pacman-Docker-Compose-Stack und zeigt"
  echo "anschließend den Status der Services an."
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

echo "Validiere Docker-Compose-Konfiguration ..."
if ! docker compose config --quiet; then
  echo "Fehler: compose.yaml ist ungültig." >&2
  exit 1
fi

echo "Starte Pacman-Compose-Stack ..."
if ! docker compose up -d; then
  echo "Fehler: Docker-Compose-Stack konnte nicht gestartet werden." >&2
  exit 1
fi

echo
echo "Aktueller Service-Status:"
if ! docker compose ps; then
  echo "Fehler: Service-Status konnte nicht abgefragt werden." >&2
  exit 1
fi

echo
echo "Pacman-Compose-Stack wurde erfolgreich gestartet."
exit 0