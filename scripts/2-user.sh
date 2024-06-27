#!/usr/bin/env bash
clear
echo -nE "
     _____                    __       ____ ___                       
    /  _  \  _______   ____  |  |__   |    |   \ ______  ____  _______ 
   /  /_\  \ \_  __ \_/ ___\ |  |  \  |    |   //  ___/_/ __ \ \_  __ \ 
  /    |    \ |  | \/\  \___ |   Y  \ |    |  / \___ \ \  ___/  |  | \/
  \____|__  / |__|    \___  >|___|  / |______/ /____  > \___  > |__|   
          \/              \/      \/                \/      \/       
                  _____________________________________
                  \  Automated Arch Linux Installer   /
                   \    SCRIPTHOME:      ArchX       /
                    \_______________________________/

                        Installing AUR Softwares

"
source $HOME/ArchX/configs/setup.conf
cd ~
mkdir "/home/$USERNAME/.cache"
touch "/home/$USERNAME/.cache/zshhistory"
sed -n '/'$INSTALL_TYPE'/q;p' ~/ArchX/pkg-files/${DESKTOP_ENV}.txt | while read line
do
  if [[ ${line} == '--END OF MINIMAL INSTALL--' ]]; then
    continue
  fi
  if [[ ${line:0:1} == '#' ]]; then
    continue
  fi
  echo "INSTALLING: ${line}"
  sudo pacman -S --noconfirm --needed ${line}
done

if [[ ! $AUR_HELPER == none ]]; then
  cd ~
  git clone "https://aur.archlinux.org/$AUR_HELPER.git"
  cd ~/$AUR_HELPER
  makepkg --noconfirm -si 2>&1 >/dev/null
  sed -n '/'$INSTALL_TYPE'/q;p' ~/ArchX/pkg-files/aur-pkgs.txt | while read line
  do
    if [[ ${line} == '--END OF MINIMAL INSTALL--' ]]; then
      continue
    fi
    if [[ ${line:0:1} == '#' ]]; then
      continue
    fi
    echo "INSTALLING: ${line}"
    $AUR_HELPER -S --quiet --noconfirm --needed ${line}
  done
fi
export PATH=$PATH:~/.local/bin
if [[ $INSTALL_TYPE == "FULL" ]]; then
    curl -s https://raw.githubusercontent.com/X3ric/usr/main/.local/share/bin/wifi-menu -o ~/wifi-menu.sh
    sudo chmod +x ~/wifi-menu.sh
    cp -r ~/ArchX/scripts/${DESKTOP_ENV}.sh ~/
    cp -r ~/ArchX/configs/.bash_profile ~/
else
    curl -s https://raw.githubusercontent.com/X3ric/usr/main/.local/share/bin/wifi-menu -o ~/wifi-menu.sh
    sudo chmod +x ~/wifi-menu.sh
    cp -r ~/ArchX/scripts/${DESKTOP_ENV}-minimal.sh ~/
    cp -r ~/ArchX/configs/.bash_profile ~/
fi
echo -ne "
__________________________________________________________
                    SYSTEM READY FOR 3-post-setup.sh     /
________________________________________________________/

"
exit
