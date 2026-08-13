#!/usr/bin/env bash
#
# Pacman Load-Test (AP21)
#
# Erzeugt fuer eine festgelegte Dauer kontrollierte parallele HTTP-Last
# gegen eine Ziel-URL, zaehlt erfolgreiche/fehlgeschlagene Requests und
# beendet sich automatisch. Dient als Werkzeug fuer den spaeteren
# HPA-Skalierungstest (AP21 Frage 6) - loest hier noch keine Skalierung
# aus, das haengt allein von Aufrufparametern und Ziel-Umgebung ab.
#
# Nutzung:
#   ./scripts/load-test.sh [URL] [DAUER_SEKUNDEN] [WORKER]
#
# Beispiel (spaeterer HPA-Test gegen Prod):
#   ./scripts/load-test.sh http://pacman.local 120 10
#
set -uo pipefail
# Bewusst KEIN "set -e": ein einzelner fehlgeschlagener curl-Request
# (z. B. durch kurzzeitige Ueberlast) soll den Lasttest nicht abbrechen,
# sondern nur als "fehlgeschlagen" gezaehlt werden.

# --- Konfiguration / Defaults --------------------------------------------
# Bewusst ungefaehrliche Defaults: Dev-Ziel statt Prod, kurze Dauer, wenige
# Worker. Fuer den eigentlichen HPA-Test wird spaeter explizit die
# Prod-URL sowie eine hoehere Dauer/Workerzahl uebergeben.
URL="${1:-http://pacman-dev.local}"
DURATION="${2:-10}"
WORKERS="${3:-2}"
HTTP_TIMEOUT="${LOAD_TEST_HTTP_TIMEOUT:-5}"

# --- Parameter validieren -------------------------------------------------
if ! [[ "$DURATION" =~ ^[0-9]+$ ]] || [ "$DURATION" -lt 1 ]; then
  echo "Fehler: DAUER muss eine positive Ganzzahl (Sekunden) sein, erhalten: '$DURATION'" >&2
  exit 2
fi

if ! [[ "$WORKERS" =~ ^[0-9]+$ ]] || [ "$WORKERS" -lt 1 ]; then
  echo "Fehler: WORKER muss eine positive Ganzzahl sein, erhalten: '$WORKERS'" >&2
  exit 2
fi

if [[ ! "$URL" =~ ^https?:// ]]; then
  echo "Fehler: URL muss mit http:// oder https:// beginnen, erhalten: '$URL'" >&2
  exit 2
fi

# --- curl-Verfuegbarkeit pruefen ------------------------------------------
if ! command -v curl >/dev/null 2>&1; then
  echo "Fehler: curl wird benoetigt, ist aber nicht installiert." >&2
  exit 3
fi

# --- Ziel-URL kurz auf Erreichbarkeit pruefen -----------------------------
echo "Pruefe Erreichbarkeit von $URL ..."
if curl --silent --show-error --max-time "$HTTP_TIMEOUT" --output /dev/null "$URL"; then
  echo "Ziel ist erreichbar."
else
  echo "Warnung: $URL war beim Erreichbarkeitstest nicht erreichbar." >&2
  echo "  Pruefe z. B. 'kubectl get ingress -A' und den Docker-Desktop-Ingress." >&2
  echo "  Der Test startet trotzdem - nicht erreichbare Requests zaehlen als fehlgeschlagen." >&2
fi

# --- Arbeitsverzeichnis fuer Zaehler ---------------------------------------
# Jeder Worker schreibt seine Ergebnisse in eigene Dateien (ein Byte pro
# Request), damit parallele Prozesse sich nicht gegenseitig ueberschreiben.
# Ausgezaehlt wird am Ende einfach ueber die Dateigroesse.
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/pacman-load-test.XXXXXX")"
STOP_FILE="$WORK_DIR/stop"
WORKER_PIDS=()
INTERRUPTED=0
START_TS=$(date +%s)
START_HUMAN=$(date '+%Y-%m-%d %H:%M:%S')

run_worker() {
  local ok_file="$1"
  local fail_file="$2"
  : > "$ok_file"
  : > "$fail_file"

  while [ ! -e "$STOP_FILE" ]; do
    if curl --silent --show-error --max-time "$HTTP_TIMEOUT" --output /dev/null "$URL"; then
      printf '.' >> "$ok_file"
    else
      printf '.' >> "$fail_file"
    fi
  done
}

# Zaehlt Anfragen, stoppt alle Worker und gibt die Zusammenfassung aus.
# Laeuft ueber den EXIT-Trap sowohl beim normalen Testende als auch nach
# STRG+C, damit in beiden Faellen sauber aufgeraeumt und ausgewertet wird.
cleanup() {
  touch "$STOP_FILE" 2>/dev/null || true

  local pid
  for pid in "${WORKER_PIDS[@]:-}"; do
    [ -n "$pid" ] || continue
    wait "$pid" 2>/dev/null || true
  done

  local end_ts end_human actual_duration ok_count fail_count total_count f n
  end_ts=$(date +%s)
  end_human=$(date '+%Y-%m-%d %H:%M:%S')
  actual_duration=$((end_ts - START_TS))

  ok_count=0
  fail_count=0
  for f in "$WORK_DIR"/ok.*; do
    [ -f "$f" ] || continue
    n=$(wc -c < "$f")
    ok_count=$((ok_count + n))
  done
  for f in "$WORK_DIR"/fail.*; do
    [ -f "$f" ] || continue
    n=$(wc -c < "$f")
    fail_count=$((fail_count + n))
  done
  total_count=$((ok_count + fail_count))

  if [ "$INTERRUPTED" -eq 1 ]; then
    echo
    echo "Abbruch durch Benutzer (STRG+C) - werte bisherige Ergebnisse aus ..."
  fi

  echo "----------------------------------------"
  echo "Test beendet"
  echo "Ende:                    $end_human"
  echo "Dauer tatsaechlich:      ${actual_duration} Sekunden"
  echo "Requests erfolgreich:    $ok_count"
  echo "Requests fehlgeschlagen: $fail_count"
  echo "Gesamt:                  $total_count"
  echo "========================================"

  rm -rf "$WORK_DIR"

  if [ "$INTERRUPTED" -eq 1 ]; then
    exit 130
  fi
  if [ "$total_count" -eq 0 ] || [ "$ok_count" -eq 0 ]; then
    exit 1
  fi
  exit 0
}

on_interrupt() {
  INTERRUPTED=1
  # Direktes exit statt Rueckkehr in den unterbrochenen Befehl: loest den
  # EXIT-Trap (cleanup) sofort und einmalig aus, statt z. B. "sleep"
  # nach dem Trap-Handler weiterlaufen zu lassen.
  exit 130
}
trap on_interrupt INT TERM
trap cleanup EXIT

echo "========================================"
echo "Pacman Load-Test"
echo "========================================"
echo "Ziel:            $URL"
echo "Dauer geplant:   ${DURATION} Sekunden"
echo "Worker:          $WORKERS"
echo "Start:           $START_HUMAN"
echo "----------------------------------------"

for ((i = 1; i <= WORKERS; i++)); do
  run_worker "$WORK_DIR/ok.$i" "$WORK_DIR/fail.$i" &
  WORKER_PIDS+=("$!")
done

sleep "$DURATION"

# Ab hier faellt das Skript regulaer durch bis zum Ende; der EXIT-Trap
# (cleanup) uebernimmt Stoppen der Worker, Auswertung und Exit-Code.
