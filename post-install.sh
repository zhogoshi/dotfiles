#!/usr/bin/env bash
set -euo pipefail

if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  echo "This script should NOT be run as root. It will prompt for sudo when needed."
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting post-installation setup..."

echo "Disabling setupMode in flake.nix..."
sed -i 's|setupMode = true;|setupMode = false;|g' "$REPO_ROOT/flake.nix"

echo "Updating assets/hyprland.conf and installing Ambxst..."
HYPR="$REPO_ROOT/assets/hyprland.conf"

OVERRIDES="$(sed -n '/^# --- USER OVERRIDES ---$/,/^# ----------------------$/p' "$HYPR")"
sed -i '/^# --- USER OVERRIDES ---$/,/^# ----------------------$/d' "$HYPR"
sed -i '/^# --- SETUP MODE BINDS ---$/,/^# ------------------------$/ s/^\([^#]\)/# \1/' "$HYPR"

curl -fsSL get.axeni.de/ambxst | sh
ambxst install hyprland

printf '\n%s\n' "$OVERRIDES" >> "$HYPR"

echo "Rebuilding NixOS configuration..."
sudo nixos-rebuild switch --flake "/etc/nixos#nixos"

echo "Post-installation complete! You may want to restart Hyprland or reboot."
