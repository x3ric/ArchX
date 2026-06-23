#!/usr/bin/env bash
set -Eeuo pipefail
# shellcheck disable=SC1091
source "${SCRIPTS_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}/common.sh"

background_checks() {
  require_root
  require_arch
  pacman_unblock_check
  if awk -F/ '$2 == "docker" {found=1} END{exit !found}' /proc/self/cgroup 2>/dev/null || [[ -f /.dockerenv ]]; then
    fail 'Docker/container installs are not supported.'
    exit 1
  fi
}

logo() {
  clear
  cat <<'BANNER'
                 _____                    __
                /  _  \  _______  ____   |  |___
               /  /_\  \ \_  __ \/ ___\  |  |   \
              /    |    \ |  | \/\  \___ |   Y  /
              \____|__  / |__|    \___  >|___| /
                      \/              \/     \/
________________________________________________________________
                Please select settings for your system         /
______________________________________________________________/
BANNER
}

valid_username() { [[ "$1" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; }
valid_hostname() { [[ "$1" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,62}$ ]]; }

ask_user() {
  local username hostname password
  while true; do
    username="$(prompt_default 'Username' 'x3ric')"
    username="${username,,}"
    valid_username "$username" && break
    fail 'Username must be lowercase letters, numbers, underscore, or dash.'
  done
  password="$(prompt_secret_twice)"
  while true; do
    hostname="$(prompt_default 'Hostname' 'ArchX')"
    valid_hostname "$hostname" && break
    fail 'Invalid hostname.'
  done
  write_setting USERNAME "$username"
  write_setting PASSWORD "$password"
  write_setting NAME_OF_MACHINE "$hostname"
}

ask_profile() {
  local profile install_type aur_helper
  profile="$(choose_one 'Profile' 1 hyprland server)"
  write_setting DESKTOP_ENV "$profile"
  if [[ "$profile" == server ]]; then
    write_setting INSTALL_TYPE MINIMAL
    write_setting AUR_HELPER none
    return 0
  fi
  install_type="$(choose_one 'Install type' 1 FULL MINIMAL)"
  aur_helper="$(choose_one 'AUR helper' 1 yay none)"
  write_setting INSTALL_TYPE "$install_type"
  write_setting AUR_HELPER "$aur_helper"
}

ask_disk() {
  local rows=() line idx choice disk rot opts
  mapfile -t rows < <(lsblk -dno NAME,SIZE,MODEL,TYPE | awk '$NF=="disk"{t=$NF;$NF=""; print "/dev/"$0}' | sed 's/[[:space:]]*$//')
  ((${#rows[@]})) || { fail 'No install disk found.'; exit 1; }
  section 'Disk selection — THIS WILL ERASE THE SELECTED DISK'
  for idx in "${!rows[@]}"; do printf '  %2d) %s\n' "$((idx+1))" "${rows[$idx]}"; done
  while true; do
    read -r -p 'Install disk number: ' choice
    [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#rows[@]} )) && break
    fail 'Invalid disk selection.'
  done
  disk="${rows[$((choice-1))]%% *}"
  cat <<'DELETE_BANNER'
                    __     __          __          
               ____/ /___ |  |   _____|  |_ ____  
              / __  / __ \|  | / __ \_   __/ ___ \ 
             / /_/ /\  __/|  |_\  __/ |  | \  ___/ 
             \__  /  \___ |____/\___  >__|  \___  >
                \/       \/         \/          \/ 
        THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK
       Please make sure you know what you are doing because
    after formatting your disk there is no way to get data back
DELETE_BANNER
  warn "Selected $disk — all data on it will be destroyed."
  read -r -p 'Type YES to continue: ' choice
  [[ "$choice" == YES ]] || { fail 'Cancelled.'; exit 1; }
  write_setting DISK "$disk"
  rot="$(cat "/sys/block/${disk#/dev/}/queue/rotational" 2>/dev/null || echo 0)"
  if [[ "$rot" == 0 ]]; then opts='noatime,compress=zstd,ssd,commit=120'; else opts='noatime,compress=zstd,commit=120'; fi
  write_setting MOUNT_OPTIONS "$opts"
}

ask_filesystem() {
  local fs pass
  fs="$(choose_one 'Filesystem' 1 btrfs ext4 luks)"
  write_setting FS "$fs"
  if [[ "$fs" == luks ]]; then
    warn 'LUKS will encrypt the root Btrfs filesystem.'
    pass="$(prompt_secret_twice)"
    write_setting LUKS_PASSWORD "$pass"
  fi
}

ask_locale() {
  local keymap tz detected
  keymap="$(prompt_default 'Console keymap' 'us')"
  write_setting KEYMAP "$keymap"
  loadkeys "$keymap" 2>/dev/null || true
  detected="$(curl -fsSL https://ipapi.co/timezone 2>/dev/null || true)"
  [[ -n "$detected" ]] || detected='UTC'
  tz="$(prompt_default 'Timezone' "$detected")"
  write_setting TIMEZONE "$tz"
}

background_checks
: > "$SETUP_CONF"
chmod 600 "$SETUP_CONF" 2>/dev/null || true
logo; ask_user
logo; ask_profile
logo; ask_disk
logo; ask_filesystem
logo; ask_locale
ok "Setup saved to $SETUP_CONF"
