<div align="center">

### Installation

Download [ArchIso](https://archlinux.org/download/) and put on a USB drive with [Etcher](https://www.balena.io/etcher/) or [Rufus](https://rufus.ie/en/)

### Boot and in prompt type the following commands

```
loadkeys {KeyLayout} // example it,en,es
pacman -Sy && pacman -S --needed git
git clone https://github.com/X3ric/ArchX
chmod -R +x ArchX
cd ArchX
./archx.sh
```

<details>
<summary><h4>one command</h4></summary>
  
```
pacman -Sy && pacman-key --init && pacman -S --needed --noconfirm git && git clone https://github.com/X3ric/ArchX && chmod -R +x ArchX && cd ArchX && ./archx.sh
```
</details>


<details>
  
<summary><h3>No ethernet?</h3></summary>

### No wifi?

1: Run `iwctl`

2: Run `device list`, and find your device name.

3: Run `station [device name] scan`

4: Run `station [device name] get-networks`

5: Run `station [device name] connect [network name]`, enter your wifi password.

6: Ctrl and C to exit. 

Optional `ping archlinux.org`, and then Press Ctrl and C to stop.

<details>
<summary><h3>Wifi Blocked?</h3></summary>

check if the WiFi is blocked by running `rfkill list`.

If says **Soft blocked: yes**, then run `rfkill unblock wifi`
</details>
</details>
<p align="center">
    <a href="https://archlinux.org"><img alt="Arch Linux" src="https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=D9E0EE&color=000000&labelColor=2AA889"/></a>
</p><br>
