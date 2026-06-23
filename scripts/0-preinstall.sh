#!/usr/bin/env bash
set -Eeuo pipefail
# shellcheck disable=SC1091
source "${SCRIPTS_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}/common.sh"
load_setup

clear
cat <<'BANNER'
   _____                 __       _________        __
  /  _  \_______  ____  |  |__   /   _____/____  _|  |_  __ _________
 /  /_\  \_  __ \/ ___\ |  |  \  \_____  \/ __  \__   _\|  |  \____  \
/    |    \|  |\/\  \___|   Y  \ /        \  ___/ |  |  |  |  /|  |_> >
\____|__  /|__|   \___  |___|  //_______  /\___  >|__|  |____/ |   __/
        \/            \/     \/         \/     \/              |__|
                     _____________________________________
                     \  Automated Arch Linux Installer   /
                      \_________________________________/
BANNER

section 'Preparing live environment'
timedatectl set-ntp true || true
loadkeys "${KEYMAP:-us}" 2>/dev/null || true
pacman -Sy --noconfirm --needed archlinux-keyring pacman-contrib reflector rsync curl grub parted networkmanager iwd rfkill gptfdisk btrfs-progs dosfstools cryptsetup glibc
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sed -i 's/^#Color/Color/' /etc/pacman.conf
cp -n /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup 2>/dev/null || true

section 'Formatting disk'
umount -A --recursive /mnt &>/dev/null || true
swapoff -a 2>/dev/null || true
wipefs -af "$DISK" 2>/dev/null || true
sgdisk -Z "$DISK"
sgdisk -a 2048 -o "$DISK"
sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:BIOSBOOT "$DISK"
sgdisk -n 2::+500M --typecode=2:ef00 --change-name=2:EFIBOOT "$DISK"
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:ROOT "$DISK"
[[ -d /sys/firmware/efi ]] || sgdisk -A 1:set:2 "$DISK"
partprobe "$DISK"
udevadm settle 2>/dev/null || true
sleep 2
mapfile -t parts < <(partition_suffixes "$DISK")
partition2="${parts[0]}"
partition3="${parts[1]}"
wait_for_block "$partition2"
wait_for_block "$partition3"

create_btrfs_subvolumes() {
  btrfs subvolume create /mnt/@
  btrfs subvolume create /mnt/@home
  btrfs subvolume create /mnt/@var
  btrfs subvolume create /mnt/@tmp
  btrfs subvolume create /mnt/@.snapshots
}

mount_btrfs_subvolumes() {
  mount -o "${MOUNT_OPTIONS},subvol=@home" "$partition3" /mnt/home
  mount -o "${MOUNT_OPTIONS},subvol=@tmp" "$partition3" /mnt/tmp
  mount -o "${MOUNT_OPTIONS},subvol=@var" "$partition3" /mnt/var
  mount -o "${MOUNT_OPTIONS},subvol=@.snapshots" "$partition3" /mnt/.snapshots
}

setup_btrfs() {
  mount -t btrfs "$partition3" /mnt
  create_btrfs_subvolumes
  umount /mnt
  mount -o "${MOUNT_OPTIONS},subvol=@" "$partition3" /mnt
  mkdir -p /mnt/{home,var,tmp,.snapshots,opt/swap,boot}
  mount_btrfs_subvolumes
}

section 'Creating filesystems'
mkfs.vfat -F32 -n EFIBOOT "$partition2"
case "$FS" in
  btrfs)
    mkfs.btrfs -L ROOT "$partition3" -f
    setup_btrfs
    ;;
  ext4)
    mkfs.ext4 -F -L ROOT "$partition3"
    mount -t ext4 "$partition3" /mnt
    mkdir -p /mnt/boot
    ;;
  luks)
    encrypted_partition="$partition3"
    printf '%s' "$LUKS_PASSWORD" | cryptsetup -q luksFormat "$encrypted_partition" -
    printf '%s' "$LUKS_PASSWORD" | cryptsetup open "$encrypted_partition" ROOT -
    partition3=/dev/mapper/ROOT
    mkfs.btrfs -L ROOT "$partition3" -f
    setup_btrfs
    write_setting ENCRYPTED_PARTITION_UUID "$(blkid -s UUID -o value "$encrypted_partition")"
    ;;
  *) fail "Unknown filesystem: $FS"; exit 1;;
esac
mount "$partition2" /mnt/boot
mountpoint -q /mnt || { fail 'Drive is not mounted; cannot continue.'; exit 1; }
mkdir -p /mnt/etc
printf 'KEYMAP=%s\n' "${KEYMAP:-us}" > /mnt/etc/vconsole.conf

section 'Installing base system'
pacstrap /mnt base base-devel linux linux-firmware linux-headers sudo archlinux-keyring wget libnewt grub os-prober networkmanager iwd rfkill cryptsetup btrfs-progs e2fsprogs dosfstools --noconfirm --needed
cp -R "$SCRIPT_DIR" /mnt/root/ArchX
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
genfstab -L /mnt > /mnt/etc/fstab
cat /mnt/etc/fstab

section 'Bootloader bootstrap'
if [[ -d /sys/firmware/efi ]]; then
  pacstrap /mnt efibootmgr --noconfirm --needed
else
  grub-install --boot-directory=/mnt/boot "$DISK"
fi

section 'Low memory swap check'
TOTAL_MEM="$(awk '/MemTotal/{print $2}' /proc/meminfo)"
if (( TOTAL_MEM < 8000000 )); then
  mkdir -p /mnt/opt/swap
  chattr +C /mnt/opt/swap 2>/dev/null || true
  dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
  chmod 600 /mnt/opt/swap/swapfile
  mkswap /mnt/opt/swap/swapfile
  swapon /mnt/opt/swap/swapfile
  printf '/opt/swap/swapfile none swap sw 0 0\n' >> /mnt/etc/fstab
fi

ok 'Base system ready for 1-setup.sh'
