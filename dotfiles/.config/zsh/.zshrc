# Luke's config for the Zoomer Shell

autoload -U colors && colors
#PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}%b "
PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}%b "
#PS1="%B%{$fg[magenta]%}%~
#>%b "

# Load aliases if existent.
[ -f "$HOME/.config/aliasrc" ] && source "$HOME/.config/aliasrc"

# History in cache dir
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.cache/zsh/history
[ -d ~/.cache/zsh ] || mkdir -p ~/.cache/zsh

export PATH="$HOME/.config/scripts:$PATH"

setopt inc_append_history
setopt share_history

#autocomplete features
autoload -U compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char
export KEYTIMEOUT=1

#open up current command in vim
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line

# Change cursor shape for different vi modes.
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'

  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select

zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init

# Use beam shape cursor on startup.
echo -ne '\e[5 q'
# Use beam shape cursor for each new prompt.
preexec() { echo -ne '\e[5 q' ;}



# Load zsh-syntax-highlighting; should be last.
# (Arch puts them under /usr/share/zsh/plugins, Debian directly in /usr/share)
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
	for dir in /usr/share/zsh/plugins/$plugin /usr/share/$plugin; do
		[ -f "$dir/$plugin.zsh" ] && source "$dir/$plugin.zsh" && break
	done
done
unset plugin dir
