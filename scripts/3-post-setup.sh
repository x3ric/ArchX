#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
CONFIGS_DIR="$SCRIPT_DIR/configs"
export SCRIPT_DIR SCRIPTS_DIR CONFIGS_DIR
# shellcheck disable=SC1091
source "$SCRIPTS_DIR/common.sh"
load_setup

clear
cat <<'BANNER'
       _________                          __
      /   _____/   ____  _______  ___  __|__| _____  ____   ______
      \_____  \   / __ \ \_  __ \ \  \/ /|  |/  ___\/ __ \ /  ___/
      /        \ \  ___/  |  | \/  \   / |  |\  \___\  __/ \___ \
     /_______  /  \___  > |__|      \_/  |__| \___  >\___  >/___  >
             \/       \/                          \/     \/     \/
                  _____________________________________
                  \  Automated Arch Linux Installer   /
                   \_______________________________/
BANNER

section 'Installing GRUB'
if [[ -d /sys/firmware/efi ]]; then
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ArchX
else
  grub-install --target=i386-pc "$DISK"
fi
if [[ "${FS}" == luks ]]; then
  sed -i "s%GRUB_CMDLINE_LINUX_DEFAULT=\"%GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${ENCRYPTED_PARTITION_UUID}:ROOT root=/dev/mapper/ROOT %g" /etc/default/grub
fi
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& os-prober/' /etc/default/grub
sed -i '/^#GRUB_DISABLE_OS_PROBER=/s/^#//' /etc/default/grub
sed -i 's/^\(GRUB_DEFAULT=\).*/\1saved/' /etc/default/grub
sed -i 's/^#\(GRUB_SAVEDEFAULT=\).*/\1true/' /etc/default/grub
sed -i 's/quiet//g' /etc/default/grub
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=3/' /etc/default/grub
THEME_DIR=/boot/grub/themes
THEME_NAME=PolyDark
mkdir -p "$THEME_DIR/$THEME_NAME"
cp -a "$SCRIPT_DIR/configs$THEME_DIR/$THEME_NAME/." "$THEME_DIR/$THEME_NAME/"
cp -an /etc/default/grub /etc/default/grub.bak || true
sed -i '/^GRUB_THEME=/d' /etc/default/grub
echo "GRUB_THEME=\"$THEME_DIR/$THEME_NAME/theme.txt\"" >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

section 'Enabling services'
for svc in NetworkManager.service bluetooth.service avahi-daemon.service ntpd.service; do
  systemctl enable "$svc" 2>/dev/null || warn "Could not enable $svc"
done
systemctl enable cups.service 2>/dev/null || true
ntpd -qg 2>/dev/null || true

if [[ "${FS}" == luks || "${FS}" == btrfs ]]; then
  section 'Installing Snapper config'
  mkdir -p /etc/snapper/configs /etc/conf.d
  cp -rf "$SCRIPT_DIR/configs/etc/snapper/configs/root" /etc/snapper/configs/ 2>/dev/null || true
  cp -rf "$SCRIPT_DIR/configs/etc/conf.d/snapper" /etc/conf.d/ 2>/dev/null || true
fi

section 'Installing /etc configs'
cp -rf "$SCRIPT_DIR/configs/etc/samba" /etc/ 2>/dev/null || true
cp -rf "$SCRIPT_DIR/configs/etc/X11" /etc/ 2>/dev/null || true
cp -rf "$SCRIPT_DIR/configs/etc/sysctl.d" /etc/ 2>/dev/null || true
sysctl --system 2>/dev/null || true

section 'Restoring sudo password requirement'
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

cleanup_chroot_artifacts
ok 'Final setup complete'
