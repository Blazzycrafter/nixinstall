#!/usr/bin/env bash
set -euo pipefail

# Prüfen, ob die Token-Datei existiert
if [[ ! -f "token" ]]; then
  echo "[ERROR] Die Datei 'token' wurde nicht gefunden!"
  exit 1
fi

# Token auslesen und Leerzeichen/Zeilenumbrüche entfernen
TOKEN=$(cat token | tr -d '[:space:]')

# Aktuelle Remote-URL holen (z. B. https://github.com/user/repo.git)
CURRENT_URL=$(git remote get-url origin)

# Falls bereits Anmeldeinformationen in der URL sind, diese bereinigen
CLEAN_URL=$(echo "$CURRENT_URL" | sed -E 's|https://.*@|https://|')

# Token in die HTTPS-URL einfügen: https://TOKEN@github.com/...
NEW_URL=$(echo "$CLEAN_URL" | sed -E "s|https://|https://${TOKEN}@|")

# Git Remote-URL aktualisieren
git remote set-url origin "$NEW_URL"

echo "[SUCCESS] Git wurde erfolgreich mit dem Token konfiguriert! Du kannst jetzt 'git push' machen."
