#!/usr/bin/env bash
# Stoppt das Skript sofort bei jedem Fehler und gibt unexpandierte Variablen aus
set -euo pipefail

DISK="${1:-/dev/sda}"

echo "[INFO] Start des Installationsskripts auf Platte: $DISK"

echo "[STEP] Versuche eventuell noch aktive Mounts zu lösen (/mnt/boot und /mnt)..."
sudo umount /mnt/boot 2>/dev/null && echo "[OK] /mnt/boot erfolgreich unmountet" || echo "[INFO] /mnt/boot war nicht gemountet."
sudo umount /mnt 2>/dev/null && echo "[OK] /mnt erfolgreich unmountet" || echo "[INFO] /mnt war nicht gemountet."

echo "[STEP] Lösche alle alten Signaturen und Partitionstabellen mit wipefs auf $DISK..."
sudo wipefs -a "$DISK"
echo "[OK] wipefs erfolgreich ausgeführt."

echo "[STEP] Schreibe eine neue GPT-Partitionstabelle auf $DISK..."
sudo parted --script "$DISK" mklabel gpt
echo "[OK] GPT-Tabelle erfolgreich geschrieben."

echo "[STEP] Erstelle EFI-Boot-Partition (1MiB bis 512MiB)..."
sudo parted --script "$DISK" mkpart ESP fat32 1MiB 512MiB
echo "[OK] EFI-Partition erstellt."

echo "[STEP] Setze das 'boot on'-Flag für die EFI-Partition (Index 1)..."
sudo parted --script "$DISK" set 1 boot on
echo "[OK] Boot-Flag gesetzt."

echo "[STEP] Erstelle Swap-Partition (512MiB bis 8512MiB)..."
sudo parted --script -- "$DISK" mkpart primary linux-swap 512MiB 8512MiB
echo "[OK] Swap-Partition erstellt."

echo "[STEP] Erstelle Root-Partition (8512MiB bis 100%)..."
sudo parted --script -- "$DISK" mkpart primary ext4 8512MiB 100%
echo "[OK] Root-Partition erstellt."

echo "[STEP] Zeige das aktuelle Layout der Festplatte an (lsblk)..."
lsblk "$DISK"

# Partitionsnamen bestimmen
if [[ "$DISK" =~ nvme ]]; then
  PART_BOOT="${DISK}p1"
  PART_SWAP="${DISK}p2"
  PART_ROOT="${DISK}p3"
else
  PART_BOOT="${DISK}1"
  PART_SWAP="${DISK}2"
  PART_ROOT="${DISK}3"
fi
echo "[INFO] Ermittelte Partitionsnamen -> Boot: $PART_BOOT | Swap: $PART_SWAP | Root: $PART_ROOT"

echo "[STEP] Formatiere EFI-Partition ($PART_BOOT) als FAT32 mit Label 'BOOT'..."
sudo mkfs.fat -F 32 -n BOOT "$PART_BOOT"
echo "[OK] EFI-Partition formatiert."

echo "[STEP] Formatiere Swap-Partition ($PART_SWAP) mit Label 'swap'..."
sudo mkswap -L swap "$PART_SWAP"
echo "[OK] Swap eingerichtet."

echo "[STEP] Formatiere Root-Partition ($PART_ROOT) als ext4 mit Label 'nixos'..."
sudo mkfs.ext4 -F -L nixos "$PART_ROOT"
echo "[OK] Root-Partition formatiert."

echo "[STEP] Warte, bis udev alle Labels und Gerätedateien registriert hat..."
sudo udevadm settle
sync
sleep 2
echo "[OK] Warten abgeschlossen."

echo "[STEP] Erstelle Mount-Verzeichnis für Root (/mnt)..."
sudo mkdir -p /mnt
echo "[OK] /mnt Verzeichnis bereit."

echo "[STEP] Mounte Root-Partition unter /mnt..."
sudo mount /dev/disk/by-label/nixos /mnt
echo "[OK] Root erfolgreich eingehängt."

echo "[STEP] Erstelle Boot-Verzeichnis innerhalb des eingehängten Systems (/mnt/boot)..."
sudo mkdir -p /mnt/boot
echo "[OK] /mnt/boot Verzeichnis erstellt."

echo "[STEP] Mounte EFI-Boot-Partition unter /mnt/boot..."
sudo mount -o umask=077 /dev/disk/by-label/BOOT /mnt/boot
echo "[OK] Boot-Partition erfolgreich eingehängt."

echo "[STEP] Aktiviere Swap..."
sudo swapon "$PART_SWAP"
echo "[OK] Swap aktiviert."

echo "[SUCCESS] Alle Schritte wurden fehlerfrei durchlaufen! Das System ist bereit für 'nixos-generate-config --root /mnt'."
