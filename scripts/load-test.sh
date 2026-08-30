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
# Alle drei Eingaben werden per Regex/Bereichspruefung VOR dem eigentlichen
# Test verifiziert (Fail-Fast, Exit-Code 2 = ungueltiger Aufruf), damit z. B.
# ein Tippfehler in der Dauer nicht erst nach dem Start von Workern oder
# mitten im Test zu unklarem Verhalten fuehrt.

# DAUER muss eine positive Ganzzahl sein, da sie direkt an "sleep" (Zeile
# ~172) uebergeben wird - negative/nicht-numerische Werte wuerden dort zu
# einem Laufzeitfehler statt einer klaren Fehlermeldung fuehren.
if ! [[ "$DURATION" =~ ^[0-9]+$ ]] || [ "$DURATION" -lt 1 ]; then
  echo "Fehler: DAUER muss eine positive Ganzzahl (Sekunden) sein, erhalten: '$DURATION'" >&2
  exit 2
fi

# WORKER bestimmt die Anzahl paralleler Hintergrundprozesse (siehe
# for-Schleife weiter unten) und muss daher ebenfalls eine positive
# Ganzzahl sein; 0 oder negative Werte wuerden schlicht keine Last
# erzeugen bzw. die for-Schleife nicht sinnvoll ausfuehren.
if ! [[ "$WORKERS" =~ ^[0-9]+$ ]] || [ "$WORKERS" -lt 1 ]; then
  echo "Fehler: WORKER muss eine positive Ganzzahl sein, erhalten: '$WORKERS'" >&2
  exit 2
fi

# Grobe Plausibilitaetspruefung der URL (nur Schema-Praefix). Eine
# vollstaendige URL-Validierung ist hier nicht noetig - falsch geformte
# URLs faellt spaetestens curl selbst ab und zaehlt sie als
# fehlgeschlagenen Request; dieser Check faengt aber den haeufigsten
# Fehlerfall (fehlendes http(s)://) sofort mit einer klaren Meldung ab.
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
if ! WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/pacman-load-test.XXXXXX")"; then
  echo "Fehler: Temporäres Arbeitsverzeichnis konnte nicht erstellt werden." >&2
  exit 3
fi
STOP_FILE="$WORK_DIR/stop"
WORKER_PIDS=()
INTERRUPTED=0
START_TS=$(date +%s)
START_HUMAN=$(date '+%Y-%m-%d %H:%M:%S')

# Ein einzelner Worker: laeuft als eigener Hintergrundprozess (siehe Aufruf
# unten mit "&") und feuert in einer Endlosschleife so schnell wie moeglich
# sequenzielle curl-Requests gegen die Ziel-URL, bis die STOP_FILE erscheint.
# Mehrere Worker parallel erzeugen so die gewuenschte gleichzeitige Last,
# ohne dass ein externes Lasttest-Tool installiert werden muss - nur
# curl wird vorausgesetzt (siehe Verfuegbarkeitspruefung oben).
run_worker() {
  local ok_file="$1"
  local fail_file="$2"
  # Dateien leeren/anlegen, falls sie (theoretisch) bereits existieren -
  # stellt sicher, dass jede Zaehlung bei 0 Bytes beginnt.
  : > "$ok_file"
  : > "$fail_file"

  # Die Schleifenbedingung prueft bei jedem Durchlauf erneut, ob die
  # STOP_FILE existiert. Das Setzen dieser Datei (siehe cleanup()) ist das
  # Signal an alle Worker, sich zu beenden - so brauchen wir keine Signale
  # zwischen Prozessen zu verschicken, ein simples "touch" reicht.
  while [ ! -e "$STOP_FILE" ]; do
    # --silent/--show-error: keine Fortschrittsanzeige, aber echte Fehler
    # (z. B. DNS-Fehler) landen auf stderr. --output /dev/null verwirft den
    # Response-Body, da nur Erfolg/Misserfolg zaehlt, nicht der Inhalt.
    # --max-time verhindert, dass ein haengender Request einen Worker
    # dauerhaft blockiert und so die Lastgenerierung stoppt.
    if curl --silent --show-error --max-time "$HTTP_TIMEOUT" --output /dev/null "$URL"; then
      # Ein Byte pro erfolgreichem Request anhaengen; die Gesamtzahl wird
      # spaeter einfach ueber die Dateigroesse (wc -c) ermittelt - schneller
      # und robuster als ein Zaehler in einer gemeinsam genutzten Variable,
      # die zwischen parallelen Prozessen ohnehin nicht geteilt werden kann.
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
  # Signalisiert allen Workern per Existenz dieser Datei, ihre Schleife zu
  # verlassen (siehe run_worker). "|| true", da ein Fehlschlag hier (z. B.
  # WORK_DIR bereits geloescht) das Aufraeumen nicht abbrechen soll.
  touch "$STOP_FILE" 2>/dev/null || true

  # Auf das tatsaechliche Ende jedes Worker-Prozesses warten, bevor
  # ausgewertet wird - sonst koennten Worker noch mitten in einem
  # letzten printf stecken und die Zaehlung waere inkonsistent/verpasst.
  local pid
  for pid in "${WORKER_PIDS[@]:-}"; do
    [ -n "$pid" ] || continue
    wait "$pid" 2>/dev/null || true
  done

  local end_ts end_human actual_duration ok_count fail_count total_count f n
  end_ts=$(date +%s)
  end_human=$(date '+%Y-%m-%d %H:%M:%S')
  actual_duration=$((end_ts - START_TS))

  # Zaehlung ueber alle Worker-Dateien hinweg: jede Datei enthaelt so viele
  # Bytes (Punkte), wie der jeweilige Worker Requests dieses Typs (ok/fail)
  # gemacht hat. Summiert ueber alle Worker ergibt sich die Gesamtzahl.
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

  # Temporaeres Arbeitsverzeichnis samt aller Zaehl-Dateien entfernen -
  # sie werden nach der Auswertung nicht mehr gebraucht und sollen nicht
  # im System-Temp-Verzeichnis liegen bleiben.
  rm -rf "$WORK_DIR"

  # Exit-Code spiegelt das Testergebnis wider, damit z. B. eine CI-Pipeline
  # oder ein umschliessendes Skript automatisiert auswerten kann:
  #   130 - Test wurde per STRG+C abgebrochen (Standard-Exit-Code fuer
  #         SIGINT, 128+2), unabhaengig davon, wie viele Requests bereits
  #         gezaehlt wurden.
  #   1   - Test ist regulaer durchgelaufen, aber es gab entweder gar
  #         keine Requests oder ausschliesslich fehlgeschlagene - deutet
  #         auf ein nicht erreichbares Ziel hin.
  #   0   - Test ist regulaer durchgelaufen und mindestens ein Request war
  #         erfolgreich.
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

# Startet WORKERS Hintergrundprozesse, die alle sofort und parallel gegen
# die Ziel-URL feuern ("&" schickt run_worker in den Hintergrund). Jeder
# Worker bekommt seine eigenen ok/fail-Dateien (siehe run_worker), die PID
# wird gemerkt, damit cleanup() spaeter gezielt auf jeden einzelnen
# Prozess warten kann.
for ((i = 1; i <= WORKERS; i++)); do
  run_worker "$WORK_DIR/ok.$i" "$WORK_DIR/fail.$i" &
  WORKER_PIDS+=("$!")
done

# Das Hauptskript selbst tut waehrend der Testdauer nichts weiter, als zu
# warten - die eigentliche Last erzeugen ausschliesslich die im Hintergrund
# laufenden Worker. Nach Ablauf von DURATION Sekunden endet "sleep" und das
# Skript faellt regulaer durch (siehe Kommentar unten).
sleep "$DURATION"

# Ab hier faellt das Skript regulaer durch bis zum Ende; der EXIT-Trap
# (cleanup) uebernimmt Stoppen der Worker, Auswertung und Exit-Code.
