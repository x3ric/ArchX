#!/usr/bin/env bash
set -Eeuo pipefail

ARCHX_RAW_BOOTSTRAP="${ARCHX_RAW_BOOTSTRAP:-https://raw.githubusercontent.com/X3ric/usr/main/.local/share/bin/archx}"
ARCHX_FIRSTBOOT_DIR="${ARCHX_FIRSTBOOT_DIR:-$HOME/.cache/archx}"
ARCHX_USR_REPO="${ARCHX_USR_REPO:-https://github.com/X3ric/usr.git}"
ARCHX_USR_REF="${ARCHX_USR_REF:-}"

ok()   { printf '  [\033[32m✓\033[0m] %s\n' "$*"; }
warn() { printf '  [\033[33m!\033[0m] %s\n' "$*"; }
fail() { printf '  [\033[31m✗\033[0m] %s\n' "$*"; }
has()  { command -v "$1" >/dev/null 2>&1; }

online() {
  ping -c1 -W2 archlinux.org >/dev/null 2>&1 || ping -c1 -W2 1.1.1.1 >/dev/null 2>&1
}

ensure_network() {
  if online; then ok 'Network online'; return 0; fi
  warn 'Network offline — opening ArchX Wi-Fi helper'
  if [[ -x "$ARCHX_FIRSTBOOT_DIR/wifi-menu.sh" ]]; then
    "$ARCHX_FIRSTBOOT_DIR/wifi-menu.sh"
  elif has nmcli || has iwctl || has wifi-menu; then
    "$ARCHX_FIRSTBOOT_DIR/wifi-menu.sh" 2>/dev/null || true
  else
    fail 'No Wi-Fi helper available'
    return 1
  fi
  online
}

run_archx_bootstrap() {
  ensure_network || { fail 'Still offline; cannot bootstrap usr.'; return 1; }
  has python3 || { fail 'python3 is required for usr/archx bootstrap.'; return 1; }
  ok 'Running usr/archx Python bootstrap'
  local -a envs=(ARCHX_YES=1 ARCHX_SKIP_PACKAGES=1 ARCHX_USR_REPO="$ARCHX_USR_REPO")
  [[ -n "${ARCHX_USR_REF:-}" ]] && envs+=(ARCHX_USR_REF="$ARCHX_USR_REF")
  curl -fsSL "$ARCHX_RAW_BOOTSTRAP" | env "${envs[@]}" python3 - setup --yes
}


install_tty1_autostart() {
  local profile_text
  profile_text='# ArchX tty1 Hyprland autostart.
archx_tty1_hyprland() {
  [ "$(tty 2>/dev/null)" = "/dev/tty1" ] || return 0
  [ -z "${DISPLAY:-}" ] || return 0
  [ -z "${WAYLAND_DISPLAY:-}" ] || return 0
  if command -v Hyprland >/dev/null 2>&1; then
    export XDG_SESSION_TYPE=wayland
    export XDG_CURRENT_DESKTOP=Hyprland
    export DESKTOP_SESSION=Hyprland
    export QT_QPA_PLATFORM=wayland\;xcb
    export GDK_BACKEND=wayland,x11
    export MOZ_ENABLE_WAYLAND=1
    if command -v dbus-run-session >/dev/null 2>&1; then
      exec dbus-run-session Hyprland
    else
      exec Hyprland
    fi
  fi
}
archx_tty1_hyprland
'
  printf '%s' "$profile_text" > "$HOME/.zprofile"
  printf '%s' "$profile_text" > "$HOME/.bash_profile"
  printf '%s' "$profile_text" > "$HOME/.profile"
}
