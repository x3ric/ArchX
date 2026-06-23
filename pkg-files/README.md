# Package profiles

ArchX is Hyprland-only now.

- `pacman-pkgs.txt` contains base packages shared by every install.
- `hyprland.txt` contains the Wayland/Hyprland desktop profile.
- `aur-pkgs.txt` contains optional AUR helpers used by the profile.
- `server.txt` is kept for server installs that should skip desktop setup.

Packages before `--END OF MINIMAL INSTALL--` are installed for `MINIMAL`; packages after it are installed only for `FULL`.

To create a custom desktop/profile later, add `<profile>.txt` here and add a matching firstboot script in `scripts/<profile>.sh`. The default supported profile is `hyprland`.
