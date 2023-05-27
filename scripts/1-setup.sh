#!/usr/bin/env bash
clear
echo -ne "
     _____                    __               __                     
    /  _  \  _______   ____  |  |__   ______  |  | __   ____   ______ 
   /  /_\  \ \_  __ \_/ ___\ |  |  \  \____ \ |  |/ /  / ___\ /  ___/ 
  /    |    \ |  | \/\  \___ |   Y  \ |  |_> >|    <  / /_/  >\___ \  
  \____|__  / |__|    \___  >|___|  / |   __/ |__|_ \ \___  //____  > 
          \/              \/      \/  |__|         \//_____/      \/  
                  _____________________________________
                  \  Automated Arch Linux Installer   /
                   \    SCRIPTHOME:     ArchX        /
                    \_______________________________/

"
source $HOME/ArchX/configs/setup.conf
echo -ne "
________________________________________________
                             Network Setup     /
______________________________________________/

"
pacman -S --noconfirm --needed networkmanager dhclient
systemctl enable --now NetworkManager
echo -ne "
_____________________________________________________________
                  Setting up mirrors for optimal download   /
___________________________________________________________/

"
pacman -S --noconfirm --needed reflector pacman-contrib curl rsync grub arch-install-scripts git
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
nc=$(grep -c ^processor /proc/cpuinfo)
echo -nE " 
_______________________________________________________________
                changing the makeflags cores. Aswell as       /
                   changing the compression settings.        /
____________________________________________________________/
                        You have "$nc" cores. 

"
TOTAL_MEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTAL_MEM -gt 8000000 ]]; then
 sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$nc\"/g" /etc/makepkg.conf
 sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $nc -z -)/g" /etc/makepkg.conf
fi
echo -ne "
___________________________________________________________
                    Setup Language to US and set locale   /
_________________________________________________________/

"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm 
echo -ne "
_____________________________________________________
                          Installing Base System    /
___________________________________________________/

"
sed -n '/'$INSTALL_TYPE'/q;p' $HOME/ArchX/pkg-files/pacman-pkgs.txt | while read line
do
if [[ ${line} == '--END OF MINIMAL INSTALL--' ]]; then
    continue
fi
echo "INSTALLING: ${line}"
sudo pacman -S --noconfirm --needed ${line}
done
echo -ne "
________________________________________________________
                          Installing Microcode         /
______________________________________________________/

"
proc_type=$(lscpu)
if grep -E "GenuineIntel" <<< ${proc_type}; then
    echo "Installing Intel microcode"
    pacman -S --noconfirm --needed intel-ucode
    proc_ucode=intel-ucode.img
elif grep -E "AuthenticAMD" <<< ${proc_type}; then
    echo "Installing AMD microcode"
    pacman -S --noconfirm --needed amd-ucode
    proc_ucode=amd-ucode.img
fi
echo -ne "
_______________________________________________________
                     Installing Graphics Drivers      /
_____________________________________________________/

"
gpu_type=$(lspci)
if grep -E "NVIDIA|GeForce" <<< ${gpu_type}; then
    pacman -S --noconfirm --needed nvidia nvidia-utils xorg-server-devel opencl-nvidia && nvidia-xconfig
elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
    pacman -S --noconfirm --needed xf86-video-amdgpu
elif grep -E "Integrated Graphics Controller" <<< ${gpu_type}; then
    pacman -S --noconfirm --needed libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
elif grep -E "Intel Corporation UHD" <<< ${gpu_type}; then
    pacman -S --needed --noconfirm libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
fi
if ! source $HOME/ArchX/configs/setup.conf; then
	while true
	do 
		read -p "Please enter username:" username
		if [[ "${username,,}" =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ]]
		then 
			break
		fi 
		echo "Incorrect username."
	done 
echo "username=${username,,}" >> ${HOME}/ArchX/configs/setup.conf
    read -p "Please enter password:" password
echo "password=${password,,}" >> ${HOME}/ArchX/configs/setup.conf
    while true
	do 
		read -p "Please name your machine:" name_of_machine
		if [[ "${name_of_machine,,}" =~ ^[a-z][a-z0-9_.-]{0,62}[a-z0-9]$ ]]
		then 
			break 
		fi 
		read -p "Hostname doesn't seem correct. Do you still want to save it? (y/n)" force 
		if [[ "${force,,}" = "y" ]]
		then 
			break 
		fi 
	done 
    echo "NAME_OF_MACHINE=${name_of_machine,,}" >> ${HOME}/ArchX/configs/setup.conf
fi
echo -ne "
_____________________________________________
                             Adding User    /
___________________________________________/

"
if [ $(whoami) = "root"  ]; then
    groupadd libvirt
    useradd -m -G wheel,libvirt,power,video -s /bin/bash $USERNAME 
    echo "$USERNAME created, home directory created, added to wheel and libvirt group, default shell set to /bin/bash"
    echo "$USERNAME:$PASSWORD" | chpasswd
    echo "$USERNAME password set"
	cp -R $HOME/ArchX /home/$USERNAME/
    chown -R $USERNAME: /home/$USERNAME/ArchX
    echo "ArchX copied to home directory"
	echo $NAME_OF_MACHINE > /etc/hostname
else
	echo "You are already a user proceed with aur installs"
fi
if [[ ${FS} == "luks" ]]; then
    sed -i 's/filesystems/encrypt filesystems/g' /etc/mkinitcpio.conf
    mkinitcpio -p linux
fi
echo -ne "
___________________________________________________
                    SYSTEM READY FOR 2-user.sh    /
_________________________________________________/

"
