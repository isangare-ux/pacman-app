# Sicherheitsmaßnahmen im Dockerfile verbessert und bewährte Sicherheitspraktiken umgesetzt.
# Die Anwendung wird als nicht privilegierter Benutzer ausgeführt, um das Sicherheitsrisiko zu reduzieren.

# Verwendet die verbindlich vorgegebene feste Node.js-Basisversion.
FROM node:16.19.0-bullseye-slim

LABEL maintainer="Ibrahim Sangaré"

# Legt das Arbeitsverzeichnis innerhalb des Containers fest.
WORKDIR /usr/src/app

# Aktualisiert die installierten Betriebssystempakete und entfernt anschließend
# die Paketlisten, damit das Docker-Image möglichst klein bleibt.
RUN apt-get update \
  && apt-get upgrade -y \
  && rm -rf /var/lib/apt/lists/*

# Kopiert package.json und package-lock.json in das Arbeitsverzeichnis.
# Dadurch kann Docker die Installation der Abhängigkeiten zwischenspeichern (Layer-Cache).
COPY package*.json ./

# Installiert ausschließlich die produktiven Abhängigkeiten.
# Entwicklungsabhängigkeiten werden nicht in das Image übernommen.
# npm ci sorgt für einen reproduzierbaren Build anhand der package-lock.json.
#
# npm selbst wird zur Laufzeit nicht benötigt (Start erfolgt direkt über
# node, siehe CMD unten). Die in npm gebündelten Abhängigkeiten
# (u. a. brace-expansion, ip-address, picomatch, sigstore, tar) tauchen
# sonst als Schwachstellen im Runtime-Image auf, obwohl sie nur Build-Zeit
# betreffen. Daher wird npm nach der Installation vollständig aus dem
# finalen Image entfernt.

RUN npm ci --omit=dev \
    && npm cache clean --force \
    && rm -rf /usr/local/lib/node_modules/npm \
    && rm -f /usr/local/bin/npm /usr/local/bin/npx

# Kopiert den vollständigen Anwendungscode in den Container.
COPY . .

# Führt die Anwendung als Benutzer "node" aus,
# um die Sicherheit des Containers zu erhöhen.
USER node

# Dokumentiert den von der Anwendung verwendeten Port.
EXPOSE 8080

# Startet die Anwendung direkt über node (npm ist im Runtime-Image nicht
# mehr vorhanden, "npm start" würde daher fehlschlagen).
CMD ["node", "."]