#!/bin/sh
# Launch polybar: bar "main" on the primary monitor, bar "second" on the rest.
# dwm runs this as its altbarcmd.

# kill only this X display's bars (not ones in another X session)
for pid in $(pgrep -u "$(id -u)" -x polybar); do
	tr '\0' '\n' <"/proc/$pid/environ" 2>/dev/null | grep -qx "DISPLAY=$DISPLAY" && kill "$pid"
done

primary=$(xrandr --query | awk '/ connected primary/ {print $1; exit}')
[ -n "$primary" ] || primary=$(xrandr --query | awk '/ connected/ {print $1; exit}')

for m in $(xrandr --query | awk '/ connected/ {print $1}'); do
	if [ "$m" = "$primary" ]; then
		MONITOR=$m polybar main &
	else
		MONITOR=$m polybar second &
	fi
done
