
# Pacman-App

## Projektübersicht

Dieses Repository enthält die modernisierte Pacman-Anwendung auf Basis von Node.js und Express sowie die Konfiguration für die Continuous-Integration-Pipeline.

Die Anwendung wird containerisiert mit Docker bereitgestellt und anschließend über GitHub Container Registry (GHCR), Kubernetes und Argo CD automatisiert ausgeliefert.

---

## Projektstruktur

```
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

## Voraussetzungen

- Docker Desktop
- Kubernetes
- kubectl
- Git
- Node.js
- npm

---

## Lokale Entwicklung

Repository klonen

```bash
git clone https://github.com/isangare-ux/pacman-app.git
cd pacman-app
```

Abhängigkeiten installieren

```bash
npm install
```

Anwendung starten

```bash
npm start
```

---

## Docker

Image erstellen

```bash
docker build -t pacman-app .
```

Container starten

```bash
docker run -p 8080:8080 pacman-app
```

---

## Continuous Integration

Die CI-Pipeline wird über GitHub Actions ausgeführt.

Sie umfasst

- Quellcode-Checkout
- Installation der Abhängigkeiten
- Smoke-Test
- Docker Build
- Veröffentlichung nach GitHub Container Registry (GHCR)

---

## Lizenz

GPLv3
