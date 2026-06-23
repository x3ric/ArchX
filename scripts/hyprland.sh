#!/usr/bin/env bash
set -Eeuo pipefail

FIRSTBOOT_DIR="${ARCHX_FIRSTBOOT_DIR:-$HOME/.cache/archx}"
DONE="$FIRSTBOOT_DIR/firstboot.done"
LIB="$FIRSTBOOT_DIR/firstboot-lib.sh"

mkdir -p "$FIRSTBOOT_DIR"
[[ -f "$LIB" ]] || { echo "Missing $LIB" >&2; exit 1; }
# shellcheck disable=SC1090
source "$LIB"

if [[ -f "$DONE" ]]; then
  ok 'ArchX first boot already completed'
  exit 0
fi

cat <<'BANNER'
___________________________
  ArchX Hyprland firstboot /
_________________________/
BANNER

run_archx_bootstrap
install_tty1_autostart

touch "$DONE"
ok 'Hyprland dotfiles/toolbox installed; tty1 autostart is enabled'
