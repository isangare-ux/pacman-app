'use strict';

var MongoClient = require('mongodb').MongoClient;
var config = require('./config');
var _db;

// Kapselt den Verbindungsaufbau zur MongoDB und hält die Verbindung als
// Singleton (siehe module.exports unten), damit nicht bei jedem Request
// neu verbunden werden muss.
function Database() {

  // Baut die Verbindung anhand der in lib/config.js zusammengesetzten
  // URL/Options auf und legt das Db-Objekt sowohl im Modul (_db, für
  // spätere getDb()-Aufrufe) als auch an app.locals.db ab, damit
  // Express-Routen direkt darauf zugreifen können.
  this.connect = function (app, callback) {

    // Ab mongodb-Treiber 3.x liefert der connect()-Callback den
    // MongoClient statt (wie in 2.x) direkt das Db-Objekt. Der
    // konkrete Datenbankname steckt bereits im Verbindungsstring
    // (siehe lib/config.js), daher liefert client.db() ohne
    // Argument dieselbe Datenbank wie bisher.
    MongoClient.connect(
      config.database.url,
      config.database.options,
      function (err, client) {

        if (err) {
          // Loggt nur eine bereinigte Fehlermeldung ohne vollständige
          // Verbindungs-URL oder Optionen, damit mögliche Zugangsdaten
          // nicht versehentlich in Terminal-, Container- oder CI-Logs erscheinen.
          console.error('MongoDB connection failed:', err.message);
        } else {
          var db = client.db();
          _db = db;
          app.locals.db = db;
        }

        callback(err);
      }
    );
  }

  // Liefert die aktive Datenbankverbindung; verbindet lazy beim ersten
  // Aufruf und gibt bei jedem weiteren Aufruf die bereits bestehende
  // Verbindung zurück, statt erneut zu verbinden.
  this.getDb = function (app, callback) {
    if (!_db) {
      this.connect(app, function (err) {
        if (err) {
          console.log('Failed to connect to database server');
        } else {
          console.log('Connected to database server successfully');
        }

        callback(err, _db);
      });
    } else {
      callback(null, _db);
    }
  }
}

module.exports = exports = new Database(); // Singleton: eine gemeinsame Verbindung für die gesamte App