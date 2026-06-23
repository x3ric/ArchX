#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
CONFIGS_DIR="$SCRIPT_DIR/configs"
export SCRIPT_DIR SCRIPTS_DIR CONFIGS_DIR
# shellcheck disable=SC1091
source "$SCRIPTS_DIR/common.sh"

require_root
require_arch
pacman_unblock_check

pacman -Sy --noconfirm --needed terminus-font
setfont ter-v22b 2>/dev/null || true
clear
cat <<'BANNER'
    _____                    __         _____
   /  _  \  _______  ____   |  |__     /     \  ____     ____   __ __
  /  /_\  \ \_  __ \/ ___\  |  |  \   /  \ /  \/ __ \   /    \ |  |  \
 /    |    \ |  | \/\  \___ |   Y  \ /    Y    \  ___/ |   |  \|  |  /
 \____|__  / |__|    \___  >|___|  / \____|__  /\___  >|___|  /|____/
         \/              \/      \/          \/     \/      \/
                  _____________________________________
                  \  Automated Arch Linux Installer   /
                   \_________________________________/
BANNER

log_run() {
  local name="$1"; shift
  section "$name"
  ( "$@" ) |& tee "$SCRIPT_DIR/${name}.log"
}

log_run startup bash "$SCRIPTS_DIR/startup.sh"
load_setup

log_run 0-preinstall bash "$SCRIPTS_DIR/0-preinstall.sh"
log_run 1-setup arch-chroot /mnt /root/ArchX/scripts/1-setup.sh
if [[ "${DESKTOP_ENV:-hyprland}" != server ]]; then
  log_run 2-user arch-chroot /mnt /root/ArchX/scripts/2-user.sh
fi
log_run 3-post-setup arch-chroot /mnt /root/ArchX/scripts/3-post-setup.sh

mkdir -p "/mnt/home/$USERNAME/.cache/archx/"
cp -v "$SCRIPT_DIR"/*.log "/mnt/home/$USERNAME/.cache/archx/" 2>/dev/null || true

cat <<'BANNER'
               __________ __          __          __
               \_  _____/|__|  ____  |__|  ______|  |__
                |   __)  |  | /    \ |  | /  ___/|  |  \
                |    \   |  ||   |  \|  | \___ \ |   Y  \
                \__  /   |__||___|  /|__|/____  >|___|  /
                   \/             \/          \/      \/
                  _____________________________________
                  \  Automated Arch Linux Installer   /
                   \_________________________________/

              Done — eject install media and run: reboot
BANNER
