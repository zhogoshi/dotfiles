#!/usr/bin/env bash
set -euo pipefail
sleep 5
echo "Downloading setup-nixos.sh..."
curl -fL https://raw.githubusercontent.com/zhogoshi/dotfiles/main/setup-nixos.sh -o setup-nixos.sh
chmod +x setup-nixos.sh
echo "Starting installer..."
bash ./setup-nixos.sh