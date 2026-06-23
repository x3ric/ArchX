#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
CONFIGS_DIR="$SCRIPT_DIR/configs"
export SCRIPT_DIR SCRIPTS_DIR CONFIGS_DIR
# shellcheck disable=SC1091
source "$SCRIPTS_DIR/common.sh"
require_root
load_setup

clear
cat <<'BANNER'
     _____                    __       ____ ___
    /  _  \  _______   ____  |  |__   |    |   \ ______  ____  _______
   /  /_\  \ \_  __ \_/ ___\ |  |  \  |    |   //  ___/_/ __ \ \_  __ \
  /    |    \ |  | \/\  \___ |   Y  \ |    |  / \___ \ \  ___/  |  | \/
  \____|__  / |__|    \___  >|___|  / |______/ /____  > \___  > |__|
          \/              \/     \/                \/      \/
                  _____________________________________
                  \  Automated Arch Linux Installer   /
                   \        Hyprland user setup       /
                    \_______________________________/
BANNER

USER_HOME="/home/$USERNAME"
USER_ARCHX="$USER_HOME/ArchX"
USER_CACHE="$USER_HOME/.cache/archx"
USER_PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

as_user_cmd() {
  runuser -u "$USERNAME" -- env \
    HOME="$USER_HOME" USER="$USERNAME" LOGNAME="$USERNAME" PATH="$USER_PATH" SHELL=/bin/bash \
    "$@"
}

as_user_bash() {
  runuser -u "$USERNAME" -- env \
    HOME="$USER_HOME" USER="$USERNAME" LOGNAME="$USERNAME" PATH="$USER_PATH" SHELL=/bin/bash \
    bash -lc "$1"
}

install_aur_pkg_list() {
  local file="$1" helper="$2" minimal="${3:-0}" line pkg
  [[ -f "$file" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    pkg="${line%%#*}"
    pkg="$(printf '%s' "$pkg" | awk '{$1=$1;print}')"
    [[ -z "$pkg" ]] && continue
    if [[ "$pkg" == '--END OF MINIMAL INSTALL--' ]]; then
      [[ "$minimal" == 1 ]] && break || continue
    fi
    printf 'INSTALLING AUR: %s\n' "$pkg"
    as_user_cmd "$helper" -S --quiet --noconfirm --needed "$pkg"
  done < "$file"
}

mkdir -p "$USER_HOME" "$USER_CACHE"
touch "$USER_CACHE/zshhistory"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.cache"

minimal=0
[[ "${INSTALL_TYPE:-FULL}" == MINIMAL ]] && minimal=1
profile="${DESKTOP_ENV:-hyprland}"
[[ -f "$SCRIPT_DIR/pkg-files/$profile.txt" ]] || profile=hyprland

section "Installing $profile profile packages"
install_pkg_list "$SCRIPT_DIR/pkg-files/$profile.txt" pacman "$minimal"

section 'Verifying Hyprland runtime commands'
if [[ "$profile" == hyprland ]]; then
  required_cmds=(Hyprland waybar dunst wl-paste cliphist kitty rofi thunar wpctl wireplumber hyprctl jq swaybg notify-send python3)
  missing_cmds=()
  for cmd in "${required_cmds[@]}"; do
    command -v "$cmd" >/dev/null 2>&1 || missing_cmds+=("$cmd")
  done
  if ((${#missing_cmds[@]})); then
    warn "Missing runtime commands after pacman install: ${missing_cmds[*]}"
    warn 'Continuing so AUR/user setup can finish, but Hyprland may not start until these are installed.'
  else
    ok 'Hyprland runtime commands are present'
  fi
fi

AUR_HELPER="${AUR_HELPER:-yay}"
if [[ "${AUR_HELPER,,}" != none ]]; then
  section "Installing AUR helper: $AUR_HELPER"
  if ! command -v "$AUR_HELPER" >/dev/null 2>&1; then
    rm -rf "$USER_HOME/$AUR_HELPER"
    as_user_cmd git clone "https://aur.archlinux.org/$AUR_HELPER.git" "$USER_HOME/$AUR_HELPER"
    as_user_bash "cd '$USER_HOME/$AUR_HELPER' && makepkg --noconfirm -si"
  fi

  section 'Installing AUR package list'
  install_aur_pkg_list "$SCRIPT_DIR/pkg-files/aur-pkgs.txt" "$AUR_HELPER" "$minimal"
fi

section 'Installing local firstboot bridge'
install -Dm755 "$SCRIPT_DIR/scripts/wifi-menu.sh" "$USER_CACHE/wifi-menu.sh"
install -Dm755 "$SCRIPT_DIR/scripts/firstboot-lib.sh" "$USER_CACHE/firstboot-lib.sh"
install -Dm755 "$SCRIPT_DIR/scripts/hyprland.sh" "$USER_CACHE/firstboot.sh"
for profile_file in .bash_profile .zprofile .profile; do
  install -Dm644 "$SCRIPT_DIR/configs/$profile_file" "$USER_HOME/$profile_file"
done
chown -R "$USERNAME:$USERNAME" "$USER_CACHE" "$USER_HOME/.bash_profile" "$USER_HOME/.zprofile" "$USER_HOME/.profile"

# Keep a user-side copy for debugging/log inspection during failed installs.
rm -rf "$USER_ARCHX"
cp -R "$SCRIPT_DIR" "$USER_ARCHX"
chown -R "$USERNAME:$USERNAME" "$USER_ARCHX"

ok 'System ready for 3-post-setup.sh'
