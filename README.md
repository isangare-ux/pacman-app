# Pacman-App

## Projektübersicht

Dieses Projekt modernisiert eine historische Pacman-Node.js-Anwendung durch den Einsatz moderner DevOps-Praktiken. Ziel ist die Bereitstellung einer reproduzierbaren Entwicklungs- und Deployment-Umgebung mithilfe von Docker, GitHub Actions, GitHub Container Registry (GHCR), Kubernetes und GitOps.

---

## Projektziele

- Modernisierung einer bestehenden Node.js-Anwendung
- Containerisierung mit Docker
- Automatisierte Build- und Testprozesse mittels GitHub Actions
- Versionierung und Bereitstellung von Docker-Images über GHCR
- Deployment auf einem Kubernetes-Cluster
- GitOps-basierte Verwaltung der Kubernetes-Ressourcen mit Argo CD
- Grundlage für Monitoring mit Prometheus und Grafana


## Projektstatus

Dieses Projekt befindet sich in der aktiven Weiterentwicklung.

---

## Projektstruktur

```text
pacman-app/
├── app.js
├── package.json
├── Dockerfile
├── docker-compose.yml
├── tests/
├── .github/
│   └── workflows/
│       └── ci.yml
├── README.md
└── .gitignore
```

---

## Verwendete Technologien

| Technologie               | Zweck                         |
| ------------------------- | ----------------------------- |
| Node.js                   | Laufzeitumgebung              |
| Express.js                | Webframework                  |
| Docker                    | Containerisierung             |
| Docker Compose            | Lokale Entwicklungsumgebung   |
| GitHub Actions            | Continuous Integration        |
| GitHub Container Registry | Speicherung der Docker-Images |
| Kubernetes                | Container-Orchestrierung      |
| Argo CD                   | GitOps-Deployment             |
| Git                       | Versionsverwaltung            |

---

## Voraussetzungen

- Docker Desktop
- Kubernetes
- kubectl
- Git
- Node.js
- npm

---

## Lokale Entwicklung

### Repository klonen

```bash
git clone https://github.com/isangare-ux/pacman-app.git
cd pacman-app
```

### Abhängigkeiten installieren

```bash
npm install
```

### Anwendung starten

```bash
npm start
```

Die Anwendung ist anschließend unter folgender Adresse erreichbar:

```
http://localhost:8080
```

---

## Docker

### Docker-Image erstellen

```bash
docker build -t pacman-app .
```

### Container starten

```bash
docker run -d -p 8080:8080 --name pacman pacman-app
```

### Container stoppen

```bash
docker stop pacman
docker rm pacman
```

---

## Continuous Integration

Die CI-Pipeline wird automatisch bei jedem Push oder Pull Request ausgeführt.

Sie umfasst folgende Schritte:

- Checkout des Quellcodes
- Installation der Abhängigkeiten
- Durchführung eines Smoke-Tests
- Erstellung des Docker-Images
- Veröffentlichung des Images in der GitHub Container Registry (GHCR)

---

## Deployment

Für die Bereitstellung der Anwendung werden Kubernetes-Manifeste verwendet. Die Images werden aus der GitHub Container Registry bezogen und können automatisiert über Argo CD synchronisiert werden.

---

## Qualitätssicherung

Zur Sicherstellung der Softwarequalität kommen folgende Maßnahmen zum Einsatz:

- Git-Versionsverwaltung
- Pull Requests
- Automatisierte CI-Pipeline
- Smoke-Tests
- Docker-basierte reproduzierbare Build-Umgebung

---

## Lizenz

GPLv3
