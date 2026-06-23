<div align="center">

# ArchX

> Opinionated Arch Linux installer.
> Fast base setup with a firstboot handoff into [`usr`](https://github.com/X3ric/usr).

<p>
  <a href="https://archlinux.org">
    <img alt="Arch Linux" src="https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=D9E0EE&color=000000&labelColor=97A4E2">
  </a>
</p>

<br>

<table align="center">
<tr>
<td align="left">

<pre><code>curl -fsSL https://raw.githubusercontent.com/x3ric/ArchX/main/install | bash</code></pre>

</td>
</tr>
</table>

**Default desktop:** Hyprland

</div>

---

## Install

Boot into an Arch Linux live ISO, make sure you have internet, then run the command above.

You can use the official [Arch ISO](https://archlinux.org/download/) or the prebuilt [ArchX ISO releases](https://github.com/X3ric/ArchX/releases).

ArchX installs the base system, packages, bootloader, and a local firstboot handoff into `usr`.

<details>
<summary><b>Keyboard layout</b></summary>

```sh
loadkeys us
```

Examples:

```sh
loadkeys us
loadkeys it
loadkeys es
```

</details>

<details>
<summary><b>Wi-Fi setup</b></summary>

The installer needs internet for the first `curl`.

Use `iwctl` if Ethernet is unavailable:

```sh
iwctl
device list
station DEVICE scan
station DEVICE get-networks
station DEVICE connect NETWORK
exit
```

Replace `DEVICE` with your Wi-Fi device and `NETWORK` with your network name.

Test the connection:

```sh
ping archlinux.org
```

Press `Ctrl+C` to stop.

If Wi-Fi is blocked:

```sh
rfkill list
rfkill unblock wifi
```

Then repeat the `iwctl` steps.

</details>

---

## First boot

After installation, reboot and log in on `tty1`.

ArchX runs once, checks networking, then bootstraps the user layer from [`usr`](https://github.com/X3ric/usr):

```sh
curl -fsSL https://raw.githubusercontent.com/X3ric/usr/main/.local/share/bin/archx | python3 - setup --yes
```

The `usr` layer handles the desktop setup:

<div align="center">

<table>
<tr>
<td align="center"><b>Hyprland</b></td>
<td align="center"><b>Waybar</b></td>
<td align="center"><b>Rofi</b></td>
<td align="center"><b>Kitty</b></td>
</tr>
<tr>
<td align="center"><b>Dunst</b></td>
<td align="center"><b>Zsh</b></td>
<td align="center"><b>Theming</b></td>
<td align="center"><b>Scripts</b></td>
</tr>
</table>

</div>

<details>
<summary><b>Custom usr repo</b></summary>

Use your own dotfiles repo without editing ArchX:

```sh
export ARCHX_USR_REPO="https://github.com/YOU/usr.git"
export ARCHX_USR_REF="main"

curl -fsSL https://raw.githubusercontent.com/X3ric/usr/main/.local/share/bin/archx | python3 - setup --yes
```

Use a local clone:

```sh
export ARCHX_USR_DIR="$HOME/my-usr"
archx setup --yes
```

</details>

---

## Scope

ArchX is personal and intentionally opinionated.

It is built for quickly reinstalling my Arch + Hyprland setup, not for being a universal installer.

<div align="center">

<table>
<tr>
<td align="center"><b>ArchX</b></td>
<td align="center">Disk setup, base install, packages, bootloader, firstboot</td>
</tr>
<tr>
<td align="center"><b>usr</b></td>
<td align="center">Dotfiles, Hyprland config, tools, theming, post-install polish</td>
</tr>
</table>

<br>

<p>
  <a href="https://archlinux.org">
    <img alt="Arch Linux" src="https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=D9E0EE&color=000000&labelColor=97A4E2">
  </a>
</p>

<img src="https://x3ric.com/imgviews/?text=ArchX" alt="">

</div>
