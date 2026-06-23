#!/usr/bin/env bash
set -Eeuo pipefail

ok()   { printf '  [\033[32m✓\033[0m] %s\n' "$*"; }
warn() { printf '  [\033[33m!\033[0m] %s\n' "$*"; }
fail() { printf '  [\033[31m✗\033[0m] %s\n' "$*"; }
has()  { command -v "$1" >/dev/null 2>&1; }
as_root(){ if [[ ${EUID:-$(id -u)} -eq 0 ]]; then "$@"; elif has sudo; then sudo "$@"; else return 1; fi; }

online() {
  ping -c1 -W2 archlinux.org >/dev/null 2>&1 || ping -c1 -W2 1.1.1.1 >/dev/null 2>&1
}

nmcli_wifi() {
  has nmcli || return 1
  as_root systemctl enable --now NetworkManager >/dev/null 2>&1 || true
  nmcli radio wifi on >/dev/null 2>&1 || true
  nmcli device wifi rescan >/dev/null 2>&1 || true
  warn 'Scanning Wi-Fi with NetworkManager…'
  mapfile -t rows < <(nmcli -t -f SSID,SECURITY device wifi list 2>/dev/null | awk -F: 'length($1){print}' | sort -u)
  ((${#rows[@]})) || return 1
  printf '\n'
  local i row ssid sec n pass=''
  for i in "${!rows[@]}"; do
    ssid="${rows[$i]%%:*}"; sec="${rows[$i]#*:}"
    printf '  %2d) %-32s %s\n' "$((i+1))" "$ssid" "${sec:---}"
  done
  printf '\n  Network number: '
  read -r n
  [[ "$n" =~ ^[0-9]+$ ]] || return 1
  ((n>=1 && n<=${#rows[@]})) || return 1
  row="${rows[$((n-1))]}"; ssid="${row%%:*}"; sec="${row#*:}"
  if [[ -n "$sec" && "$sec" != '--' ]]; then
    read -rs -p "  Password for $ssid: " pass; printf '\n'
    as_root nmcli device wifi connect "$ssid" password "$pass"
  else
    as_root nmcli device wifi connect "$ssid"
  fi
}

iwd_wifi() {
  has iwctl || return 1
  as_root systemctl start iwd >/dev/null 2>&1 || true
  as_root rfkill unblock wifi >/dev/null 2>&1 || true
  warn 'Scanning Wi-Fi with iwd…'
  iwctl device list || true
  printf '  Wi-Fi device (example wlan0): '
  read -r dev
  [[ -n "$dev" ]] || return 1
  iwctl station "$dev" scan || true
  iwctl station "$dev" get-networks || true
  printf '  SSID: '
  read -r ssid
  [[ -n "$ssid" ]] || return 1
  read -rs -p '  Password, empty for open network: ' pass; printf '\n'
  if [[ -n "$pass" ]]; then iwctl --passphrase "$pass" station "$dev" connect "$ssid"; else iwctl station "$dev" connect "$ssid"; fi
}

legacy_wifi_menu() {
  has wifi-menu || return 1
  as_root wifi-menu
}

main() {
  if online; then ok 'Network already online'; exit 0; fi
  as_root rfkill unblock wifi >/dev/null 2>&1 || true
  nmcli_wifi || iwd_wifi || legacy_wifi_menu || {
    fail 'No supported Wi-Fi helper found. Use NetworkManager, iwd, or netctl wifi-menu.'
    exit 1
  }
  online && ok 'Network is online' || { fail 'Still offline'; exit 1; }
}

main "$@"
