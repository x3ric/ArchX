### Scripts Folder

This directory contains scripts needed for installation:

- [`0-preinstall.sh`](0-preinstall.sh): Prepares the disk by clearing existing data and creating the necessary filesystem for the installation process.

- [`1-setup.sh`](1-setup.sh): Installs the Linux kernel and sets up essential configurations like network settings, locale, language, etc.

- [`2-user.sh`](2-user.sh): Installs additional packages required for the chosen desktop environment (`${DESKTOP_ENV}`). It reads package lists from `${DESKTOP_ENV}.txt` and `aur-pkgs.txt` to install standard and AUR (Arch User Repository) packages, respectively.

- [`3-post-setup.sh`](3-post-setup.sh): Handles post-setup tasks, including configuring the GRUB bootloader, enabling essential services, tweaking system files, and performing cleanup operations for a smooth functioning system.

- [`awesome.sh`](awesome.sh): Executes during the first boot of the installed distribution. It applies final touches, patch fixes, or customizations for awesome. 

- [`startup.sh`](startup.sh): Serves as an interactive menu before starting the ArchX installation. Allows users to make initial configuration choices. Once selections are made, the ArchX installation process starts, applying the chosen configurations and settings.

### Make a new  one?

Additionally you can create a new installation choice. Let's say you want to create an option for 
`${name}.sh` (replace `${name}` with the name of your choice, e.g., `awesome.sh`). This script will be placed in the `scripts` directory use `awesome.sh` as a base and uncomment line 22 and replace $wm with your wanted wm to make also change last exec line in the xinitrc
because as default i not use a login manager i prefer tty.

Create a new file named `${name}.txt` (replace `${name}` with the name of your choice, e.g., `awesome.txt`). This file should be located in the `/pkg-files` directory. It will contain a list of essential packages for the minimal installation option and also should add the line `--END OF MINIMAL INSTALL--` to the list of packages. This addition helps distinguish between essential packages for a minimal installation and additional ones for a full desktop environment setup.