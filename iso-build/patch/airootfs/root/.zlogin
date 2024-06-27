# fix for screen readers
if grep -Fqa 'accessibility=' /proc/cmdline &> /dev/null; then
    setopt SINGLE_LINE_ZLE
fi
~/.automated_script.sh
if [[ $(tty) == "/dev/tty1" ]]; then
    chmod +x ./wifi-menu.sh
    echo -e "\nwait 15s for connection scanning\n"
    sleep 15
    if ! ping -c 1 google.com &> /dev/null; then echo "No internet connection. Running wifi-menu..."; sudo ./wifi-menu.sh; else echo "Internet connection available. Skipping wifi-menu."; fi
    pacman -Sy && pacman -S --needed --noconfirm  archlinux-keyring && pacman-key --init && sleep 3
    curl -L -o repository.zip https://github.com/X3ric/ArchX/archive/refs/heads/main.zip && bsdtar -xf repository.zip && mv ./ArchX-main ./ArchX && sudo chmod -R +x ArchX && cd ArchX && ./archx.sh
fi
