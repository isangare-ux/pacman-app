# Pacman-App

## Projektübersicht

Dieses Projekt modernisiert eine bestehende Pacman-Node.js-Anwendung durch den Einsatz moderner DevOps-Praktiken.

Ziel ist eine reproduzierbare Entwicklungs-, Build-, Test- und Deployment-Umgebung mit Docker, GitHub Actions, GitHub Container Registry, Kubernetes und GitOps.

Das Gesamtprojekt ist auf zwei Repositories aufgeteilt:

- `pacman-app`

  - Anwendungscode
  - Node.js-Abhängigkeiten
  - Dockerfile
  - Docker Compose
  - lokale Hilfs- und Testskripte
  - Smoke-Test
  - GitHub-Actions-Workflows
  - CI- und Release-Konfiguration
- `pacman-gitops`

  - Kubernetes-Manifeste
  - Kustomize Base und Overlays
  - Entwicklungs- und Produktionskonfiguration
  - Argo-CD-Konfiguration
  - GitOps-Sollzustand
  - Monitoring
  - Backup/Restore
  - weitere Betriebsressourcen

Durch diese Trennung werden Anwendungscode und Deployment-Sollzustand unabhängig voneinander versioniert und nachvollziehbar verwaltet.

---

# Projektziele

Die wichtigsten Ziele des Projekts sind:

- Modernisierung einer bestehenden Node.js-Anwendung
- reproduzierbare Installation der Abhängigkeiten
- Containerisierung der Anwendung mit Docker
- lokale Bereitstellung von Pacman und MongoDB mit Docker Compose
- automatisierte Build- und Testprozesse mit GitHub Actions
- Bereitstellung von Container-Images über GHCR
- eindeutige Zuordnung zwischen Quellcode und Container-Image
- Kubernetes-basierte Bereitstellung
- Trennung von Entwicklungs- und Produktionsumgebung
- GitOps-basierte Verwaltung des Kubernetes-Sollzustands
- Synchronisation des Sollzustands mit Argo CD
- Integration von Security- und Qualitätsprüfungen
- Vorbereitung für Monitoring, Skalierung, Backup und Restore

---

# Architekturübersicht

Der grundsätzliche technische Ablauf des Gesamtprojekts ist:

```text
GitHub
  |
  v
GitHub Actions
  |
  v
GitHub Container Registry
  |
  v
GitOps Repository
  |
  v
Kustomize
  |
  v
Argo CD
  |
  v
Kubernetes
  |
  v
Monitoring
```

Das Repository `pacman-app` bildet dabei hauptsächlich die Anwendung, den Container-Build sowie die CI-/Release-Seite ab.

Das Repository `pacman-gitops` beschreibt den gewünschten Kubernetes-Sollzustand.

---

# Anwendungsarchitektur

Die Pacman-Anwendung basiert auf Node.js und Express.

Der interne Startablauf ist:

```text
npm start
  |
  v
node .
  |
  v
package.json
  |
  v
main: bin/server.js
  |
  v
bin/server.js
  |
  v
app.js
  |
  v
Express-Anwendung
```

`bin/server.js` startet den HTTP-Server.

`app.js` konfiguriert unter anderem:

- Express
- statische Inhalte
- Routen
- Fehlerbehandlung
- Datenbankverbindung

Die Anwendung verwendet standardmäßig Port:

```text
8080
```

---

# Projektstruktur

```text
pacman-app/
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── release.yml
│
├── bin/
│   └── server.js
│
├── docs/
│   └── docker-analyse.md
│
├── lib/
│   ├── config.js
│   └── database.js
│
├── public/
│   ├── data/
│   ├── fonts/
│   ├── img/
│   ├── js/
│   ├── mp3/
│   ├── wav/
│   ├── index.html
│   ├── pacman-canvas.css
│   ├── pacman-canvas.js
│   └── style.css
│
├── routes/
│   ├── highscores.js
│   ├── location.js
│   └── user.js
│
├── scripts/
│   ├── load-test.sh
│   ├── local-start.sh
│   └── local-stop.sh
│
├── tests/
│   └── smoke-test.sh
│
├── views/
│   ├── error.pug
│   ├── index.pug
│   └── layout.pug
│
├── .dockerignore
├── .env.example
├── .gitignore
├── app.js
├── compose.yaml
├── Dockerfile
├── LICENSE
├── package.json
├── package-lock.json
└── README.md
```

---

# Bedeutung der wichtigsten Verzeichnisse

## `bin/`

Enthält den Startpunkt des HTTP-Servers.

Die Datei:

```text
bin/server.js
```

lädt die Express-Anwendung aus `app.js` und startet den Server auf Port 8080 beziehungsweise auf dem über die Umgebungsvariable `PORT` definierten Port.

---

## `lib/`

Enthält wiederverwendbare technische Komponenten.

### `lib/config.js`

Erstellt die MongoDB-Konfiguration auf Grundlage von Umgebungsvariablen.

Dazu gehören unter anderem:

- MongoDB-Host
- Datenbankname
- Port
- Authentifizierungsdaten
- optionale SSL-Konfiguration
- optionale Replica-Set-Konfiguration

### `lib/database.js`

Kapselt den Aufbau und die Wiederverwendung der MongoDB-Verbindung.

Die Datenbankverbindung wird für die Express-Anwendung bereitgestellt und von den Routen verwendet.

Beim Logging werden keine vollständigen Verbindungs-URLs oder Zugangsdaten ausgegeben.

---

# Backend-Routen

Die Anwendung stellt mehrere Express-Routen bereit.

## Highscores

```text
GET  /highscores/list
POST /highscores
```

`GET /highscores/list` liest gespeicherte Highscores aus MongoDB und liefert die besten Ergebnisse als JSON zurück.

`POST /highscores` speichert einen neuen Highscore.

Die verwendete MongoDB-Collection ist:

```text
highscore
```

---

## Benutzerstatistiken

```text
GET  /user/id
GET  /user/stats
POST /user/stats
```

`GET /user/id` erzeugt einen neuen Datensatz und liefert die von MongoDB erzeugte ObjectId zurück.

`POST /user/stats` aktualisiert laufende Spielstatistiken wie:

- Score
- Level
- Leben
- Spielzeit
- Cloud
- Zone
- Host

`GET /user/stats` liefert gespeicherte Spielstatistiken als JSON zurück.

Die verwendete MongoDB-Collection ist:

```text
userstats
```

---

## Standort- und Umgebungsinformationen

```text
GET /location/metadata
```

Der Endpunkt versucht Informationen über die Laufzeitumgebung zu ermitteln.

Dazu gehören:

- Cloud
- Zone
- Host

Die Anwendung versucht unterschiedliche Umgebungen beziehungsweise Metadata-Dienste zu erkennen.

Dieser Endpunkt kann abhängig von der lokalen Umgebung länger benötigen, da mehrere Metadata-Quellen nacheinander geprüft werden.

---

# Frontend

Das Frontend befindet sich hauptsächlich unter:

```text
public/
```

Wichtige Dateien sind:

```text
public/index.html
public/pacman-canvas.js
```

`index.html` enthält die grundlegende Benutzeroberfläche.

`pacman-canvas.js` enthält:

- Spiellogik
- Highscore-Verarbeitung
- Live-Statistiken
- AJAX-Aufrufe zum Backend

Beispiele für verwendete Backend-Aufrufe:

```text
GET  highscores/list
POST highscores
GET  user/stats
POST user/stats
GET  location/metadata
```

Der grundsätzliche Datenfluss lautet:

```text
Browser
  |
  v
public/pacman-canvas.js
  |
  | AJAX
  v
Express-Routen
  |
  v
lib/database.js
  |
  v
MongoDB
  |
  v
JSON-Antwort
  |
  v
Browser
```

---

# Node.js und Abhängigkeiten

Die zentralen Node.js-Dateien sind:

```text
package.json
package-lock.json
```

Die Anwendung verwendet unter anderem:

- Express
- MongoDB-Treiber
- Pug
- Body Parser

Für Entwicklungszwecke wird zusätzlich Nodemon verwendet.

---

# Reproduzierbare Installation

Die Abhängigkeiten werden mit:

```bash
npm ci
```

installiert.

`npm ci` verwendet den in `package-lock.json` gespeicherten Dependency-Stand und eignet sich besonders für:

- CI-Pipelines
- reproduzierbare Builds
- definierte Projektstände

Für das Runtime-Image werden nur produktive Abhängigkeiten installiert:

```bash
npm ci --omit=dev
```

---

# Anwendung lokal starten

## Variante 1: Direkt mit Node.js

Zuerst Abhängigkeiten installieren:

```bash
npm ci
```

Danach:

```bash
npm start
```

Intern wird dadurch:

```bash
node .
```

ausgeführt.

Node.js verwendet den in `package.json` definierten Einstiegspunkt:

```text
bin/server.js
```

Die Anwendung ist anschließend standardmäßig erreichbar unter:

```text
http://localhost:8080
```

Hinweis:

Für Funktionen, die MongoDB benötigen, muss zusätzlich eine erreichbare MongoDB-Instanz vorhanden sein.

---

# Docker

## Dockerfile

Das Dockerfile beschreibt, wie das Pacman-Container-Image aufgebaut wird.

Die wichtigsten Schritte sind:

```text
Node.js-Basisimage
  |
  v
Arbeitsverzeichnis
  |
  v
package.json + package-lock.json
  |
  v
npm ci --omit=dev
  |
  v
Anwendungscode
  |
  v
non-root User
  |
  v
Port 8080
  |
  v
CMD ["node", "."]
```

---

## Basis-Image

Verwendet wird eine fest versionierte Node.js-Basis:

```dockerfile
FROM node:16.19.0-bullseye-slim
```

Die feste Version verhindert, dass ein Build unkontrolliert auf eine andere Node.js-Version wechselt.

Das `slim`-Image reduziert zusätzliche Betriebssystemkomponenten.

---

# Docker-Build

Ein lokales Image kann mit folgendem Befehl erzeugt werden:

```bash
docker build -t pacman-app .
```

Beispiel für einen Test-Build:

```bash
docker build -t pacman-local:test .
```

---

# Containerstart

Der Container verwendet als Startbefehl:

```dockerfile
CMD ["node", "."]
```

Dieser Befehl wird nicht während des Image-Builds ausgeführt.

Er wird erst ausgeführt, wenn ein Container aus dem Image gestartet wird.

Der Ablauf lautet:

```text
Docker-Image
  |
  v
Container startet
  |
  v
CMD ["node", "."]
  |
  v
bin/server.js
  |
  v
app.js
  |
  v
Pacman
```

---

# Non-root-Ausführung

Die Anwendung wird im Container mit:

```dockerfile
USER node
```

als nicht privilegierter Benutzer gestartet.

Dadurch erhält der Anwendungsprozess weniger Rechte als ein Root-Prozess.

Dies reduziert die Auswirkungen einer möglichen Kompromittierung.

---

# `.dockerignore`

Die `.dockerignore` verhindert, dass unnötige oder potenziell sensible Dateien in den Docker-Build-Kontext übernommen werden.

Beispielsweise werden ausgeschlossen:

```text
node_modules/
.git/
.env
.github/
docs/
tests/
scripts/
security_scan_ergebnis.txt
compose.yaml
```

Lokale `.env`-Dateien werden ausgeschlossen.

Die Beispieldatei:

```text
.env.example
```

darf weiterhin im Repository vorhanden sein.

---

# Docker Compose

Docker Compose wird für die lokale Mehr-Container-Umgebung verwendet.

Der grundsätzliche Aufbau ist:

```text
Docker Compose
  |
  +--> Pacman
  |
  +--> MongoDB
  |
  +--> Netzwerk
  |
  +--> Persistenz / Volumes
```

Die Konfiguration befindet sich in:

```text
compose.yaml
```

---

# Lokalen Compose-Stack starten

Der Stack kann direkt gestartet werden:

```bash
docker compose up -d
```

oder über das Hilfsskript:

```bash
./scripts/local-start.sh
```

Das Startskript prüft unter anderem:

- Docker CLI vorhanden
- Docker-Daemon erreichbar
- Docker Compose vorhanden
- `compose.yaml` vorhanden
- Compose-Konfiguration gültig

Anschließend wird der Stack gestartet und der Service-Status angezeigt.

---

# Lokalen Compose-Stack stoppen

Der Stack kann über:

```bash
./scripts/local-stop.sh
```

kontrolliert beendet werden.

Intern wird:

```bash
docker compose down
```

verwendet.

Persistente Volumes werden dabei bewusst nicht mit `-v` gelöscht.

Dadurch bleiben lokale MongoDB-Daten über einen Stop-/Start-Zyklus erhalten.

---

# Smoke-Test

Der Smoke-Test befindet sich unter:

```text
tests/smoke-test.sh
```

Er prüft die grundlegende HTTP-Erreichbarkeit der Anwendung.

Ausführung:

```bash
./tests/smoke-test.sh
```

Der Test verwendet einen HTTP-Aufruf auf:

```text
http://localhost:8080
```

und erwartet eine erfolgreiche Antwort.

Der Test ist bewusst klein gehalten.

Er bestätigt:

- Webserver erreichbar
- Port 8080 erreichbar
- kein HTTP-Fehler auf der Startseite

Er bestätigt nicht automatisch:

- vollständige MongoDB-Funktion
- Highscore-Speicherung
- Kubernetes-Funktion
- GitOps-Funktion
- Backup/Restore

Diese Bereiche werden getrennt getestet.

---

# Lasttest

Das Lasttest-Skript befindet sich unter:

```text
scripts/load-test.sh
```

Beispiel:

```bash
./scripts/load-test.sh http://pacman-dev.local 120 10
```

Die Parameter bedeuten:

```text
http://pacman-dev.local = Ziel
120                     = Dauer in Sekunden
10                      = Anzahl paralleler Worker
```

Ein Worker entspricht nicht einem einzelnen Request.

Jeder Worker sendet während der Testdauer fortlaufend HTTP-Requests.

Beispiel:

```text
                    Hauptskript
                         |
                  startet Worker
                         |
            +------------+------------+
            |            |            |
         Worker 1     Worker 2     Worker 3
            |            |            |
         curl-loop     curl-loop     curl-loop
            |            |            |
       Erfolg/Fehler Erfolg/Fehler Erfolg/Fehler
```

Das Skript zählt:

- erfolgreiche Requests
- fehlgeschlagene Requests
- Gesamtzahl der Requests
- tatsächliche Testdauer

Es dient unter anderem als Hilfsmittel für spätere HPA-Tests.

CPU- oder RAM-Verbrauch misst das Skript nicht selbst.

Diese Werte werden über Kubernetes- beziehungsweise Monitoring-Werkzeuge betrachtet.

---

# GitHub Actions

Die GitHub-Actions-Workflows befinden sich unter:

```text
.github/workflows/
```

Aktuell vorhanden:

```text
ci.yml
release.yml
```

Die genaue Aufgabenverteilung wird durch die jeweilige Workflow-Datei definiert.

Typische Aufgaben der CI sind:

```text
Repository Checkout
  |
  v
Node.js einrichten
  |
  v
Abhängigkeiten installieren
  |
  v
Tests
  |
  v
Docker-Build
  |
  v
Security-/Qualitätsprüfungen
```

Die konkreten Trigger, Berechtigungen, Tags und Release-Schritte müssen immer anhand der tatsächlichen Workflow-Dateien bewertet werden.

---

# Unterschied zwischen `npm ci` und CI

`npm ci` ist ein einzelner Befehl zur reproduzierbaren Installation von Node.js-Abhängigkeiten.

Ein CI-Run bezeichnet dagegen einen vollständigen automatisierten Pipeline-Durchlauf.

Beispiel:

```text
CI-Run
  |
  +--> Checkout
  |
  +--> npm ci
  |
  +--> Tests
  |
  +--> Docker Build
  |
  +--> Security-Prüfungen
```

---

# GitHub Container Registry

Container-Images werden über GHCR bereitgestellt.

Wichtige Begriffe sind:

## Commit-SHA

Die Commit-SHA identifiziert einen konkreten Git-Stand.

Beispiel:

```text
6f6a378
```

Sie ermöglicht die Zuordnung eines Images zum Quellcode.

## Image-Tag

Ein Tag ist eine lesbare Referenz auf ein Container-Image.

Beispiele:

```text
dev
prod
sha-1234567
```

Tags können abhängig vom Prozess verändert beziehungsweise neu zugeordnet werden.

## Image-Digest

Der Digest ist ein kryptografischer Identifier für den tatsächlichen Image-Inhalt.

Beispiel:

```text
sha256:...
```

Der Digest ist für eine eindeutige und unveränderliche Zuordnung besonders wichtig.

---

# Kubernetes und GitOps

Die Kubernetes-Konfiguration befindet sich nicht primär in diesem Repository.

Der gewünschte Kubernetes-Sollzustand wird im Repository:

```text
pacman-gitops
```

verwaltet.

Dort werden unter anderem behandelt:

- Namespace
- Deployment
- Service
- StatefulSet
- Headless Service
- PVC
- ConfigMap
- Secret
- ServiceAccount
- Ingress
- NetworkPolicy
- Ressourcenlimits
- Probes
- HPA
- PDB
- LimitRange
- ResourceQuota
- Kustomize
- Argo CD

---

# GitOps-Prinzip

Git dient als Quelle des gewünschten Zustands.

Der Ablauf ist grundsätzlich:

```text
Änderung in Git
  |
  v
Pull Request / Review
  |
  v
Merge
  |
  v
Argo CD erkennt neuen Sollzustand
  |
  v
Vergleich mit Kubernetes-Istzustand
  |
  v
Synchronisation
```

Dadurch werden manuelle Änderungen am Cluster reduziert und Änderungen bleiben über Git nachvollziehbar.

---

# Argo-CD-Zustände

Wichtige Zustände sind:

## Synced

Der in Git definierte Sollzustand entspricht dem Zustand im Cluster.

## OutOfSync

Git-Sollzustand und Cluster-Istzustand unterscheiden sich.

## Healthy

Die verwalteten Kubernetes-Ressourcen befinden sich in einem funktionsfähigen Zustand.

## Degraded

Eine oder mehrere Ressourcen weisen einen fehlerhaften Zustand auf.

`Synced` und `Healthy` beschreiben unterschiedliche Aspekte.

Ein System kann beispielsweise:

```text
Synced + Degraded
```

oder:

```text
OutOfSync + Healthy
```

sein.

---

# Security

Im Repository dürfen keine echten Zugangsdaten gespeichert werden.

Dazu gehören insbesondere:

- Passwörter
- Tokens
- private Schlüssel
- kubeconfig-Dateien
- Secret-Werte
- produktive `.env`-Dateien

Die `.env.example` dient ausschließlich als Vorlage.

---

# Logging

Logs sollen technische Fehler verständlich darstellen, aber keine Secrets offenlegen.

Insbesondere sollten nicht ausgegeben werden:

- Passwörter
- Tokens
- vollständige Connection-Strings mit Credentials
- Secret-Werte

Die MongoDB-Fehlerbehandlung wurde entsprechend so angepasst, dass keine vollständige Verbindungs-URL geloggt wird.

---

# Qualitätssicherung

Zur Qualitätssicherung werden unter anderem eingesetzt:

- Git
- Branches
- Pull Requests
- reproduzierbare Dependency-Installation
- Smoke-Test
- Docker-Build
- CI-Automatisierung
- Security-Scans
- Container-Härtung
- GitOps
- nachvollziehbare Release-Prozesse

---

# Nachvollziehbarkeit mit Git

Änderungen werden versioniert und über Commits nachvollziehbar gemacht.

Der grundlegende Arbeitsablauf ist:

```bash
git status
git diff
git add <dateien>
git commit -m "Kurze professionelle Nachricht"
git push origin main
```

Dadurch sind unter anderem nachvollziehbar:

- was geändert wurde
- wann es geändert wurde
- welcher Commit den Stand enthält
- welche Dateien betroffen waren

---

# Monitoring

Für den Kubernetes-Betrieb sind Monitoring-Komponenten wie Prometheus und Grafana vorgesehen beziehungsweise im GitOps-Kontext zu betrachten.

Dabei werden insbesondere unterschieden:

- technische Metriken
- Ressourcenverbrauch
- Alerts
- erwartete Alerts
- echte Fehler
- Plattformgrenzen

Die konkrete Monitoring-Konfiguration befindet sich im GitOps-/Betriebsbereich des Gesamtprojekts.

---

# Backup und Restore

MongoDB-Backup und Restore gehören ebenfalls zur Betriebsseite des Gesamtprojekts.

Ein vollständiger Restore-Nachweis besteht nicht nur aus einem erfolgreichen Restore-Job.

Ein sinnvoller Nachweis ist:

```text
Testdatensatz anlegen
  |
  v
Backup erstellen
  |
  v
Datensatz kontrolliert löschen/verändern
  |
  v
Restore durchführen
  |
  v
Datensatz wieder vorhanden
  |
  v
Anwendung funktioniert
```

---

# Projektgrenzen

Dieses Repository konzentriert sich auf:

- Anwendung
- lokale Ausführung
- Docker
- Tests
- CI
- Release-Vorbereitung

Kubernetes-, GitOps-, Monitoring- und Betriebsressourcen werden getrennt im GitOps-Repository verwaltet.

---

# Wichtige lokale Befehle

## Abhängigkeiten installieren

```bash
npm ci
```

## Anwendung direkt starten

```bash
npm start
```

## Docker-Image bauen

```bash
docker build -t pacman-app .
```

## Compose-Stack starten

```bash
./scripts/local-start.sh
```

oder:

```bash
docker compose up -d
```

## Smoke-Test

```bash
./tests/smoke-test.sh
```

## Load-Test

```bash
./scripts/load-test.sh http://pacman-dev.local 120 10
```

## Compose-Stack stoppen

```bash
./scripts/local-stop.sh
```

---

# Prüfbarkeit und Nachweise

Für Änderungen und technische Entscheidungen werden nach Möglichkeit folgende Nachweise verwendet:

- Git-Commit
- Git-Diff
- GitHub Actions
- Docker-Build-Ausgabe
- Container-Status
- Smoke-Test
- Security-Scan
- Screenshots
- Kubernetes-Ressourcenstatus
- Argo-CD-Status
- Monitoring
- Backup-/Restore-Nachweise

Ein technischer Schritt gilt erst dann als erfolgreich, wenn ein geeigneter Nachweis vorliegt.

---

# Lizenz

GPLv3
