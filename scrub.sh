#!/bin/sh
# scrub.sh - strip known secrets / machine-specific values from collected
# dotfiles, then scan for anything that still looks like a secret.
# Usage: scrub.sh <dir>     (exits non-zero if the scan finds something)

set -eu
dir="${1:?usage: scrub.sh <dir>}"

# --- known offenders ------------------------------------------------------
# aliasrc: alias that pipes a plaintext password into the clipboard, and
# website sync aliases that name a server
[ -f "$dir/.config/aliasrc" ] &&
	sed -i '/^[[:space:]]*wup=/d; /^[[:space:]]*w[ud]='"'"'rsync /d' "$dir/.config/aliasrc"

# sxhkdrc: binding that copies a GitHub token to the clipboard. Replace the
# command with one that reads it from pass(1) instead.
if [ -f "$dir/.config/sxhkd/sxhkdrc" ]; then
	sed -i 's|echo "gh[pousr]_[A-Za-z0-9]*" *|pass show github/token |' "$dir/.config/sxhkd/sxhkdrc"
fi

# Hardcoded home directory -> portable form. Only rewrite in text files.
grep -rlI '/home/blink' "$dir" 2>/dev/null | while IFS= read -r f; do
	sed -i 's|/home/blink/|$HOME/|g; s|/home/blink\b|$HOME|g' "$f"
done
# ...except these don't expand $HOME, only ~
[ -f "$dir/.config/ncmpcpp/config" ] &&
	sed -i '/^mpd_music_dir/s|\$HOME|~|' "$dir/.config/ncmpcpp/config"
[ -f "$dir/.config/ranger/rc.conf" ] &&
	sed -i '/^map g. cd /s|\$HOME|~|' "$dir/.config/ranger/rc.conf"

# --- scan -----------------------------------------------------------------
pattern='gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9_-]{20,}|(pass(word|wd)?|secret|token|api_?key)[[:space:]]*[=:][[:space:]]*["'"'"'][^"'"'"'$ ]{6,}'
if hits=$(grep -rInE "$pattern" "$dir"); then
	echo "!! scrub.sh: possible secrets left in $dir:" >&2
	echo "$hits" >&2
	exit 1
fi
echo "scrub.sh: no secrets found in $dir"
