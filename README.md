<div align="center">

### Installation

Download [Arch.Iso](https://archlinux.org/download/) and create bootable USB and launch or go to [ArchX.iso](https://github.com/X3ric/ArchX/releases/tag/V0.1) instead to skip all steps.

### Boot and in prompt type the following commands

<details>
<summary><h4>set console layout</h4></summary>

<pre>
loadkeys {Layout} // example it,en,es
</pre>

</details>
  
<pre>
curl -s https://raw.githubusercontent.com/x3ric/ArchX/refs/heads/main/install | bash
</pre>

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
  <a href="https://archlinux.org"><img alt="Arch Linux" src="https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=D9E0EE&color=000000&labelColor=97A4E2"/></a>
</p><br>

<img src="https://x3ric.com/imgviews/?text=ArchX" alt="">
