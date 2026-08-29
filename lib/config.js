// Baut die MongoDB-Verbindungskonfiguration (URL + Options) ausschließlich
// aus Umgebungsvariablen auf. So kann dieselbe Anwendung ohne Codeänderung
// lokal (Defaults greifen) und in Kubernetes (Werte kommen aus ConfigMap/
// Secret, siehe pacman-gitops/apps/pacman/base/configmap.yaml) laufen.

// Defaultwerte für den Fall, dass keine der unten geprüften Variablen gesetzt ist
var service_host = 'localhost'
var auth_details = ''
var mongo_database = 'pacman'
var mongo_port = '27017'
var use_ssl = false
var validate_ssl = true
var connection_details = ''

// MONGO_NAMESPACE_SERVICE_HOST ist der Fallback für ältere/andere
// Kubernetes-Service-Discovery-Varianten, falls MONGO_SERVICE_HOST fehlt
if(process.env.MONGO_SERVICE_HOST) {
    service_host = process.env.MONGO_SERVICE_HOST
} else if(process.env.MONGO_NAMESPACE_SERVICE_HOST) {
    service_host = process.env.MONGO_NAMESPACE_SERVICE_HOST
}

if(process.env.MONGO_DATABASE) {
    mongo_database = process.env.MONGO_DATABASE
}

if(process.env.MY_MONGO_PORT) {
    mongo_port = process.env.MY_MONGO_PORT
}

// SSL/TLS-Verschlüsselung für die Verbindung zum MongoDB-Server aktivieren
if(process.env.MONGO_USE_SSL) {
    if(process.env.MONGO_USE_SSL.toLowerCase() == "true") {
        use_ssl = true
    }
}

// Erlaubt es, die Validierung des Server-Zertifikats gezielt abzuschalten
// (z. B. bei selbstsignierten Zertifikaten in Test-/Dev-Umgebungen)
if(process.env.MONGO_VALIDATE_SSL) {
    if(process.env.MONGO_VALIDATE_SSL.toLowerCase() == "false") {
        validate_ssl = false
    }
}

// Nur wenn beide Werte gesetzt sind, wird ein "user:pwd@"-Teil für die
// Connection-URL gebaut; sonst bleibt die Verbindung ohne Authentifizierung
if(process.env.MONGO_AUTH_USER && process.env.MONGO_AUTH_PWD) {
    auth_details = `${process.env.MONGO_AUTH_USER}:${process.env.MONGO_AUTH_PWD}@`
}

// service_host kann eine kommagetrennte Liste mehrerer Hosts sein (Replica
// Set mit mehreren Knoten). Jeder Host bekommt denselben Port angehängt,
// z. B. "host1,host2" -> "host1:27017,host2:27017"
var hosts = service_host.split(',')

for (let i=0; i<hosts.length;i++) {
  connection_details += `${hosts[i]}:${mongo_port},`
}

// Trailing-Komma aus der Schleife oben wieder entfernen
connection_details = connection_details.replace(/,\s*$/, "");

// readPreference 'secondaryPreferred': Lesezugriffe werden bevorzugt von
// Secondary-Knoten eines Replica Sets bedient, um den Primary zu entlasten;
// ohne Secondary wird trotzdem der Primary genutzt
var database = {
    url: `mongodb://${auth_details}${connection_details}/${mongo_database}`,
    options: {
        readPreference: 'secondaryPreferred'
    }
};

// Nur bei echtem Replica-Set-Betrieb gesetzt (Name muss mit der
// Server-Konfiguration übereinstimmen, siehe mongodb-statefulset.yaml)
if(process.env.MONGO_REPLICA_SET) {
    database.options.replicaSet = process.env.MONGO_REPLICA_SET
}

if(use_ssl) {
    database.options.ssl = use_ssl
    database.options.sslValidate = validate_ssl
}

exports.database = database;
