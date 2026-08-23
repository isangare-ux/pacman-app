# Sicherheitsmaßnahmen im Dockerfile verbessert und bewährte
# Sicherheitspraktiken umgesetzt.

# Verwendet die verbindlich vorgegebene feste Node.js-Basisversion.
FROM node:16.19.0-bullseye-slim

LABEL maintainer="Ibrahim Sangaré"

# Legt das Arbeitsverzeichnis innerhalb des Containers fest.
WORKDIR /usr/src/app

# Aktualisiert die im Basisimage enthaltenen Debian-Pakete auf verfügbare
# Sicherheitsstände. Anschließend werden die Paketlisten entfernt.
RUN apt-get update \
  && apt-get upgrade -y \
  && rm -rf /var/lib/apt/lists/*

# Kopiert zunächst nur die Paketdefinitionen.
# Dadurch kann Docker den Dependency-Layer zwischenspeichern.
COPY package*.json ./

# Installiert ausschließlich produktive Abhängigkeiten reproduzierbar
# anhand der package-lock.json.
#
# npm wird nach der Installation entfernt, da die Anwendung zur Laufzeit
# direkt über Node.js gestartet wird. Dadurch wird die Runtime-Angriffsfläche
# reduziert.
RUN npm ci --omit=dev \
  && npm cache clean --force \
  && rm -rf /usr/local/lib/node_modules/npm \
  && rm -f /usr/local/bin/npm /usr/local/bin/npx

# Kopiert anschließend den Anwendungscode.
COPY . .

# Führt die Anwendung als nicht privilegierten Benutzer aus.
USER node

# Dokumentiert den verwendeten Anwendungsport.
EXPOSE 8080

# Startet die Anwendung direkt über Node.js.
CMD ["node", "."]