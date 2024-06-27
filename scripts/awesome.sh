#!/bin/bash
if [[ "$EUID" -ne 0 ]]; then
echo -nE "
___________________________
  Awesome post install    /
_________________________/

"
    if ! ping -c 1 google.com &> /dev/null; then echo "No internet connection. Running command..." && sudo ./wifi-menu.sh; else echo "Internet connection available. Skipping command."; fi
    echo "picomx install"
    curl -s https://raw.githubusercontent.com/X3ric/picom/next/install | bash
    echo "ctpvx install"
    curl -s https://raw.githubusercontent.com/X3ric/ctpv/master/install | bash
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
    envycontrol -s nvidia --force-comp --coolbits 32
    fi

    sudo systemctl enable gpm.service
    
    #xset r rate 660 25 #Default one 
    xset r rate 560 25 #Input speed
    
    # Cleanup unnecessary packages
    pacman -Rns --noconfirm $(pacman -Qdtq)
    paccache -r
    
    sysctl --system

    [[ ! -f "/usr/lib/libgtk3-nocsd.so.0" ]] && git clone https://github.com/PCMan/gtk3-nocsd && cd gtk3-nocsd && make && sudo make install && cd .. && rm -rf gtk3-nocsd && sudo cp /usr/local/lib/libgtk3-nocsd.so.0 /usr/lib/libgtk3-nocsd.so.0
    
    cd /home/$choice/.cache
    git clone https://github.com/X3ric/usr
    chmod -R +x /home/$choice/.cache/usr/
    cp -r -a /home/$choice/.cache/usr/. /home/$choice/
    rm -R /home/$choice/README.md
    rm -R /home/$choice/LICENSE
    rm -Rf /home/$choice/.git/
    cd /home/$choice/
    mkdir -p /home/$choice/.icons/default/
    ln -s /home/$choice/.local/share/icons/cz-Hickson-Black/cursors/ /home/$choice/.icons/default/cursors
    curl -s -O https://raw.githubusercontent.com/x3ric/usr/main/.local/share/bin/desktop-hide && chmod +x ./desktop-hide && ./desktop-hide && rm -rf ./desktop-hide 
    chown -R $choice:$choice /home/$choice
    chmod 755 /home/$choice
    rm -R /home/$choice/awesome.sh
    rm -R /home/$choice/wifi-menu.sh
    rm -R /home/$choice/.bash_profile
    rm -R /home/$choice/.bash_logout
    rm -R /home/$choice/.bash_history
    echo "export ZDOTDIR=~/.config/zsh" | sudo tee /etc/zsh/zshenv
    rm -rf ~/.zshenv
    sudo touch /home/$choice/.cache/ttywal
    sudo touch /etc/vconsole.conf
    sudo chmod a+rw /etc/vconsole.conf
    /home/$choice/.local/share/bin/ttywal
    chsh $choice -s /bin/zsh
    reboot
fi
