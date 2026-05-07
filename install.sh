#!/usr/bin/env bash
# Run on a fresh NixOS live ISO to bootstrap the system.
set -euo pipefail

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "This installer must run as root."
  echo 'Use: sudo bash install.sh'
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERNAME=""
INIT_PASS=""
KB_LAYOUT="us"
BROWSER_CHOICE=""
PRIMARY_DISK=""
PRIMARY_DEV=""
INSTALL_OK=0
WARNINGS=()
CRITICALS=()
RUN_TMP=""
FAIL_DETAIL_LABELS=()
FAIL_DETAIL_FILES=()

# ── Colors & TUI ──
R='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
CY='\033[36m'
GR='\033[32m'
YE='\033[33m'
RE='\033[31m'

hide_cursor()  { printf '\033[?25l'; }
show_cursor()  { printf '\033[?25h'; }
clear_screen() { printf '\033[2J\033[H'; }

trap 'show_cursor; rm -rf "${RUN_TMP}" 2>/dev/null || true' EXIT

_abort_install() {
  show_cursor
  clear_screen
  rm -rf "$RUN_TMP" 2>/dev/null || true
  printf '%s\n' "Aborting installation..."
  trap - INT TERM
  exit 130
}
trap '_abort_install' INT TERM

_init_run_tmp() {
  [ -n "$RUN_TMP" ] && return 0
  RUN_TMP="$(mktemp -d "${TMPDIR:-/tmp}/nixsetup.XXXXXX")" || RUN_TMP="${TMPDIR:-/tmp}"
}

_capt() {
  local label="$1" lf
  shift
  _init_run_tmp
  lf="$(mktemp "$RUN_TMP/cap.XXXXXX")"
  if "$@" >"$lf" 2>&1; then
    rm -f "$lf"
    return 0
  fi
  FAIL_DETAIL_LABELS+=("$label")
  FAIL_DETAIL_FILES+=("$lf")
  return 1
}

_review_fail_logs() {
  local rep i
  if [ ${#FAIL_DETAIL_LABELS[@]} -eq 0 ] && [ ${#WARNINGS[@]} -eq 0 ] && [ ${#CRITICALS[@]} -eq 0 ]; then
    return 0
  fi
  _init_run_tmp
  rep="$(mktemp "$RUN_TMP/review.XXXXXX")"
  {
    if [ ${#CRITICALS[@]} -gt 0 ]; then
      printf '%s\n' "=== Errors ==="
      printf '%s\n' "${CRITICALS[@]}"
      printf '\n'
    fi
    if [ ${#WARNINGS[@]} -gt 0 ]; then
      printf '%s\n' "=== Warnings ==="
      printf '%s\n' "${WARNINGS[@]}"
      printf '\n'
    fi
    if [ ${#FAIL_DETAIL_LABELS[@]} -gt 0 ]; then
      printf '%s\n' "=== Last 10 lines per captured command ==="
      for i in "${!FAIL_DETAIL_LABELS[@]}"; do
        printf '\n--- %s ---\n' "${FAIL_DETAIL_LABELS[$i]}"
        tail -n 10 "${FAIL_DETAIL_FILES[$i]}" 2>/dev/null || printf '%s\n' "(no output)"
      done
    fi
  } >"$rep"
  echo ""
  if command -v less >/dev/null 2>&1; then
    echo -e "  ${DIM}Scrollable log: arrows / PgUp·PgDn · q closes${R}"
    less -R "$rep" || true
  else
    cat "$rep"
    read -r -s -p "  Press Enter..." _ || true
  fi
  rm -f "$rep"
}

log() { echo -e "  ${DIM}▸${R} $*"; }
ok()  { echo -e "  ${GR}${BOLD}✓${R} $*"; }
warn(){ echo -e "  ${YE}${BOLD}⚠${R} $*"; WARNINGS+=("$*"); }
err() { echo -e "  ${RE}${BOLD}✗${R} $*"; CRITICALS+=("$*"); }

phase_header() {
  local num="$1" title="$2"
  local iw=46 bar="" mid titlepad i
  clear_screen
  for ((i = 0; i < iw; i++)); do bar+="═"; done
  echo -e ""
  echo -e "  ${CY}${BOLD}╔${bar}╗${R}"
  mid="  NixOS Installer  |  Phase ${num} of 10"
  [ ${#mid} -gt "$iw" ] && mid="${mid:0:iw}"
  printf -v mid '%-*s' "$iw" "$mid"
  echo -e "  ${CY}${BOLD}║${R}${BOLD}${mid}${R}${CY}${BOLD}║${R}"
  echo -e "  ${CY}${BOLD}╠${bar}╣${R}"
  titlepad="  ${title}"
  [ ${#titlepad} -gt "$iw" ] && titlepad="${titlepad:0:iw}"
  printf -v titlepad '%-*s' "$iw" "$titlepad"
  echo -e "  ${CY}${BOLD}║${R}${BOLD}${titlepad}${R}${CY}${BOLD}║${R}"
  echo -e "  ${CY}${BOLD}╚${bar}╝${R}"
  echo -e ""
}

# ── TUI: arrow-key single-select ──
tui_select() {
  local -n _result="$1"; shift
  local prompt="$1";     shift
  local items=("$@")
  local cur=0 total=${#items[@]} key esc

  hide_cursor
  echo -e "  ${BOLD}${prompt}${R}"
  echo -e "  ${DIM}(↑↓ select · Enter confirm)${R}"
  echo ""

  _render_list() {
    for i in "${!items[@]}"; do
      if [ "$i" -eq "$cur" ]; then
        echo -e "  ${CY}${BOLD}▶  ${items[$i]}${R}"
      else
        echo -e "     ${DIM}${items[$i]}${R}"
      fi
    done
  }

  printf '\033[s'
  _render_list

  while true; do
    IFS= read -r -s -n1 key
    if [ "$key" = $'\x1b' ]; then
      IFS= read -r -s -n1 esc
      IFS= read -r -s -n1 esc
      case "$esc" in
        A) if [ "$cur" -gt 0 ]; then cur=$(( cur - 1 )); fi ;;
        B) if [ "$cur" -lt $(( total - 1 )) ]; then cur=$(( cur + 1 )); fi ;;
      esac
    elif [ "$key" = "" ]; then
      break
    else
      continue
    fi
    printf '\033[u\033[0J'
    _render_list
  done

  printf '\033[u\033[0J'
  show_cursor
  echo -e "  ${GR}${BOLD}✓${R} ${BOLD}${prompt}${R}  ${CY}${items[$cur]}${R}"
  echo ""
  _result="${items[$cur]}"
}

# ── TUI: checkbox multi-select ──
tui_checkbox() {
  local -n _checked="$1"; shift
  local prompt="$1";      shift
  local items=("$@")
  local cur=0 total=${#items[@]} key esc
  local selected=()
  for _ in "${items[@]}"; do selected+=(0); done

  hide_cursor
  echo -e "  ${BOLD}${prompt}${R}"
  echo -e "  ${DIM}(↑↓ navigate · Space toggle · Enter continue)${R}"
  echo ""

  _render_cb() {
    for i in "${!items[@]}"; do
      local box="[ ]" ocol="$DIM"
      [ "${selected[$i]}" -eq 1 ] && box="[${GR}x${R}]" && ocol=""
      if [ "$i" -eq "$cur" ]; then
        echo -e "  ${CY}${BOLD}▶${R}  ${box} ${BOLD}${items[$i]}${R}"
      else
        echo -e "     ${box} ${ocol}${items[$i]}${R}"
      fi
    done
  }

  printf '\033[s'
  _render_cb

  while true; do
    IFS= read -r -s -n1 key
    if [ "$key" = $'\x1b' ]; then
      IFS= read -r -s -n1 esc
      IFS= read -r -s -n1 esc
      case "$esc" in
        A) if [ "$cur" -gt 0 ]; then cur=$(( cur - 1 )); fi ;;
        B) if [ "$cur" -lt $(( total - 1 )) ]; then cur=$(( cur + 1 )); fi ;;
      esac
    elif [ "$key" = " " ]; then
      selected[$cur]=$(( 1 - selected[$cur] ))
    elif [ "$key" = "" ]; then
      break
    else
      continue
    fi
    printf '\033[u\033[0J'
    _render_cb
  done

  printf '\033[u\033[0J'
  show_cursor

  _checked=()
  for i in "${!items[@]}"; do
    [ "${selected[$i]}" -eq 1 ] && _checked+=("${items[$i]}")
  done

  if [ ${#_checked[@]} -gt 0 ]; then
    echo -e "  ${GR}${BOLD}✓${R} ${BOLD}${prompt}${R}"
    for item in "${_checked[@]}"; do echo -e "    ${CY}▸${R} ${item}"; done
  else
    echo -e "  ${GR}${BOLD}✓${R} ${BOLD}${prompt}${R}  ${DIM}(none — English only)${R}"
  fi
  echo ""
}

# ── TUI: text input ──
tui_input() {
  local -n _inp="$1"; shift
  local prompt="$1" default="${2:-}"
  printf '  '
  printf '%b' "${BOLD}"
  printf '%b' "$prompt"
  printf '%b' "${R}"
  if [ -n "$default" ]; then
    printf ' %b[%s]%b  ' "${DIM}" "$default" "${R}"
  else
    printf '  '
  fi
  IFS= read -r _inp
  [ -z "$_inp" ] && _inp="$default"
  echo ""
}

# ── TUI: masked password input ──
tui_password() {
  local -n _pw="$1"; shift
  local prompt="$1" default="${2:-}"
  local _char _typed=""
  printf "  ${BOLD}%s${R} ${DIM}(hidden · enter = use default: %s)${R}  " "$prompt" "$default"
  while IFS= read -r -s -n1 _char; do
    if [ -z "$_char" ]; then
      break
    elif [ "$_char" = $'\x7f' ] || [ "$_char" = $'\b' ]; then
      if [ -n "$_typed" ]; then
        _typed="${_typed%?}"
        printf '\b \b'
      fi
    else
      _typed+="$_char"
      printf '*'
    fi
  done
  echo ""
  echo ""
  [ -z "$_typed" ] && _pw="$default" || _pw="$_typed"
}

# ── Phase 0: Welcome ──
phase_header "0" "Welcome"
echo -e "  This script will guide you through a full NixOS installation."
echo -e ""
echo -e "  ${YE}${BOLD}Requirements:${R}"
echo -e "    ${DIM}▸${R} Booted into a NixOS live ISO"
echo -e "    ${DIM}▸${R} Internet connection active"
echo -e "    ${DIM}▸${R} Target disk(s) visible under /dev/"
echo -e ""
read -r -s -p "  Press Enter to begin..." _
echo ""

# ── Phase 1: System Identity ──
phase_header "1" "System Identity"
echo -e "  Configure your username and login password."
echo ""

tui_input USERNAME "Username" "hogoshi"
tui_password INIT_PASS "Initial password" "changeme"

DEST="/home/$USERNAME/nixos"

echo -e "  ${GR}${BOLD}✓${R} Identity:"
echo -e "    ${DIM}▸${R} User:     ${CY}${USERNAME}${R}"
echo -e "    ${DIM}▸${R} Config:   ${CY}${DEST}${R}"
echo -e "    ${DIM}▸${R} Password: ${DIM}(set — hidden)${R}"
echo ""
read -r -s -p "  Press Enter to continue..." _
echo ""

# ── Phase 2: Keyboard Layouts ──
phase_header "2" "Keyboard Layouts"
echo -e "  ${GR}${BOLD}English (us)${R} is always included."
echo -e "  Select additional layouts. Cycle with ${CY}Alt+Shift${R}."
echo ""

_KB_OPTS=(
  "Russian    (ru)"
  "Spanish    (es)"
  "German     (de)"
  "French     (fr)"
  "Ukrainian  (ua)"
  "Polish     (pl)"
  "Japanese   (jp)"
  "Italian    (it)"
)

_KB_SELECTED=()
tui_checkbox _KB_SELECTED "Additional layouts:" "${_KB_OPTS[@]}"

KB_LAYOUT="us"
for _l in "${_KB_SELECTED[@]}"; do
  _code="${_l##*(}"
  _code="${_code%)}"
  _code="${_code// /}"
  KB_LAYOUT="${KB_LAYOUT},${_code}"
done

echo -e "  ${GR}${BOLD}✓${R} Active layout string:  ${CY}${BOLD}${KB_LAYOUT}${R}"
echo ""
read -r -s -p "  Press Enter to continue..." _
echo ""

# ── Phase 3: Browser ──
phase_header "3" "Browser"
echo -e "  Choose your default browser."
echo -e "  ${DIM}Zen Browser requires fetching from GitHub (github.com/youwen5/zen-browser-flake).${R}"
echo ""

tui_select BROWSER_CHOICE "Browser:" "Firefox" "Zen Browser"

# ── Phase 4: Disks to Format ──
phase_header "4" "Disks to Format"

mapfile -t ALL_DISKS < <(lsblk -dpno NAME,SIZE,MODEL \
  | grep -E '^/dev/(sd|nvme|vd)' \
  | awk '{printf "%s  (%s  %s)\n", $1, $2, $3}')

if [ ${#ALL_DISKS[@]} -eq 0 ]; then
  err "No disks detected. Is the system booted correctly?"
  show_cursor; exit 1
fi

FORMAT_DISKS=()
while [ ${#FORMAT_DISKS[@]} -eq 0 ]; do
  tui_checkbox FORMAT_DISKS "Select disks to format:" "${ALL_DISKS[@]}"
  if [ ${#FORMAT_DISKS[@]} -eq 0 ]; then
    warn "At least one disk must be selected."
  fi
done

# ── Phase 5: Installation Disk ──
phase_header "5" "Installation Disk"
echo -e "  ${DIM}Select which formatted disk NixOS will be installed on.${R}"
echo ""

PRIMARY_DISK=""
tui_select PRIMARY_DISK "Install NixOS on:" "${FORMAT_DISKS[@]}"
PRIMARY_DEV="${PRIMARY_DISK%% *}"

declare -A MOUNT_PATHS

for disk in "${FORMAT_DISKS[@]}"; do
  dev="${disk%% *}"
  [ "$dev" = "$PRIMARY_DEV" ] && continue
  mount_path=""
  tui_input mount_path "Mount path for ${CY}${dev}${R}:" "/hdd"
  MOUNT_PATHS["$dev"]="$mount_path"
done

# ── Phase 6: Disk Formatting ──
phase_header "6" "Disk Formatting"

echo -e "  ${YE}${BOLD}WARNING:${R} All data on ${CY}${BOLD}${PRIMARY_DEV}${R} will be destroyed."
echo ""
read -r -s -p "  Press Enter to confirm and begin formatting..." _
echo ""

log "Partitioning ${PRIMARY_DEV}..."
if _capt "parted ${PRIMARY_DEV}" sudo parted -s "$PRIMARY_DEV" -- \
    mklabel gpt \
    mkpart ESP fat32 1MiB 512MiB \
    set 1 esp on \
    mkpart primary ext4 512MiB 100%; then
  ok "Partition table created."
else
  err "Partitioning failed on ${PRIMARY_DEV}."
fi

if [[ "$PRIMARY_DEV" == *nvme* ]] || [[ "$PRIMARY_DEV" == *loop* ]] || [[ "$PRIMARY_DEV" == *mmcblk* ]]; then
  BOOT_PART="${PRIMARY_DEV}p1"
  ROOT_PART="${PRIMARY_DEV}p2"
else
  BOOT_PART="${PRIMARY_DEV}1"
  ROOT_PART="${PRIMARY_DEV}2"
fi

log "Formatting boot partition (FAT32)..."
if _capt "mkfs.fat ${BOOT_PART}" sudo mkfs.fat -F 32 -n BOOT "$BOOT_PART"; then
  ok "Boot: ${BOOT_PART}"
else
  warn "mkfs.fat failed on ${BOOT_PART}"
fi

log "Formatting root partition (ext4)..."
if _capt "mkfs.ext4 ${ROOT_PART}" sudo mkfs.ext4 -L nixos "$ROOT_PART"; then
  ok "Root: ${ROOT_PART}"
else
  warn "mkfs.ext4 failed on ${ROOT_PART}"
fi

log "Mounting root..."
if _capt "mount ${ROOT_PART} /mnt" sudo mount "$ROOT_PART" /mnt; then
  ok "Mounted ${ROOT_PART} → /mnt"
else
  err "Mount failed for ${ROOT_PART}"
fi

sudo mkdir -p /mnt/boot
if _capt "mount ${BOOT_PART} /mnt/boot" sudo mount "$BOOT_PART" /mnt/boot; then
  ok "Mounted ${BOOT_PART} → /mnt/boot"
else
  warn "Boot mount failed for ${BOOT_PART}"
fi

for dev in "${!MOUNT_PATHS[@]}"; do
  mpath="${MOUNT_PATHS[$dev]}"
  log "Formatting extra disk ${dev} (ext4)..."
  if _capt "mkfs.ext4 ${dev}" sudo mkfs.ext4 -L "$(basename "$mpath")" "$dev"; then
    ok "Formatted: ${dev}"
  else
    warn "mkfs.ext4 failed on ${dev}"
  fi
  sudo mkdir -p "/mnt${mpath}"
  if _capt "mount ${dev} → /mnt${mpath}" sudo mount "$dev" "/mnt${mpath}"; then
    ok "Mounted ${dev} → /mnt${mpath}"
  else
    warn "Could not mount ${dev} → /mnt${mpath}"
  fi
done

log "Generating hardware config..."
if _capt "nixos-generate-config --root /mnt" sudo nixos-generate-config --root /mnt; then
  ok "hardware-configuration.nix generated."
else
  warn "nixos-generate-config failed — hardware config may be incomplete"
fi

# ── Phase 7: Writing Configuration ──
phase_header "7" "Writing Configuration"

log "Copying repository to /mnt${DEST}..."
sudo mkdir -p "/mnt${DEST}"
sudo cp -rT "$REPO_ROOT" "/mnt${DEST}"

GENERATED_HW="/mnt/etc/nixos/hardware-configuration.nix"
if [ -f "$GENERATED_HW" ]; then
  sudo cp "$GENERATED_HW" "/mnt${DEST}/hosts/hardware-configuration.nix"
  ok "Copied hardware config to repo."
else
  warn "Could not find generated hardware-configuration.nix at ${GENERATED_HW}"
fi

log "Patching config for user: ${USERNAME}..."
sudo find "/mnt${DEST}" -type f -name "*.nix" -print0 | sudo xargs -0 sed -i "s|hogoshi|${USERNAME}|g"
sudo sed -i "s|initialPassword = \"[^\"]*\"|initialPassword = \"${INIT_PASS}\"|" "/mnt${DEST}/modules/system/users.nix"
sudo sed -i "s|setupMode = false;|setupMode = true;|" "/mnt${DEST}/flake.nix"

if [ "$BROWSER_CHOICE" = "Zen Browser" ]; then
  sudo sed -i "s|useZen = false|useZen = true|" "/mnt${DEST}/flake.nix"
  log "Browser: Zen Browser (useZen = true)"
else
  log "Browser: Firefox (useZen = false)"
fi

if [ -f "/mnt${DEST}/flake.lock" ]; then
  log "Removing flake.lock — sed/username edits change sources; locked self narHash would abort nixos-install."
  sudo rm -f "/mnt${DEST}/flake.lock"
fi
ok "Config patched."

# (Permissions will be set after installation)

# ── Phase 8: Dotfiles & Assets ──
phase_header "8" "Dotfiles & Assets"

log "Patching kb_layout in hyprland.conf..."
sudo sed -i "s|kb_layout = us|kb_layout = ${KB_LAYOUT}|g" "/mnt${DEST}/assets/hyprland.conf"
log "  kb_layout → ${KB_LAYOUT}"

log "Creating symlinks..."
TARGET_ROOT="/mnt"
sudo mkdir -p "/mnt/home/${USERNAME}/.config/hypr"
sudo ln -sf "${DEST}/assets/hyprland.conf" "/mnt/home/${USERNAME}/.config/hypr/hyprland.conf"
log "  linked: hyprland.conf"

sudo mkdir -p "/mnt/home/${USERNAME}/.config/fastfetch"
sudo ln -sf "${DEST}/assets/fastfetch.json" "/mnt/home/${USERNAME}/.config/fastfetch/config.json"
log "  linked: fastfetch.json"

# (Config permissions will be set later)

# ── Phase 9: NixOS Installation ──
phase_header "9" "NixOS Installation"

log "Linking live /etc/nixos → /mnt${DEST} so flake path matches target root..."
if _capt "ln live /etc/nixos → /mnt${DEST}" sudo rm -rf /etc/nixos && sudo ln -sfn "/mnt${DEST}" /etc/nixos; then
  ok "Live /etc/nixos → /mnt${DEST}"
else
  warn "Could not relink live /etc/nixos"
fi

log "Linking target /etc/nixos → /home/${USERNAME}/nixos..."
if _capt "ln target /etc/nixos → /home/${USERNAME}/nixos" sudo rm -rf /mnt/etc/nixos && sudo ln -sfn "/home/${USERNAME}/nixos" /mnt/etc/nixos; then
  ok "Target /etc/nixos → /home/${USERNAME}/nixos"
else
  warn "Could not relink target /etc/nixos"
fi

log "Locking flake..."
if _capt "nix flake lock /mnt${DEST}" sudo nix --extra-experimental-features 'nix-command flakes' flake lock "/mnt${DEST}"; then
  ok "flake.lock written"
else
  warn "nix flake lock failed (network or features missing?)"
fi

log "Running nixos-install..."
echo ""
_init_run_tmp
_nil="$(mktemp "$RUN_TMP/nixinst.XXXXXX")"
set +e
set +o pipefail
sudo nixos-install --no-root-passwd --flake "/mnt${DEST}#nixos" 2>&1 | tee "$_nil"
_nix_ec=${PIPESTATUS[0]}
set -o pipefail
set -e
if [ "$_nix_ec" -eq 0 ]; then
  rm -f "$_nil"
  ok "NixOS installed successfully."
  INSTALL_OK=1

  log "Setting permissions for ${USERNAME}..."
  sudo chown -R 1000:100 "/mnt${DEST}"
  sudo chown -R 1000:100 "/mnt/home/${USERNAME}/.config"
  ok "Permissions set."
else
  err "nixos-install failed — captured output can be reviewed below."
  FAIL_DETAIL_LABELS+=("nixos-install")
  FAIL_DETAIL_FILES+=("$_nil")
fi

# ── Phase 10: Complete ──
phase_header "10" "Complete"

nw=${#WARNINGS[@]}
nc=${#CRITICALS[@]}
nd=${#FAIL_DETAIL_LABELS[@]}

if [ "$nw" -eq 0 ] && [ "$nc" -eq 0 ]; then
  echo -e "  ${GR}${BOLD}All phases completed without errors.${R}"
else
  if [ "$nc" -gt 0 ]; then
    echo -e "  ${RE}${BOLD}Errors (${nc}):${R}"
    for e in "${CRITICALS[@]}"; do echo -e "    ${RE}▸${R} ${e}"; done
    echo ""
  fi
  if [ "$nw" -gt 0 ]; then
    echo -e "  ${YE}${BOLD}Warnings (${nw}):${R}"
    for e in "${WARNINGS[@]}"; do echo -e "    ${YE}▸${R} ${e}"; done
    echo ""
  fi
fi

echo ""
echo -e "  ${BOLD}Summary:${R}"
echo -e "    ${DIM}▸${R} User:     ${CY}${USERNAME}${R}"
echo -e "    ${DIM}▸${R} Config:   ${CY}${DEST}${R}"
echo -e "    ${DIM}▸${R} Keyboard: ${CY}${KB_LAYOUT}${R}"
echo -e "    ${DIM}▸${R} Browser:  ${CY}${BROWSER_CHOICE}${R}"
echo ""

if [ "$INSTALL_OK" -eq 1 ] && [ "$nw" -eq 0 ] && [ "$nc" -eq 0 ]; then
  echo -e "  ${GR}${BOLD}Auto install completed successfully.${R}"
  echo -e "  ${DIM}Rebooting in 5 seconds...${R}"
  for i in {5..1}; do
    echo -e "  ${CY}Rebooting in $i...${R}"
    sleep 1
  done
  sudo reboot
else
  echo -e "  ${YE}${BOLD}Install did not finish cleanly. Reboot is not started.${R}"
  echo -e "  ${DIM}Review errors/warnings below.${R}"
fi
echo ""
if [ "$nw" -gt 0 ] || [ "$nc" -gt 0 ] || [ "$nd" -gt 0 ]; then
  _review_fail_logs
fi
