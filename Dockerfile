# Verwendet die verbindlich vorgegebene feste Node.js-Basisversion.
FROM node:16.19.0-bullseye-slim

LABEL maintainer="Ibrahim Sangaré"

# Arbeitsverzeichnis im Container.
WORKDIR /usr/src/app

# Zuerst nur Paketdefinitionen kopieren.
# Dadurch kann Docker den Dependency-Layer cachen.
COPY package*.json ./

# Installiert ausschließlich produktive Abhängigkeiten
# reproduzierbar anhand der package-lock.json.
#
# npm wird anschließend entfernt, sofern die Anwendung
# direkt mit node gestartet werden kann.
RUN npm ci --omit=dev \
  && npm cache clean --force \
  && rm -rf /usr/local/lib/node_modules/npm \
  && rm -f /usr/local/bin/npm /usr/local/bin/npx

# Anwendungscode kopieren.
COPY . .

# Anwendung läuft als nicht privilegierter Benutzer.
USER node

# Dokumentierter Anwendungsport.
EXPOSE 8080

# WICHTIG:
# Erst nach Prüfung von package.json den tatsächlichen
# Startbefehl hier eintragen.
CMD ["node", "."]