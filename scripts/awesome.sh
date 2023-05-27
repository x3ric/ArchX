#!/bin/bash
if [[ "$EUID" -ne 0 ]]; then
echo -nE "
___________________________
  Awesome post install    /
_________________________/

"
    if ! ping -c 1 google.com &> /dev/null; then echo "No internet connection. Running command..."; sudo ./wifi-menu.sh; else echo "Internet connection available. Skipping command."; fi
    read -p 'Install picom? y[n]: ' picom
    if [[ $picom == "y" ]]; then
        mkdir -p picomx && cd picomx && curl -s -O https://raw.githubusercontent.com/X3ric/picom/next/PKGBUILD && makepkg -si --noconfirm && cd .. && rm -rf picomx
    fi
    sudo ./awesome.sh
else
echo -nE "
___________________________
  Awesome final install   /
_________________________/  

"
    #sed -i "\$s|^exec.*|exec $wm|" "/etc/X11/xinit/xinitrc" # replace $wm with the wm you want
    echo "Cange password for root to login with su root"
    passwd root
    read -p "What is your user?: " choice

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
    envycontrol -s nvidia --force-comp --coolbits 32
    fi
    
    # Install and enable ufw for a simple firewall
    pacman -S --noconfirm ufw
    systemctl enable --now ufw
    ufw default deny incoming
    ufw default allow outgoing
    
    # Cleanup unnecessary packages
    pacman -Rns --noconfirm $(pacman -Qdtq)
    # Clean package cache
    paccache -r
    
    sysctl --system

    papirus-folders -C black --theme ePapirus-Dark &>/dev/null

    git clone https://github.com/X3ric/usr
    chmod -R +x /home/$choice/usr/
    rm -R /home/$choice/usr/README.md
    rm -R /home/$choice/usr/LICENSE
    rm -Rf /home/$choice/usr/.git/
    cp -r -a /home/$choice/usr/. /home/$choice/
    rm -Rf /home/$choice/usr

    rm /usr/share/applications/nvim.desktop /usr/share/applications/btop.desktop /usr/share/applications/uxterm.desktop /usr/share/applications/xterm.desktop /usr/share/applications/btop.desktop /usr/share/applications/uxterm.desktop /usr/share/applications/xterm.desktop /usr/share/applications/lstopo.desktop /usr/share/applications/cmake-gui.desktop /usr/share/applications/electron.desktop /usr/share/applications/lf.desktop /usr/share/applications/panel-preferences.desktop /usr/share/applications/rofi.desktop /usr/share/applications/rofi-theme-selector.desktop /usr/share/applications/xfce4-about.desktop

    chown -R $choice:$choice /home/$choice
    chmod 755 /home/$choice
    rm -R /home/$choice/awesome.sh
    rm -R /home/$choice/wifi-menu.sh
    rm -R /home/$choice/.bash_profile
    rm -R /home/$choice/.bash_logout
    rm -R /home/$choice/.bash_history
    chsh $choice -s /bin/zsh
    reboot
fi
