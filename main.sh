#!/usr/bin/env bash
# Stoppt das Skript sofort bei jedem Fehler und gibt unexpandierte Variablen aus
set -euo pipefail

DISK="${1:-/dev/sda}"
REPO_DIR="$(pwd)"
NIXOS_DIR="/mnt/etc/nixos"

echo "[INFO] === STARTE HAUPTINSTALLATION (MAIN) ==="

# 1. Partitionierung und Mounting über das bestehende Skript triggern
if [[ -f "./part.sh" ]]; then
  echo "[STEP] Rufe partitionierungs-Skript auf..."
  bash ./part.sh "$DISK"
else
  echo "[ERROR] part.sh wurde im aktuellen Verzeichnis nicht gefunden!"
  exit 1
fi

echo "[STEP] Prüfe Status der 'configuration.nix'..."
if [[ -f "$REPO_DIR/configuration.nix" ]]; then
  echo "[OK] Vorhandene configuration.nix im Repo gefunden. Verwende diese."
else
  echo "[INFO] Keine configuration.nix im Repo gefunden. Starte Setup-Modus..."
  
  echo "[STEP] Generiere initiale NixOS-Konfiguration unter /mnt..."
  sudo nixos-generate-config --root /mnt
  
  echo "[STEP] Kopiere generierte Konfiguration ins Repository ($REPO_DIR)..."
  sudo cp /mnt/etc/nixos/configuration.nix "$REPO_DIR/configuration.nix"
  sudo cp /mnt/etc/nixos/hardware-configuration.nix "$REPO_DIR/hardware-configuration.nix"
  # Korrigiere die Dateirechte für den aktuellen Benutzer
  sudo chown -R "$USER:$USER" "$REPO_DIR/configuration.nix" "$REPO_DIR/hardware-configuration.nix"
  echo "[OK] Setup-Modus abgeschlossen: Konfigurationen gesichert."
fi

echo "[STEP] Übertrage Konfigurationen in das Zielsystem ($NIXOS_DIR)...[cite: 1]"
sudo mkdir -p "$NIXOS_DIR"

# configuration.nix kopieren
if [[ -f "$REPO_DIR/configuration.nix" ]]; then
  sudo cp "$REPO_DIR/configuration.nix" "$NIXOS_DIR/configuration.nix"
  echo "[OK] configuration.nix nach $NIXOS_DIR kopiert."
fi

# hardware-configuration.nix kopieren (falls vorhanden)
if [[ -f "$REPO_DIR/hardware-configuration.nix" ]]; then
  sudo cp "$REPO_DIR/hardware-configuration.nix" "$NIXOS_DIR/hardware-configuration.nix"
  echo "[OK] hardware-configuration.nix nach $NIXOS_DIR kopiert."
fi

# flake.nix optional kopieren
if [[ -f "$REPO_DIR/flake.nix" ]]; then
  echo "[STEP] flake.nix gefunden. Kopiere ins Zielsystem..."
  sudo cp "$REPO_DIR/flake.nix" "$NIXOS_DIR/flake.nix"
  echo "[OK] flake.nix kopiert."
else
  echo "[INFO] Keine flake.nix im Repo vorhanden. Überspringe diesen Schritt."
fi

echo ""
echo "======================================================================"
echo "[SUCCESS] Die Grundinstallation und Datei-Vorbereitung sind abgeschlossen!"
echo "Das System ist unter /mnt eingehängt und bereit."
echo "======================================================================"
echo "Das Skript pausiert jetzt hier und wartet auf deinen nächsten Schritt."
echo "Du kannst nun manuell Anpassungen vornehmen oder das System via chroot/rebuild bauen."#!/usr/bin/env bash
# Stoppt das Skript sofort bei jedem Fehler und gibt unexpandierte Variablen aus
set -euo pipefail

DISK="${1:-/dev/sda}"
REPO_DIR="$(pwd)"

echo "[INFO] === STARTE HAUPTINSTALLATION (MAIN) ==="

# 1. Partitionierung und Mounting über das bestehende Skript triggern
if [[ -f "./part.sh" ]]; then
  echo "[STEP] Rufe partitionierungs-Skript auf..."
  bash ./part.sh "$DISK"
else
  echo "[ERROR] part.sh wurde im aktuellen Verzeichnis nicht gefunden!"
  exit 1
fi

echo "[STEP] Prüfe Status der 'configuration.nix'..."
if [[ -f "$REPO_DIR/configuration.nix" ]]; then
  echo "[OK] Vorhandene configuration.nix im Repo gefunden. Verwende diese."
else
  echo "[INFO] Keine configuration.nix im Repo gefunden. Starte Setup-Modus..."
  
  echo "[STEP] Generiere initiale NixOS-Konfiguration unter /mnt..."
  sudo nixos-generate-config --root /mnt
  
  echo "[STEP] Kopiere generierte Konfiguration ins Repository ($REPO_DIR)..."
  sudo cp /mnt/etc/nixos/configuration.nix "$REPO_DIR/configuration.nix"
  sudo cp /mnt/etc/nixos/hardware-configuration.nix "$REPO_DIR/hardware-configuration.nix"
  # Korrigiere die Dateirechte für den aktuellen Benutzer
  sudo chown -R "$USER:$USER" "$REPO_DIR/configuration.nix" "$REPO_DIR/hardware-configuration.nix"
  echo "[OK] Setup-Modus abgeschlossen: Konfigurationen gesichert."
fi

echo "[STEP] Übertrage Konfigurationen in das Zielsystem ($NIXOS_DIR)..."
sudo mkdir -p "$NIXOS_DIR"

# configuration.nix kopieren
if [[ -f "$REPO_DIR/configuration.nix" ]]; then
  sudo cp "$REPO_DIR/configuration.nix" "$NIXOS_DIR/configuration.nix"
  echo "[OK] configuration.nix nach $NIXOS_DIR kopiert."
fi

# hardware-configuration.nix kopieren (falls vorhanden)
if [[ -f "$REPO_DIR/hardware-configuration.nix" ]]; then
  sudo cp "$REPO_DIR/hardware-configuration.nix" "$NIXOS_DIR/hardware-configuration.nix"
  echo "[OK] hardware-configuration.nix nach $NIXOS_DIR kopiert."
fi

# flake.nix optional kopieren
if [[ -f "$REPO_DIR/flake.nix" ]]; then
  echo "[STEP] flake.nix gefunden. Kopiere ins Zielsystem..."
  sudo cp "$REPO_DIR/flake.nix" "$NIXOS_DIR/flake.nix"
  echo "[OK] flake.nix kopiert."
else
  echo "[INFO] Keine flake.nix im Repo vorhanden. Überspringe diesen Schritt."
fi

echo ""
echo "======================================================================"
echo "[SUCCESS] Die Grundinstallation und Datei-Vorbereitung sind abgeschlossen!"
echo "Das System ist unter /mnt eingehängt und bereit."
echo "======================================================================"
echo "Das Skript pausiert jetzt hier und wartet auf deinen nächsten Schritt."
echo "Du kannst nun manuell Anpassungen vornehmen oder das System via chroot/rebuild bauen."
