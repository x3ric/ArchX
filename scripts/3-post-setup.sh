#!/usr/bin/env bash
clear
echo -ne "
       _________                          __                        
      /   _____/   ____  _______  ___  __|__| _____  ____   ______
      \_____  \   / __ \ \_  __ \ \  \/ /|  |/  ___\/ __ \ /  ___/
      /        \ \  ___/  |  | \/  \   / |  |\  \___\  __/ \___ \ 
     /_______  /  \___  > |__|      \_/  |__| \___  >\___  >/___  >
             \/       \/                          \/     \/     \/ 
                  _____________________________________
                  \  Automated Arch Linux Installer   /
                   \    SCRIPTHOME:     ArchX        /
                    \_______________________________/

                     Final Setup and Configurations
                   GRUB EFI Bootloader Install & Check

"
source ${HOME}/ArchX/configs/setup.conf
if [[ -d "/sys/firmware/efi" ]]; then
    grub-install --efi-directory=/boot ${DISK}
fi
echo -ne "
___________________________________________________________
                      Creating Grub Boot Menu Themed      /
_________________________________________________________/

"
if [[ "${FS}" == "luks" ]]; then
sed -i "s%GRUB_CMDLINE_LINUX_DEFAULT=\"%GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${ENCRYPTED_PARTITION_UUID}:ROOT root=/dev/mapper/ROOT %g" /etc/default/grub
fi
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& os-prober/' /etc/default/grub
sed -i '/^#GRUB_DISABLE_OS_PROBER=/s/^#//' /etc/default/grub
sed -i 's/quiet//g' /etc/default/grub
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/' /etc/default/grub
echo -e "Installing PolyDark Grub theme..."
THEME_DIR="/boot/grub/themes"
THEME_NAME="PolyDark"
echo -e "Creating the theme directory..."
mkdir -p "${THEME_DIR}/${THEME_NAME}"
echo -e "Copying the theme..."
cd ${HOME}/ArchX
cp -a configs${THEME_DIR}/${THEME_NAME}/* ${THEME_DIR}/${THEME_NAME}
echo -e "Backing up Grub config..."
cp -an /etc/default/grub /etc/default/grub.bak
echo -e "Setting the theme as the default..."
grep "GRUB_THEME=" /etc/default/grub 2>&1 >/dev/null && sed -i '/GRUB_THEME=/d' /etc/default/grub
echo "GRUB_THEME=\"${THEME_DIR}/${THEME_NAME}/theme.txt\"" >> /etc/default/grub
echo -e "Updating grub..."
grub-mkconfig -o /boot/grub/grub.cfg
echo -e "All set!"
echo -ne "
______________________________________________________
                      Enabling Essential Services    /
____________________________________________________/

"
systemctl enable cups.service
echo "  Cups enabled"
ntpd -qg
systemctl enable ntpd.service
echo "  NTP enabled"
systemctl enable NetworkManager.service
echo "  NetworkManager enabled"
systemctl enable bluetooth
echo "  Bluetooth enabled"
systemctl enable avahi-daemon.service
echo "  Avahi enabled"

if [[ "${FS}" == "luks" || "${FS}" == "btrfs" ]]; then
echo -ne "
____________________________________________________
                       Creating Snapper Config     /
__________________________________________________/

"
SNAPPER_CONF="$HOME/ArchX/configs/etc/snapper/configs/root"
mkdir -p /etc/snapper/configs/
cp -rfv ${SNAPPER_CONF} /etc/snapper/configs/
SNAPPER_CONF_D="$HOME/ArchX/configs/etc/conf.d/snapper"
mkdir -p /etc/conf.d/
cp -rfv ${SNAPPER_CONF_D} /etc/conf.d/
fi
echo -ne "
____________________________________________________
                        Setting etc configs        /
__________________________________________________/

"
cp -rfv "$HOME/ArchX/configs/etc/samba" /etc/
cp -rfv "$HOME/ArchX/configs/etc/X11" /etc/
cp -rfv "$HOME/ArchX/configs/etc/sysctl.d" /etc/
echo -ne "
________________________________________
                             Cleaning  /
______________________________________/

"
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
rm -r $HOME/ArchX
rm -r /home/$USERNAME/ArchX
rm -r /home/$USERNAME/yay
cd $pwd
