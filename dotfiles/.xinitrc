#!/bin/sh

# start some nice programs
export PATH="$HOME/.local/bin:$PATH"

[ -f "$HOME/.config/xprofile" ] && . "$HOME/.config/xprofile"
[ -f "$HOME/.config/Xmodmap" ] && xmodmap "$HOME/.config/Xmodmap"

# dwm restarts itself when killed (super+shift+r / remaps do `pkill dwm`),
# but stop looping once the X server itself is gone
while :; do
	ssh-agent dwm
	xset q >/dev/null 2>&1 || break
done
