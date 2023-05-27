#!/usr/bin/env bash
clear
echo -nE "
   _____                 __       _________        __                  
  /  _  \_______  ____  |  |__   /   _____/____  _|  |_  __ _________  
 /  /_\  \_  __ \/ ___\ |  |  \  \_____  \/ __  \__   _\|  |  \____  \ 
/    |    \|  |\/\  \___|   Y  \ /        \  ___/ |  |  |  |  /|  |_> >
\____|__  /|__|   \___  |___|  //_______  /\___  >|__|  |____/ |   __/ 
        \/            \/     \/         \/     \/              |__|   
                     _____________________________________
                     \  Automated Arch Linux Installer   /
                      \_________________________________/

                    Setting up mirrors for optimal download

"
source $CONFIGS_DIR/setup.conf
timedatectl set-ntp true
pacman -S --noconfirm archlinux-keyring
pacman -S --noconfirm --needed pacman-contrib 
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sed -i 's/^#Color/Color/' /etc/pacman.conf
pacman -S --noconfirm --needed reflector rsync curl grub
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
echo -ne "
_____________________________________________________
                          Installing Prerequisites  /
___________________________________________________/

"
pacman -S --noconfirm --needed gptfdisk btrfs-progs glibc
echo -ne "
________________________________________________
                             Formatting Disk   /
______________________________________________/

"
umount -A --recursive /mnt &>/dev/null
sgdisk -Z ${DISK}
sgdisk -a 2048 -o ${DISK}
sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK}
sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK}
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK}
if [[ ! -d "/sys/firmware/efi" ]]; then
    sgdisk -A 1:set:2 ${DISK}
fi
partprobe ${DISK}
echo -ne "
__________________________________________________
                           Creating Filesystems  /
________________________________________________/

"
createsubvolumes() {
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@tmp
    btrfs subvolume create /mnt/@.snapshots
}
mountallsubvol() {
    mount -o ${MOUNT_OPTIONS},subvol=@home ${partition3} /mnt/home
    mount -o ${MOUNT_OPTIONS},subvol=@tmp ${partition3} /mnt/tmp
    mount -o ${MOUNT_OPTIONS},subvol=@var ${partition3} /mnt/var
    mount -o ${MOUNT_OPTIONS},subvol=@.snapshots ${partition3} /mnt/.snapshots
}
subvolumesetup() {
    createsubvolumes
    umount /mnt
    mount -o ${MOUNT_OPTIONS},subvol=@ ${partition3} /mnt
    mkdir -p /mnt/{home,var,tmp,.snapshots,swap}
    mountallsubvol
}
if [[ "${DISK}" =~ "nvme" ]]; then
    partition2=${DISK}p2
    partition3=${DISK}p3
elif [[ "${DISK}" =~ "mmc" ]]; then
    partition2=${DISK}p2
    partition3=${DISK}p3
else
    partition2=${DISK}2
    partition3=${DISK}3
fi
if [[ "${FS}" == "btrfs" ]]; then
    mkfs.vfat -F32 -n "EFIBOOT" ${partition2}
    mkfs.btrfs -L ROOT ${partition3} -f
    mount -t btrfs ${partition3} /mnt
    subvolumesetup
elif [[ "${FS}" == "ext4" ]]; then
    mkfs.vfat -F32 -n "EFIBOOT" ${partition2}
    mkfs.ext4 -L ROOT ${partition3}
    mount -t ext4 ${partition3} /mnt
elif [[ "${FS}" == "luks" ]]; then
    mkfs.vfat -F32 -n "EFIBOOT" ${partition2}
    echo -ne "${LUKS_PASSWORD}" | cryptsetup -y -v luksFormat ${partition3} -
    echo -ne "${LUKS_PASSWORD}" | cryptsetup open ${partition3} ROOT -
    mkfs.btrfs -L ROOT ${partition3}
    mount -t btrfs ${partition3} /mnt
    subvolumesetup
    echo ENCRYPTED_PARTITION_UUID=$(blkid -s UUID -o value ${partition3}) >> $CONFIGS_DIR/setup.conf
fi
mkdir -p /mnt/boot/efi
mount -t vfat -L EFIBOOT /mnt/boot/
if ! grep -qs '/mnt' /proc/mounts; then
    echo "Drive is not mounted, cannot continue."
    echo "Rebooting in 3 seconds..." && sleep 1
    echo "Rebooting in 2 seconds..." && sleep 1
    echo "Rebooting in 1 second..." && sleep 1
    reboot now
fi
echo -ne "
_________________________________________________________
                           Arch Install on Main Drive   /
_______________________________________________________/

"
pacstrap /mnt base base-devel linux linux-firmware sudo archlinux-keyring wget libnewt --noconfirm --needed
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
cp -R ${SCRIPT_DIR} /mnt/root/ArchX
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
genfstab -L /mnt >> /mnt/etc/fstab
echo " 
  Generated /etc/fstab:
"
cat /mnt/etc/fstab
echo -ne "
_____________________________________________________________
                       GRUB BIOS Bootloader Install & Check /
___________________________________________________________/

"
if [[ ! -d "/sys/firmware/efi" ]]; then
    grub-install --boot-directory=/mnt/boot ${DISK}
else
    pacstrap /mnt efibootmgr --noconfirm --needed
fi
echo -ne "
_____________________________________________________________
                       Checking for low memory systems <8G  /
___________________________________________________________/

"
TOTAL_MEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTAL_MEM -lt 8000000 ]]; then
    mkdir -p /mnt/opt/swap
    chattr +C /mnt/opt/swap
    dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
    chmod 600 /mnt/opt/swap/swapfile # set permissions.
    chown root /mnt/opt/swap/swapfile
    mkswap /mnt/opt/swap/swapfile
    swapon /mnt/opt/swap/swapfile
    echo "/opt/swap/swapfile	none	swap	sw	0	0" >> /mnt/etc/fstab
fi
echo -ne "
_____________________________________________________________
                          SYSTEM READY FOR 1-setup.sh       /
___________________________________________________________/

"
