'use strict';

// MongoClient ist die offizielle Klasse aus dem mongodb-Paket,
// um eine Verbindung zur MongoDB-Datenbank herzustellen.
var MongoClient = require('mongodb').MongoClient;

// config enthält die Datenbankverbindungs-URL und Optionen
// (z.B. Host, Port, Datenbankname) aus der zentralen Konfigurationsdatei.
var config = require('./config');

// Speichert die aktive Datenbankverbindung, damit sie nicht bei
// jedem Aufruf neu aufgebaut werden muss (Singleton-Muster).
var _db;

function Database() {

    // Baut eine neue Verbindung zur MongoDB auf.
    // Wird intern von getDb() aufgerufen, wenn noch keine Verbindung besteht.
    this.connect = function(app, callback) {
            MongoClient.connect(config.database.url,
                                config.database.options,
                                function (err, db) {
                                    if (err) {
                                        // Verbindung fehlgeschlagen: Fehler und
                                        // Verbindungsdaten zur Fehleranalyse ausgeben.
                                        console.log(err);
                                        console.log(config.database.url);
                                        console.log(config.database.options);
                                    } else {
                                        // Verbindung erfolgreich: Datenbankreferenz
                                        // lokal und in der Express-App speichern,
                                        // damit alle Routen darauf zugreifen können.
                                        _db = db;
                                        app.locals.db = db;
                                    }
                                    callback(err);
                                });
    }

    // Gibt die aktive Datenbankverbindung zurück.
    // Existiert noch keine Verbindung, wird zuerst connect() aufgerufen.
    this.getDb = function(app, callback) {
        if (!_db) {
            this.connect(app, function(err) {
                if (err) {
                    console.log('Failed to connect to database server');
                } else {
                    console.log('Connected to database server successfully');
                }

                callback(err, _db);
            });
        } else {
            // Verbindung bereits vorhanden: direkt zurückgeben,
            // ohne erneuten Verbindungsaufbau.
            callback(null, _db);
        }

    }
}

// Exportiert eine einzige gemeinsame Instanz (Singleton),
// sodass die gesamte Anwendung dieselbe Datenbankverbindung nutzt.
module.exports = exports = new Database();
