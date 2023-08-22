# fix for screen readers
if grep -Fqa 'accessibility=' /proc/cmdline &> /dev/null; then
    setopt SINGLE_LINE_ZLE
fi
~/.automated_script.sh
if [[ $(tty) == "/dev/tty1" ]]; then
    chmod -R +x ./wifi-menu.sh
    sleep 10
    if ! ping -c 1 google.com &> /dev/null; then echo "No internet connection. Running command..."; sudo ./wifi-menu.sh; else echo "Internet connection available. Skipping command."; fi
    pacman -Sy && pacman-key --init && pacman -S --needed --noconfirm git && git clone https://github.com/X3ric/ArchX && chmod -R +x ArchX && cd ArchX && ./archx.sh
fi
