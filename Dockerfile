#Sicherheitsmaßnahmen im Dockerfile verbessert. Nicht benötigte Berechtigungen reduziert und bewährte Sicherheitspraktiken umgesetzt
#Docker-Container so angepasst, dass die Anwendung unter einem nicht privilegierten Benutzer ausgeführt wird.
# Verwendet das offizielle Node.js 22 Alpine-Image als schlanke Basis.
FROM node:22-alpine

# Legt das Arbeitsverzeichnis innerhalb des Containers fest.
WORKDIR /usr/src/app

# Kopiert package.json und package-lock.json in das Arbeitsverzeichnis.
# Dadurch kann Docker den Layer für die Installation der Abhängigkeiten cachen.
COPY package*.json ./

# Installiert ausschließlich die produktiven Abhängigkeiten.
# Entwicklungsabhängigkeiten werden nicht in das Image übernommen.
# npm ci → Installiere genau diese festgelegten Versionen für einen reproduzierbaren Build.
RUN npm ci --omit=dev

# Kopiert den gesamten Anwendungscode in den Container.
COPY . .

# Führt die Anwendung mit dem Benutzer "node" aus,
# um die Sicherheit des Containers zu erhöhen.
USER node

# Dokumentiert, dass die Anwendung auf Port 8080 erreichbar ist.
EXPOSE 8080

# Startet die Anwendung über das in package.json definierte Startskript.
CMD ["npm", "start"]