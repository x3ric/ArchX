# ArchX tty1 firstboot + Hyprland autostart.
# Installed by ArchX. Firstboot rewrites this hook after usr dotfiles apply,
# so tty1 keeps autostarting Hyprland even if the login shell changes.

archx_tty1_hyprland() {
  [ "$(tty 2>/dev/null)" = "/dev/tty1" ] || return 0
  [ -z "${DISPLAY:-}" ] || return 0
  [ -z "${WAYLAND_DISPLAY:-}" ] || return 0

  firstboot="$HOME/.cache/archx/firstboot.sh"
  donefile="$HOME/.cache/archx/firstboot.done"
  log="$HOME/.cache/archx/firstboot.log"

  mkdir -p "$HOME/.cache/archx" 2>/dev/null || true

  if [ -x "$firstboot" ] && [ ! -f "$donefile" ]; then
    echo ":: ArchX firstboot starting; log: $log"
    "$firstboot" > "$log" 2>&1
    rc=$?
    cat "$log"
    if [ "$rc" != 0 ]; then
      echo ":: ArchX firstboot failed. Check: $log"
      return "$rc"
    fi
  fi

  if command -v Hyprland >/dev/null 2>&1; then
    export XDG_SESSION_TYPE=wayland
    export XDG_CURRENT_DESKTOP=Hyprland
    export DESKTOP_SESSION=Hyprland
    export QT_QPA_PLATFORM=wayland\;xcb
    export GDK_BACKEND=wayland,x11
    export MOZ_ENABLE_WAYLAND=1
    echo ":: Starting Hyprland on tty1"
    if command -v dbus-run-session >/dev/null 2>&1; then
      exec dbus-run-session Hyprland
    else
      exec Hyprland
    fi
  else
    echo ":: Hyprland is not installed or not in PATH."
  fi
}

archx_tty1_hyprland
