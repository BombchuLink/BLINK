BLINK's LARBS is not Kempt (BLINK) is a auto deployment script for debian that installs Bombchu link (aka BLink)'s default setup for linux.

BLINK includes

BLink's  custom daemon.
https://github.com/BombchuLink/NannyBot

BLink's dwm build
https://github.com/BombchuLink/dwm

xkslags
https://github.com/BombchuLink/xkslags

Blink's build of xst
https://github.com/BombchuLink/xst

polybar dwm
https://github.com/pgrondek/polybar-dwm

## Installing

On a fresh Debian 13 (trixie) install, as root:

```sh
apt install git
git clone https://github.com/BombchuLink/BLINK
cd BLINK
./blink.sh -u <user>
```

Then log in as that user on tty1 and X starts automatically (`~/.config/zsh/.zprofile` runs `startx`).

Options: `-p PASS` password for a new user, `-y` no prompts, `-s` skip the slow polybar build, `-r URL -b BRANCH` take dotfiles from another clone. It's safe to re-run; dotfiles it overwrites are moved to `~/.blink-backup-<date>/`.

Per-machine things (monitor layout, tablet) go in `~/.config/xprofile.local`. See `dotfiles/.config/xprofile.local.example`.

## Layout

| path | what |
| --- | --- |
| `blink.sh` | the installer |
| `progs.csv` | everything it installs. Tag blank = apt, `G` = git repo + `make install`, `F` = function `install_<name>` in blink.sh |
| `dotfiles/` | copied straight into `$HOME` |
| `collect.sh` | re-pull configs from the main machine into `dotfiles/` (never writes outside this repo) |
| `scrub.sh` | strips/blocks secrets; `collect.sh` runs it automatically |

`collect.sh` won't overwrite files that were cleaned up in this repo (`.xinitrc`, xprofile, zsh, polybar, all of nvim). It tells you when the copy in `$HOME` differs so you can merge by hand.

## License

[MIT-0](LICENSE): do whatever you want with it, no attribution needed.
The wallpapers and sound effects in `dotfiles/.config/` belong to their original creators and aren't covered by it.
