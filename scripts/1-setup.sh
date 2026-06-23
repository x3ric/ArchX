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
     _____                    __               __
    /  _  \  _______   ____  |  |__   ______  |  | __   ____   ______
   /  /_\  \ \_  __ \_/ ___\ |  |  \  \____ \ |  |/ /  / ___\ /  ___/
  /    |    \ |  | \/\  \___ |   Y  \ |  |_> >|    <  / /_/  >\___ \
  \____|__  / |__|    \___  >|___|  / |   __/ |__|_ \ \___  //____  >
          \/              \/      \/  |__|         \//_____/      \/
                  _____________________________________
                  \  Automated Arch Linux Installer   /
                   \_______________________________/
BANNER

section 'Network setup'
pacman -S --noconfirm --needed networkmanager iwd rfkill
systemctl enable NetworkManager || true

section 'Locale and pacman setup'
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
printf 'LANG=en_US.UTF-8\nLC_TIME=en_US.UTF-8\n' > /etc/locale.conf
printf 'KEYMAP=%s\n' "${KEYMAP:-us}" > /etc/vconsole.conf
localectl set-keymap "${KEYMAP:-us}" 2>/dev/null || true
localectl set-x11-keymap "${KEYMAP:-us}" 2>/dev/null || true
timedatectl set-timezone "${TIMEZONE:-UTC}" 2>/dev/null || true
timedatectl set-ntp true 2>/dev/null || true
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sed -i 's/^#Color/Color/' /etc/pacman.conf
sed -i "/\[multilib\]/,/Include/ s/^#//" /etc/pacman.conf
pacman -Sy --noconfirm

section 'Build tuning'
nc="$(nproc)"
TOTAL_MEM="$(awk '/MemTotal/{print $2}' /proc/meminfo)"
if (( TOTAL_MEM > 8000000 )); then
  sed -i "s/^#\?MAKEFLAGS=.*/MAKEFLAGS=\"-j$nc\"/" /etc/makepkg.conf || true
  sed -i "s/^COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $nc -z -)/" /etc/makepkg.conf || true
fi

section 'Installing base package list'
minimal=0
[[ "${INSTALL_TYPE:-FULL}" == MINIMAL ]] && minimal=1
install_pkg_list "$SCRIPT_DIR/pkg-files/pacman-pkgs.txt" pacman "$minimal"

section 'Installing microcode'
proc_type="$(lscpu)"
if grep -q 'GenuineIntel' <<< "$proc_type"; then
  pacman -S --noconfirm --needed intel-ucode
elif grep -q 'AuthenticAMD' <<< "$proc_type"; then
  pacman -S --noconfirm --needed amd-ucode
fi

section 'Installing graphics drivers'
gpu_type="$(lspci || true)"
if grep -Eiq 'NVIDIA|GeForce' <<< "$gpu_type"; then
  pacman -S --noconfirm --needed nvidia-dkms nvidia-utils opencl-nvidia vulkan-tools vulkan-icd-loader
elif grep -Eiq 'Radeon|AMD' <<< "$gpu_type"; then
  pacman -S --noconfirm --needed mesa vulkan-radeon libva-mesa-driver mesa-vdpau
elif grep -Eiq 'Intel|UHD|Iris|Integrated Graphics' <<< "$gpu_type"; then
  pacman -S --noconfirm --needed mesa vulkan-intel intel-media-driver libva-utils
fi

section 'Adding user'
groupadd -f libvirt
groupadd -f dialout
groupadd -f kvm
id -u "$USERNAME" >/dev/null 2>&1 || useradd -m -G wheel,kvm,libvirt,power,video,input,dialout -s /bin/bash "$USERNAME"
printf '%s:%s\n' "$USERNAME" "$PASSWORD" | chpasswd
echo "$NAME_OF_MACHINE" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1 localhost
::1       localhost
127.0.1.1 $NAME_OF_MACHINE.localdomain $NAME_OF_MACHINE
EOF
rm -rf "/home/$USERNAME/ArchX"
cp -R "$SCRIPT_DIR" "/home/$USERNAME/ArchX"
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/ArchX"

section 'Sudo bootstrap'
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

if [[ "${FS}" == luks ]]; then
  sed -i 's/filesystems/encrypt filesystems/g' /etc/mkinitcpio.conf
  mkinitcpio -P
fi

ok 'System ready for 2-user.sh'
