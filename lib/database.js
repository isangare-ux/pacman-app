'use strict';

var MongoClient = require('mongodb').MongoClient;
var config = require('./config');
var _db;

function Database() {
    this.connect = function(app, callback) {
            // Ab mongodb-Treiber 3.x liefert der connect()-Callback den
            // MongoClient statt (wie in 2.x) direkt das Db-Objekt. Der
            // konkrete Datenbankname steckt bereits im Verbindungsstring
            // (siehe lib/config.js), daher liefert client.db() ohne
            // Argument dieselbe Datenbank wie bisher.
            MongoClient.connect(config.database.url,
                                config.database.options,
                                function (err, client) {
                                    if (err) {
                                        console.log(err);
                                        console.log(config.database.url);
                                        console.log(config.database.options);
                                    } else {
                                        var db = client.db();
                                        _db = db;
                                        app.locals.db = db;
                                    }
                                    callback(err);
                                });
    }

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
            callback(null, _db);
        }

    }
}

module.exports = exports = new Database(); // Singleton
