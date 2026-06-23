#!/usr/bin/env bash
# Shared helpers for ArchX install scripts.
set -Eeuo pipefail

if [[ -z "${SCRIPT_DIR:-}" ]]; then
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fi
SCRIPTS_DIR="${SCRIPTS_DIR:-$SCRIPT_DIR/scripts}"
CONFIGS_DIR="${CONFIGS_DIR:-$SCRIPT_DIR/configs}"
SETUP_CONF="${SETUP_CONF:-$CONFIGS_DIR/setup.conf}"
export SCRIPT_DIR SCRIPTS_DIR CONFIGS_DIR SETUP_CONF

ok()      { printf '  [\033[32m✓\033[0m] %s\n' "$*"; }
warn()    { printf '  [\033[33m!\033[0m] %s\n' "$*"; }
fail()    { printf '  [\033[31m✗\033[0m] %s\n' "$*"; }
has()     { command -v "$1" >/dev/null 2>&1; }
section() { printf '\n____________________________________________________________\n  %s\n____________________________________________________________\n\n' "$*"; }

as_root() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    "$@"
  elif has sudo; then
    sudo "$@"
  else
    fail "Need root for: $*"
    return 1
  fi
}

require_root() {
  [[ ${EUID:-$(id -u)} -eq 0 ]] || { fail 'Run this as root from the Arch ISO/chroot.'; exit 1; }
}

require_arch() {
  [[ -e /etc/arch-release ]] || { fail 'This must run on Arch Linux / the Arch ISO.'; exit 1; }
}

pacman_unblock_check() {
  [[ ! -f /var/lib/pacman/db.lck ]] || {
    fail 'Pacman is locked: /var/lib/pacman/db.lck'
    warn 'If pacman is not running, remove the lock and retry.'
    exit 1
  }
}

online() {
  ping -c1 -W2 archlinux.org >/dev/null 2>&1 || ping -c1 -W2 1.1.1.1 >/dev/null 2>&1
}

write_setting() {
  local key="$1" value="${2:-}"
  mkdir -p "$(dirname -- "$SETUP_CONF")"
  touch "$SETUP_CONF"
  chmod 600 "$SETUP_CONF" 2>/dev/null || true
  if grep -Eq "^${key}=" "$SETUP_CONF"; then
    sed -i -e "/^${key}=.*/d" "$SETUP_CONF"
  fi
  printf '%s=%q\n' "$key" "$value" >> "$SETUP_CONF"
}

load_setup() {
  [[ -f "$SETUP_CONF" ]] || { fail "Missing setup config: $SETUP_CONF"; exit 1; }
  # shellcheck disable=SC1090
  source "$SETUP_CONF"
}

prompt_default() {
  local prompt="$1" default="$2" value
  read -r -p "$prompt [$default]: " value
  printf '%s' "${value:-$default}"
}

prompt_secret_twice() {
  local p1 p2
  while true; do
    read -rs -p 'Password: ' p1; printf '\n' >&2
    read -rs -p 'Password again: ' p2; printf '\n' >&2
    [[ "$p1" == "$p2" && -n "$p1" ]] && { printf '%s' "$p1"; return 0; }
    fail 'Passwords did not match or were empty. Try again.' >&2
  done
}

choose_one() {
  local title="$1" default="$2" choice i
  shift 2
  local options=("$@")
  printf '\n%s\n' "$title" >&2
  for i in "${!options[@]}"; do
    printf '  %2d) %s\n' "$((i+1))" "${options[$i]}" >&2
  done
  while true; do
    read -r -p "Select [$default]: " choice
    choice="${choice:-$default}"
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
      printf '%s' "${options[$((choice-1))]}"
      return 0
    fi
    for i in "${options[@]}"; do
      [[ "$choice" == "$i" ]] && { printf '%s' "$i"; return 0; }
    done
    fail 'Invalid selection.' >&2
  done
}

partition_suffixes() {
  local disk="$1"
  if [[ "$disk" =~ (nvme|mmcblk) ]]; then
    printf '%s\n%s\n' "${disk}p2" "${disk}p3"
  else
    printf '%s\n%s\n' "${disk}2" "${disk}3"
  fi
}

wait_for_block() {
  local dev="$1" i
  for i in {1..20}; do
    [[ -b "$dev" ]] && return 0
    sleep 0.25
  done
  fail "Block device not found: $dev"
  return 1
}

install_pkg_list() {
  local file="$1" helper="${2:-pacman}" minimal="${3:-0}" line pkg
  local -a pkgs=()
  [[ -f "$file" ]] || return 0

  while IFS= read -r line || [[ -n "$line" ]]; do
    pkg="${line%%#*}"
    pkg="$(printf '%s' "$pkg" | awk '{$1=$1;print}')"
    [[ -z "$pkg" ]] && continue
    if [[ "$pkg" == '--END OF MINIMAL INSTALL--' ]]; then
      [[ "$minimal" == 1 ]] && break || continue
    fi
    pkgs+=("$pkg")
  done < "$file"

  ((${#pkgs[@]})) || return 0

  if [[ "$helper" == pacman ]]; then
    # Install official packages in one transaction.  This prevents pacman from
    # pulling an unwanted provider such as jack2 for an earlier package and then
    # failing later when pipewire-jack is installed.
    if printf '%s\n' "${pkgs[@]}" | grep -qx 'pipewire-jack'; then
      local -a jack_conflicts=()
      pacman -Qq jack2 >/dev/null 2>&1 && jack_conflicts+=(jack2)
      pacman -Qq jack >/dev/null 2>&1 && jack_conflicts+=(jack)
      if ((${#jack_conflicts[@]})); then
        warn "Replacing ${jack_conflicts[*]} with pipewire-jack"
        as_root pacman -Rdd --noconfirm "${jack_conflicts[@]}" || true
      fi
    fi

    printf 'INSTALLING (%d packages): %s\n' "${#pkgs[@]}" "$file"
    printf '  - %s\n' "${pkgs[@]}"
    as_root pacman -S --noconfirm --needed "${pkgs[@]}"
  else
    for pkg in "${pkgs[@]}"; do
      printf 'INSTALLING AUR: %s\n' "$pkg"
      "$helper" -S --quiet --noconfirm --needed "$pkg"
    done
  fi
}

cleanup_chroot_artifacts() {
  rm -rf /root/ArchX 2>/dev/null || true
  [[ -n "${USERNAME:-}" ]] && rm -rf "/home/$USERNAME/ArchX" "/home/$USERNAME/yay" 2>/dev/null || true
}
