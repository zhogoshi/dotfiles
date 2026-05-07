#!/usr/bin/env bash
set -euo pipefail

curl -fsSL https://raw.githubusercontent.com/zhogoshi/dotfiles/main/setup-nixos.sh -o setup-nixos.sh
bash ./setup-nixos.sh