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

echo "Uncommenting monitor in assets/hyprland.conf..."
sed -i 's|^# monitor = |monitor = |g' "$REPO_ROOT/assets/hyprland.conf"

echo "Rebuilding NixOS configuration..."
sudo nixos-rebuild switch --flake "$REPO_ROOT#nixos"

echo "Post-installation complete! You may want to restart Hyprland or reboot."
