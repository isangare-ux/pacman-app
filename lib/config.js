// Standardwerte
let service_host = process.env.MONGO_HOST ||
  process.env.MONGO_SERVICE_HOST ||
  process.env.MONGO_NAMESPACE_SERVICE_HOST ||
  'localhost';

let mongo_database = process.env.MONGO_DB ||
  process.env.MONGO_DATABASE ||
  'pacman';

let mongo_port = process.env.MONGO_PORT ||
  process.env.MY_MONGO_PORT ||
  '27017';

let auth_details = '';
let use_ssl = process.env.MONGO_USE_SSL === 'true';
let validate_ssl = process.env.MONGO_VALIDATE_SSL !== 'false';

// Authentifizierung (optional)
if (process.env.MONGO_AUTH_USER && process.env.MONGO_AUTH_PWD) {
  auth_details = `${process.env.MONGO_AUTH_USER}:${process.env.MONGO_AUTH_PWD}@`;
}

// Verbindung zu einem oder mehreren MongoDB-Hosts
const hosts = service_host.split(',');

const connection_details = hosts
  .map(host => `${host}:${mongo_port}`)
  .join(',');

// MongoDB-Konfiguration
const database = {
  url: `mongodb://${auth_details}${connection_details}/${mongo_database}`,
  options: {
    readPreference: 'secondaryPreferred'
  }
};

// Replica Set (optional)
if (process.env.MONGO_REPLICA_SET) {
  database.options.replicaSet = process.env.MONGO_REPLICA_SET;
}

// SSL (optional)
if (use_ssl) {
  database.options.ssl = true;
  database.options.sslValidate = validate_ssl;
}

exports.database = database;