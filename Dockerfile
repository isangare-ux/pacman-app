# Basis-Image: Node 16 auf schlankem Debian Bullseye für eine kleine Image-Größe
FROM node:16.19.0-bullseye-slim

LABEL maintainer="Ibrahim Sangaré"

# Installation von curl für den Healthcheck
RUN apt-get update \
  && apt-get install -y --no-install-recommends curl \
  && rm -rf /var/lib/apt/lists/*

# Arbeitsverzeichnis im Container festlegen
WORKDIR /usr/src/app

# Nur die package-Dateien kopieren, um den Docker-Layer-Cache
# bei unveränderten Abhängigkeiten optimal zu nutzen
COPY package*.json ./

# Produktionsabhängigkeiten reproduzierbar installieren (ohne devDependencies)
RUN npm ci --omit=dev

# Restlichen Anwendungscode in den Container kopieren
COPY . .

# Auf einen nicht-privilegierten Benutzer wechseln (Security Best Practice)
USER node

# Port, auf dem die Anwendung im Container lauscht
EXPOSE 8080

# Startbefehl des Containers
CMD ["npm", "start"]