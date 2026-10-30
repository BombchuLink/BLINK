#!/bin/sh
# collect.sh - pull BLink's dotfiles from this machine into ./dotfiles
#
# Reads from $HOME, writes ONLY inside this repo's dotfiles/ directory.
# Re-run it whenever you change configs on the main machine, then review
# `git diff` before committing (it runs the secret scanner at the end).
#
# nvim is NOT collected here: dotfiles/.config/nvim is maintained by hand in
# this repo (it was cleaned up and no longer matches ~/.config/nvim 1:1).

set -euf  # -f: no globbing, the exclude patterns are matched with case

repo="$(cd "$(dirname "$0")" && pwd)"
dest="$repo/dotfiles"
src="$HOME"

# Paths relative to $HOME. Directories are copied recursively.
include='
.xinitrc
.zshenv
.config/aliasrc
.config/xprofile
.config/XResources
.config/Xmodmap
.config/Xassets
.config/zsh/.zshrc
.config/zsh/.zprofile
.config/sxhkd/sxhkdrc
.config/polybar/config
.config/polybar/polybar.sh
.config/polybar/scripts
.config/dunst/dunstrc
.config/picom.conf
.config/redshift
.config/mpd/mpd.conf
.config/ncmpcpp/config
.config/ncmpcpp/bindings
.config/mpv/mpv.conf
.config/mpv/input.conf
.config/mpv/scripts
.config/ranger/rc.conf
.config/ranger/rifle.conf
.config/ranger/scope.sh
.config/ranger/commands.py
.config/zathura/zathurarc
.config/rofi/config.rasi
.config/rofi/dmenu.rasi
.config/gtk-2.0
.config/gtk-3.0/settings.ini
.config/gtk-3.0/gtk.css
.config/gtk-4.0/settings.ini
.config/fontconfig
.config/btop/btop.conf
.config/sxiv
.config/mimeapps.list
.local/share/applications/xranger.desktop
.config/user-dirs.dirs
.config/sfx/Startup.wav
.config/sfx/S1Death.wav
.config/sfx/S1Checkpoint.wav
.config/sfx/TTYD Menu Pullup.wav
.config/wallpaper/wall_Marisa.png
.config/wallpaper/wall_Black.png
'

# Scripts: only ones actually reachable from sxhkd, dwm, xprofile, polybar,
# the shell config/aliases, ranger/sxiv hooks and NannyBot (directly
# or via another listed script). Games (super+G) are left out on purpose.
# Re-derive this list when bindings change instead of copying whole folders.
scripts='
.config/scripts/8MB
.config/scripts/RightMonitorTablet
.config/scripts/audiodevice.in
.config/scripts/char/adv
.config/scripts/char/char
.config/scripts/character
.config/scripts/clipmanager.sh
.config/scripts/keys_held
.config/scripts/killnow
.config/scripts/pls7zip
.config/scripts/plsunzip
.config/scripts/plsunzipall
.config/scripts/plszip
.config/scripts/savememe
.config/scripts/setbg
.config/scripts/togglepolybarmain
.local/bin/calculate.sh
.local/bin/changede
.local/bin/changepaper
.local/bin/displayselect
.local/bin/dmenupass
.local/bin/dmenurecord
.local/bin/ifinstalled
.local/bin/maimpick
.local/bin/pauseallmpv
.local/bin/prompt
.local/bin/remaps
.local/bin/tablet
.local/bin/td-toggle
.local/bin/texclear
.local/bin/tools/dmenupass
.local/bin/torwrap
.local/bin/tutorialvids
'

# Glob patterns (matched against the path relative to $HOME) to never copy:
# pip/easy_install entrypoints, binaries, caches, backups, personal/app-only
# helpers, and anything that only makes sense on this one machine.
exclude='
*/__pycache__*
*.zip
*.orig
*.rej
*~
*_
*_BACKUP_*
*_OLD*
*_old*
.config/scripts/python
.config/scripts/tmp.*
.config/scripts/VPNON
.config/scripts/*.notif
.local/bin/claude
.local/bin/lwp
.local/bin/wal
.local/bin/bandcamp-dl
.local/bin/convert-caffe2-to-onnx
.local/bin/convert-onnx-to-caffe2
.local/bin/cpack
.local/bin/ctest
.local/bin/isympy
.local/bin/m64py
.local/bin/mid3*
.local/bin/moggsplit
.local/bin/mutagen-*
.local/bin/pylupdate5
.local/bin/pyrcc5
.local/bin/pyuic5
.local/bin/scons*
.local/bin/sconsign
.local/bin/tabulate
.local/bin/torchrun
.local/bin/ttrv
.local/bin/unidecode
.local/bin/watchmedo
.local/bin/*python-argcomplete*
.local/bin/futurize
.local/bin/pasteurize
.local/bin/jsonlint
.local/bin/readelf.py
.local/bin/koikatsu*
.local/bin/charastudio
.local/bin/lewdhandler
.local/bin/statusbar/statusbar.zip
.local/bin/statusbar/mode_CURRENT
'

# Files that were cleaned up / made portable inside this repo. They are the
# source of truth now, so collecting must not clobber them; we only warn when
# the copy in $HOME has diverged so you can port the change by hand.
owned='
.xinitrc
.config/xprofile
.config/zsh/.zprofile
.config/zsh/.zshrc
.config/polybar/config
.config/polybar/polybar.sh
'

excluded() {
	for pat in $owned; do
		if [ "$1" = "$pat" ]; then
			cmp -s "$src/$1" "$dest/$1" 2>/dev/null ||
				echo "  repo-owned, NOT copied (differs from \$HOME, merge by hand): $1"
			return 0
		fi
	done
	for pat in $exclude; do
		# shellcheck disable=SC2254
		case "$1" in $pat) return 0 ;; esac
	done
	return 1
}

copy_one() { # $1 = path relative to $HOME (regular file)
	excluded "$1" && return 0
	mkdir -p "$dest/$(dirname "$1")"
	cp -P --preserve=mode,timestamps "$src/$1" "$dest/$1"
}

echo "Collecting from $src into $dest"
IFS='
'
for rel in $include $scripts; do
	if [ -d "$src/$rel" ]; then
		(cd "$src" && find "$rel" \( -type f -o -type l \) -print) | while IFS= read -r f; do
			copy_one "$f"
		done
	elif [ -e "$src/$rel" ]; then
		copy_one "$rel"
	else
		echo "  skip (missing): $rel"
	fi
done

# Machine-specific secrets/values that must never land in the repo.
"$repo/scrub.sh" "$dest"
