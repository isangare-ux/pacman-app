# Sicherheitsmaßnahmen im Dockerfile verbessert und bewährte Sicherheitspraktiken umgesetzt.
# Die Anwendung wird als nicht privilegierter Benutzer ausgeführt, um das Sicherheitsrisiko zu reduzieren.

# Verwendet das offizielle Node.js 22 Alpine-Image als schlanke Basis.
FROM node:16.19.0-bullseye-slim 

# Setzt Metadaten für das Image (hier: verantwortliche Person), sichtbar über "docker inspect".
LABEL maintainer="Ibrahim Sangaré"

# Legt das Arbeitsverzeichnis innerhalb des Containers fest.
WORKDIR /usr/src/app

# Kopiert package.json und package-lock.json in das Arbeitsverzeichnis.
# Dadurch kann Docker die Installation der Abhängigkeiten zwischenspeichern (Layer-Cache).
COPY package*.json ./

# Installiert ausschließlich die produktiven Abhängigkeiten.
# Entwicklungsabhängigkeiten werden nicht in das Image übernommen.
# npm ci sorgt für einen reproduzierbaren Build anhand der package-lock.json.
RUN npm ci --omit=dev

# Kopiert den vollständigen Anwendungscode in den Container.
COPY . .

# Führt die Anwendung als Benutzer "node" aus,
# um die Sicherheit des Containers zu erhöhen.
USER node

# Dokumentiert den von der Anwendung verwendeten Port.
EXPOSE 8080

# Startet die Anwendung über das in package.json definierte Startskript.
CMD ["npm", "start"]