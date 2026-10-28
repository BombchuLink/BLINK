#!/bin/bash
# BLINK: BLink's LARBS Is Not Kempt
# Auto-deploys BLink's desktop (dwm, xst, polybar, nvim, dotfiles) on Debian.
#
# Run as root on a fresh Debian 13 (trixie) install:
#   ./blink.sh -u <user> [-p <password>] [-y]
#
#   -u USER      user to set up (created if it doesn't exist)
#   -p PASSWORD  password for a newly created user (or set BLINK_PASS)
#   -r REPO      git URL of the BLINK repo to take dotfiles/progs.csv from
#                (default: the directory this script lives in)
#   -b BRANCH    branch of REPO (default: master)
#   -y           don't ask for confirmation
#   -s           skip the slow source builds (polybar) - for quick tests

set -u

### OPTIONS ###

name=""
pass="${BLINK_PASS:-}"
repo=""
branch="master"
assume_yes=0
skip_slow=0

while getopts "u:p:r:b:ysh" o; do
	case "$o" in
		u) name=$OPTARG ;;
		p) pass=$OPTARG ;;
		r) repo=$OPTARG ;;
		b) branch=$OPTARG ;;
		y) assume_yes=1 ;;
		s) skip_slow=1 ;;
		*) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
	esac
done

### HELPERS ###

log() { printf '\033[1;35m[BLINK]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[BLINK]\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31m[BLINK]\033[0m %s\n' "$*" >&2; exit 1; }

failed=()
fail() { warn "FAILED: $*"; failed+=("$*"); }

export DEBIAN_FRONTEND=noninteractive
apt_get() { apt-get -y -o Dpkg::Options::=--force-confold "$@"; }

# run a command as the target user, in their home
as_user() { sudo -u "$name" -H --preserve-env=TERM -- "$@"; }

### CHECKS ###

[ "$(id -u)" -eq 0 ] || die "Run this as root (su - or sudo)."
[ -f /etc/debian_version ] || die "This script is for Debian."
. /etc/os-release
[ "${VERSION_CODENAME:-}" = "trixie" ] ||
	warn "Built for Debian 13 (trixie); this is '${PRETTY_NAME:-unknown}'. Continuing anyway."

if [ -z "$name" ]; then
	read -rp "Username to set up: " name
fi
echo "$name" | grep -q '^[a-z_][a-z0-9_-]*$' || die "Invalid username: $name"

if ! id "$name" >/dev/null 2>&1 && [ -z "$pass" ]; then
	read -rsp "Password for new user $name: " pass; echo
	read -rsp "Again: " pass2; echo
	[ "$pass" = "$pass2" ] || die "Passwords don't match."
fi

if [ "$assume_yes" -ne 1 ]; then
	echo "This will install BLink's setup for user '$name' and OVERWRITE their dotfiles"
	echo "(existing files are moved to ~/.blink-backup-<date>)."
	read -rp "Continue? [y/N] " ans
	[ "$ans" = y ] || [ "$ans" = Y ] || exit 1
fi

### BASE ###

log "Updating package lists and installing base tools..."
apt_get update || die "apt-get update failed. Check your network/sources.list."
apt_get install sudo ca-certificates curl git gnupg rsync ||
	die "Couldn't install base tools."

# Get dotfiles + progs.csv
here="$(cd "$(dirname "$0")" && pwd)"
if [ -n "$repo" ]; then
	src="$(mktemp -d)"
	log "Cloning $repo ($branch)..."
	git clone --depth 1 -b "$branch" "$repo" "$src" || die "Couldn't clone $repo"
else
	src="$here"
fi
[ -d "$src/dotfiles" ] && [ -f "$src/progs.csv" ] ||
	die "No dotfiles/ and progs.csv in $src"

### USER ###

if id "$name" >/dev/null 2>&1; then
	log "Using existing user $name."
else
	log "Creating user $name..."
	useradd -m -s /bin/zsh -G sudo "$name" 2>/dev/null ||
		useradd -m -G sudo "$name" || die "Couldn't create user $name"
	echo "$name:$pass" | chpasswd
fi
unset pass pass2
usermod -aG sudo,audio,video,input "$name"
home="$(getent passwd "$name" | cut -d: -f6)"
srcdir="$home/repos"
as_user mkdir -p "$srcdir"

# Passwordless sudo just for the duration of the install (removed at the end)
trap 'rm -f /etc/sudoers.d/blink-temp' EXIT
echo "$name ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/blink-temp
chmod 440 /etc/sudoers.d/blink-temp

### INSTALLERS ###

# clone (or update) a repo into ~/repos as the user; prints the dir
fetch() { # $1 = url, $2 = optional extra git clone args
	local dir="$srcdir/$(basename "$1" .git)"
	if [ -d "$dir/.git" ]; then
		as_user git -C "$dir" pull --ff-only -q >&2
	else
		as_user git clone -q --depth 1 ${2:-} "$1" "$dir" >&2
	fi || return 1
	echo "$dir"
}

gitmake() { # $1 = url
	local dir
	dir="$(fetch "$1")" || return 1
	# no `make clean`: suckless-style clean targets may delete a tracked config.h
	as_user make -C "$dir" -j"$(nproc)" && make -C "$dir" install
}

install_droidsansmono() {
	local d=/usr/local/share/fonts/powerline
	mkdir -p "$d"
	curl -fsSL -o "$d/Droid Sans Mono for Powerline.otf" \
		"https://github.com/powerline/fonts/raw/master/DroidSansMono/Droid%20Sans%20Mono%20for%20Powerline.otf" &&
		fc-cache -f >/dev/null
}

install_fontawesome() {
	local v=6.7.2 tmp
	tmp="$(mktemp -d)"
	curl -fsSL -o "$tmp/fa.zip" \
		"https://github.com/FortAwesome/Font-Awesome/releases/download/$v/fontawesome-free-$v-desktop.zip" &&
		unzip -o -q -j "$tmp/fa.zip" "*/otfs/*.otf" -d /usr/local/share/fonts/fontawesome6 &&
		fc-cache -f >/dev/null
	local rc=$?
	rm -rf "$tmp"
	return $rc
}

install_neovim() {
	local arch
	case "$(uname -m)" in
		x86_64) arch=x86_64 ;;
		aarch64) arch=arm64 ;;
		*) return 1 ;;
	esac
	curl -fsSL "https://github.com/neovim/neovim/releases/download/stable/nvim-linux-$arch.tar.gz" |
		tar -xz -C /opt || return 1
	rm -rf /opt/nvim && mv "/opt/nvim-linux-$arch" /opt/nvim &&
		ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
}

install_xkslags() {
	local dir
	dir="$(fetch https://github.com/BombchuLink/xkslags.git)" || return 1
	as_user make -C "$dir" &&
		install -Dm755 "$dir/xkslags" /usr/local/bin/xkslags &&
		install -Dm644 "$dir/xkslags.1" /usr/local/share/man/man1/xkslags.1
}

install_polybar() {
	if [ "$skip_slow" -eq 1 ]; then warn "Skipping polybar (-s)."; return 0; fi
	apt_get install libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev \
		libxcb-composite0-dev python3-xcbgen xcb-proto libxcb-image0-dev \
		libxcb-ewmh-dev libxcb-icccm4-dev libxcb-xkb-dev libxcb-xrm-dev \
		libxcb-cursor-dev libasound2-dev libpulse-dev libjsoncpp-dev \
		libmpdclient-dev libuv1-dev libnl-genl-3-dev libcurl4-openssl-dev || return 1
	local dir
	dir="$(fetch https://github.com/pgrondek/polybar-dwm.git --recursive)" || return 1
	as_user cmake -S "$dir" -B "$dir/build" -DCMAKE_BUILD_TYPE=Release \
		-DBUILD_DOC=OFF -DBUILD_TESTS=OFF -DENABLE_I3=OFF &&
		as_user cmake --build "$dir/build" -j"$(nproc)" &&
		cmake --install "$dir/build"
}

install_nannybot() {
	# NannyBot insists on living in ~/.config/nannybot
	local dir="$home/.config/nannybot"
	if [ -d "$dir/.git" ]; then
		as_user git -C "$dir" pull --ff-only -q
	else
		as_user mkdir -p "$home/.config" &&
			as_user git clone -q --depth 1 https://github.com/BombchuLink/NannyBot.git "$dir"
	fi
}

install_jellyfin-tui() {
	[ "$(uname -m)" = x86_64 ] || return 1
	local tmp b=https://github.com/dhonus/jellyfin-tui/releases/latest/download
	tmp="$(mktemp -d)"
	(cd "$tmp" &&
		curl -fsSLO "$b/jellyfin-tui-linux-x86_64.tar.gz" &&
		curl -fsSLO "$b/jellyfin-tui-linux-x86_64.sha256" &&
		sha256sum -c --quiet jellyfin-tui-linux-x86_64.sha256 &&
		tar -xzf jellyfin-tui-linux-x86_64.tar.gz jellyfin-tui &&
		install -Dm755 jellyfin-tui /usr/local/bin/jellyfin-tui)
	local rc=$?
	rm -rf "$tmp"
	return $rc
}

install_discord() {
	local tmp
	tmp="$(mktemp -d)"
	curl -fsSL -o "$tmp/discord.deb" "https://discord.com/api/download?platform=linux&format=deb" &&
		chmod 644 "$tmp/discord.deb" && chmod 755 "$tmp" && # apt's _apt user must read it
		apt_get install "$tmp/discord.deb"
	local rc=$?
	rm -rf "$tmp"
	return $rc
}

install_brave() {
	curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
		https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg || return 1
	echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" \
		>/etc/apt/sources.list.d/brave-browser-release.list
	apt_get update && apt_get install brave-browser &&
		ln -sf /usr/bin/brave-browser /usr/local/bin/brave # dwm & $BROWSER call it "brave"
}

### PACKAGES ###

progs="$(sed '/^#/d;/^[[:space:]]*$/d' "$src/progs.csv")"

log "Installing apt packages..."
mapfile -t aptpkgs < <(echo "$progs" | awk -F, '$1 == "" {print $2}')
if ! apt_get install "${aptpkgs[@]}"; then
	warn "Batch install failed, retrying packages one by one to find the culprit(s)..."
	for p in "${aptpkgs[@]}"; do
		apt_get install "$p" >/dev/null 2>&1 || fail "apt: $p"
	done
fi

total=$(echo "$progs" | grep -vc '^,')
n=0
# (read from fd 3 so nothing run inside the loop can eat the list from stdin)
while IFS=, read -r -u 3 tag prog comment; do
	[ -z "$tag" ] && continue
	n=$((n + 1))
	comment="${comment//\"/}"
	log "[$n/$total] $(basename "$prog" .git) $comment"
	case "$tag" in
		G) gitmake "$prog" || fail "git: $prog" ;;
		F) "install_$prog" || fail "$prog" ;;
		*) fail "unknown tag '$tag' for $prog" ;;
	esac
done 3<<<"$progs"

# `make install`/`cmake --install` run as root and can leave root-owned files
# (xst's install target even rebuilds the binary), so hand ~/repos back
chown -R "$name:$(id -gn "$name")" "$srcdir"

### DOTFILES ###

log "Deploying dotfiles to $home (backups in ~/.blink-backup-*)..."
backup="$home/.blink-backup-$(date +%Y%m%d-%H%M%S)"
rsync -a --backup --backup-dir="$backup" --chown="$name:$(id -gn "$name")" \
	"$src/dotfiles/" "$home/" || fail "deploying dotfiles"
if [ -d "$backup" ]; then
	chown -R "$name:$(id -gn "$name")" "$backup" # rsync creates it as root
	log "Previous versions of overwritten files are in $backup"
fi
as_user mkdir -p "$home/.cache/zsh" "$home/screenshots"


### SYSTEM TWEAKS ###

log "Applying system tweaks..."
chsh -s /bin/zsh "$name" >/dev/null 2>&1 || fail "chsh to zsh"

# Debian ships nsxiv; BLink's scripts call sxiv
if ! command -v sxiv >/dev/null && command -v nsxiv >/dev/null; then
	ln -sf "$(command -v nsxiv)" /usr/local/bin/sxiv
	[ -e "$home/.config/nsxiv" ] || as_user ln -s sxiv "$home/.config/nsxiv"
fi
# Debian names fd's binary fdfind
command -v fd >/dev/null || ln -sf "$(command -v fdfind)" /usr/local/bin/fd 2>/dev/null

# Debian's redshift AppArmor profile only allows ~/.config/redshift.conf
if [ -f /etc/apparmor.d/usr.bin.redshift ]; then
	echo 'owner @{HOME}/.config/redshift/redshift.conf r,' >/etc/apparmor.d/local/usr.bin.redshift
	apparmor_parser -r /etc/apparmor.d/usr.bin.redshift 2>/dev/null || fail "redshift apparmor rule"
fi

# No beeping
rmmod pcspkr 2>/dev/null
echo "blacklist pcspkr" >/etc/modprobe.d/nobeep.conf

# Commands the dotfiles run through `sudo -n` / hotkeys without a password
cat >/etc/sudoers.d/blink-cmds <<EOF
%sudo ALL=(ALL:ALL) NOPASSWD: /usr/sbin/shutdown,/usr/sbin/reboot,/usr/bin/mount,/usr/bin/umount,/usr/bin/loadkeys,/usr/bin/nmtui
EOF
chmod 440 /etc/sudoers.d/blink-cmds
visudo -cq || { rm -f /etc/sudoers.d/blink-cmds; fail "sudoers rule"; }

### NEOVIM PLUGINS ###

if command -v nvim >/dev/null; then
	log "Installing neovim plugins (lazy.nvim restore + coc extensions)..."
	as_user timeout 600 nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 ||
		fail "neovim plugin install"
	if command -v node >/dev/null; then
		as_user timeout 600 nvim --headless "+CocInstall -sync coc-json coc-git coc-clangd" +qa >/dev/null 2>&1 ||
			fail "coc extensions"
	fi
fi

### DONE ###

echo
if [ "${#failed[@]}" -eq 0 ]; then
	log "All done! Log in as $name on tty1 and X will start automatically."
else
	warn "Finished, but these steps failed:"
	printf '   - %s\n' "${failed[@]}" >&2
	warn "Fix them and re-run; the script is safe to run again."
fi
[ "${#failed[@]}" -eq 0 ]
