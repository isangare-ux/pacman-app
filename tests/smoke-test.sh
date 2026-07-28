#Smoke-Test ergänzt, um die Erreichbarkeit und grundlegende Funktionsfähigkeit der Anwendung automatisiert zu prüfen.
#!/bin/bash

curl -f http://localhost:8080

if [ $? -eq 0 ]; then
    echo "Smoke Test erfolgreich"
else
    echo "Smoke Test fehlgeschlagen"
    exit 1
fi