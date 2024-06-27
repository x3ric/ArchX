#!/bin/bash

if [[ "$EUID" -ne 0 ]]; then
echo -nE "
___________________________
  Awesome post install    /
_________________________/

"
    if ! ping -c 1 google.com &> /dev/null; then echo "No internet connection. Running command..." && sudo ./wifi-menu.sh; else echo "Internet connection available. Skipping command."; fi
    sudo ./awesome-minimal.sh
else
    # removing uneeded etc "minimal"
    rm -rf /etc/X11/xinit/xinitrc.d/30-gtk3-nocsd.sh
    rm -rf /etc/X11/xinit/xinitrcterm

    echo -e "if [[ ! -z /dev/tty1 ]]; then\n	startx\nfi" > ./.bash_profile

    echo "Cange password for root to login with su root"
    passwd root
    choice=$(logname)
    read -p 'Layout? us,it: ' pos
    localectl set-keymap --no-ask-password $pos
    localectl set-x11-keymap --no-ask-password $pos
    timezone="$(curl -s --fail https://ipapi.co/timezone)"
    timedatectl --no-ask-password set-timezone ${timezone}
    timedatectl --no-ask-password set-ntp 1
    localectl --no-ask-password set-locale LANG="en_US.UTF-8" LC_TIME="en_US.UTF-8"
    #ln -s /usr/share/zoneinfo/${timezone} /etc/localtime
    loadkeys $pos

    read -p 'Is laptop? y[n]: ' lp
    if [[ $lp == "y" ]]; then
    pacman -S --needed --noconfirm sof-firmware tlp acpi acpid
    sed -i -E 's/^#(SOUND_POWER_SAVE_ON_AC=).*/\10/; s/^#(START_CHARGE_THRESH_BAT[01]=).*/\185/; s/^#(STOP_CHARGE_THRESH_BAT[01]=).*/\190/' /etc/tlp.conf
    systemctl enable tlp.service
    fi

    gpu_type=$(lspci)
    if grep -E "NVIDIA|GeForce" <<< ${gpu_type}; then
    yay --noconfirm --needed envycontrol
    envycontrol -s nvidia --force-comp --coolbits 32
    fi

    #xset r rate 660 25 #Default one 
    xset r rate 560 25 #Input speed

    # Cleanup unnecessary packages
    pacman -Rns --noconfirm $(pacman -Qdtq)
    paccache -r

    sysctl --system

    chown -R $choice:$choice /home/$choice
    chmod 755 /home/$choice
    rm -R /home/$choice/awesome-minimal.sh
    rm -R /home/$choice/wifi-menu.sh

    reboot
fi
