# ArchX scripts

ArchX is now Hyprland-only and split by installation phase:

- `startup.sh` collects disk/user/profile options.
- `0-preinstall.sh` partitions, formats, mounts, pacstraps, and copies ArchX into the target system.
- `1-setup.sh` runs in the chroot as root: base packages, microcode, GPU packages, user creation, hostname.
- `2-user.sh` runs as the installed user: Hyprland packages, AUR packages, and local firstboot assets.
- `3-post-setup.sh` runs as root: bootloader, services, snapper/sysctl/samba, cleanup.
- `wifi-menu.sh` is a local offline-safe Wi-Fi helper used before any network fetch.
- `firstboot-lib.sh` contains shared firstboot helpers.
- `hyprland.sh` is the firstboot script. It verifies network, then runs the `usr` repo `archx` bootstrap.

The contract between repos is simple:

1. `ArchX` installs the OS and Hyprland packages.
2. `usr` installs and updates user dotfiles through:

```sh
curl -fsSL https://raw.githubusercontent.com/X3ric/usr/main/.local/share/bin/archx | python3 - setup --yes
```

Custom user configs are supported by setting `ARCHX_USR_REPO`, `ARCHX_USR_REF`, or `ARCHX_USR_DIR` before firstboot/archx runs.
