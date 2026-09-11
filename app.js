'use strict';

// Lade die benötigten Module: Express für den Webserver,
// path für Dateipfade und Database für die Verbindung zur Datenbank.
// ====================================================
// 1. Module und Abhängigkeiten
// ====================================================
var express = require('express');
var path = require('path');
var Database = require('./lib/database');
var assert = require('assert');

// ====================================================
// 2. Routen importieren
// ====================================================
// Importiere die einzelnen Route-Module für die API-Endpunkte.
var highscores = require('./routes/highscores');
var user = require('./routes/user');
var loc = require('./routes/location');

// ====================================================
// 3. Express-App initialisieren
// ====================================================
// Erstellt eine neue Express-Anwendung.
var app = express();

// ====================================================
// 4. View-Engine und statische Dateien
// ====================================================
// Konfiguriere den View-Renderer: Templates liegen im Ordner "views"
// und werden mit Pug gerendert.
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'pug');

// Stellt die statischen Dateien aus dem Ordner "public" bereit,
// z. B. HTML, CSS, JS und Bilder für die Frontend-Seite.
app.use('/', express.static(path.join(__dirname, 'public')));

// ====================================================
// 5. API-Routen registrieren
// ====================================================
// Registriert die einzelnen Routen:
// /highscores -> Punkteregister
// /user -> Benutzerlogik
// /location -> Standort-/Spielerpositionen
app.use('/highscores', highscores);
app.use('/user', user);
app.use('/location', loc);

// ====================================================
// 6. Fehlerbehandlung
// ====================================================
// Wenn keine Route passt, wird ein 404-Fehler erzeugt und
// an den Error-Handler weitergeleitet.
app.use(function (req, res, next) {
  var err = new Error('Not Found');
  err.status = 404;
  next(err);
});

// Zentraler Fehler-Handler für HTTP-Fehler.
app.use(function (err, req, res, next) {
  if (res.headersSent) {
    return next(err)
  }
  // Fehlernachricht nur in der Entwicklungsumgebung anzeigen.
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // Rendert die Fehlerseite aus dem Template "error".
  res.status(err.status || 500);
  res.render('error');
});

// ====================================================
// 7. Datenbankverbindung
// ====================================================
// Verbindet die App mit der Datenbank.
// Wenn die Verbindung fehlschlägt, wird eine Meldung ausgegeben.
Database.connect(app, function (err) {
  if (err) {
    console.log('Failed to connect to database server');
  } else {
    console.log('Connected to database server successfully');
  }

});

// ====================================================
// 8. App exportieren
// ====================================================
// Exportiert die Express-App, damit sie von anderen Dateien gestartet
// oder getestet werden kann.
module.exports = app;
