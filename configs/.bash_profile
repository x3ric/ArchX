if [[ "$(tty)" = "/dev/tty1" ]]; then
[ -f $HOME/awesome*.sh ] && sleep 10 && ./awesome*.sh
fi
