## PLUGINS

[ -f ~/.zsh/ztupide/ztupide.zsh ] || git -C ~/.zsh clone https://github.com/mpostaire/ztupide.git
# ZTUPIDE_AUTOUPDATE=604800 # 7 days (disabled because annoying - maybe add background update?)
# ZTUPIDE_DISABLE_ASYNC=1 # disable async plugin loading (enabled by default)
source ~/.zsh/ztupide/ztupide.zsh

# in virtual console, use bold to change fg color to a distinct typing fg color (but still white)
# we do this because vconsole can only use 16 colors using bold on top of the 8 normal colors
# (vconsole don't have a bold font so the only difference will be the color)
if [ $TERM = "linux" ]; then
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=0,bold"
    BREF_GIT_COLOR="%B%F{white}"
    BREF_BATTERY_COLOR="%B%F{yellow}"
else
    _zsh_window_title() {
        echo -ne "\033]0;$(print -Pn -- '%n@%M: %~')\a"
    }
    chpwd_functions+=("_zsh_window_title")
    _zsh_window_title
fi

# Prompt (can be async only if it supports it or else first prompt may not correctly show up, or even crash zsh)
# TODO implement instant prompt
ztupide load mpostaire/bref-zsh-prompt

# Colored ls and manpages (and set auto ls when cd with chpwd in callback to ensure the auto ls is also colored)
ztupide load --async zsh-colored-ls-manpages 'list() { ls }'
chpwd_functions+=("list")

# Auto-close and delete matching delimiters in zsh (fork of hlissner/zsh-autopair that handles backward-kill-word)
ztupide load --async mpostaire/zsh-autopair

# Try this plugin when it is less buggy (may be incompatible with fzf-tab plugin)
# ztupide load --async marlonrichert/zsh-autocomplete

# more completion functions
ztupide load --async zsh-users/zsh-completions

# even more completion functions, then init completion system (must be after all
# the completion functions have been added to fpath)
autoload -Uz compinit
ztupide load --async zsh-more-completions 'compinit'

# TODO for auto-generated completions of commands without them, add the following line
# after compinit (not used because it can cause bad behavior: type 'skinning -' and it will spawn
# the program window each time a new char is added as it calls its --help each time but skinning
# don't have a --help and just spawn its window instead)
# compdef _gnu_generic -default- -P "*"

# fzf integration
if command -v fzf > /dev/null; then
    # fzf-tab personal config and fixes (has to be loaded before fzf-tab)
    ztupide load --async zsh-fzf-config
    # Replace zsh's default completion selection menu with fzf!
    ztupide load --async Aloxaf/fzf-tab

    # Kill all children processes of this zsh process on exit (fix bug of accumulating fzf processes
    # not closed properly after tab completion and fix bug of slow zsh exit).
    # TODO make this better by fixing the bug at the source in fzf-tab plugin if possible.
    # This may cause some scripts to fail when launched from an interactive shell but it's acceptable as
    # I generally don't want children processes surviving after a terminal is closed except for daemons but
    # they won't be affected.
    trap "pkill -P $$" EXIT
else
    echo 'Install the "fzf" package to enable fzf integration.'
    bindkey "^R" history-incremental-pattern-search-backward
fi

# Cycle through history based on characters already typed on the line (should be before fast-syntax-highlighting)
HISTORY_SUBSTRING_SEARCH_PREFIXED=1
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND=
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND=
ztupide load --async zsh-users/zsh-history-substring-search

# Syntax-highlighting for Zshell (should be before zsh-autosuggestions)
ztupide load --async zdharma-continuum/fast-syntax-highlighting 'FAST_HIGHLIGHT_STYLES[defaultprecommand]=fg=green,underline'

# fish-like autosuggestions (it's better to place it after compinit)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# this adds a huge prompt display speedup but may cause problems (see plugin's readme)
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
# we call _zsh_autosuggest_start function after the plugin is loaded (it's needed if
# loading in async mode and if using ZSH_AUTOSUGGEST_USE_ASYNC=1).
ztupide load --async zsh-users/zsh-autosuggestions '_zsh_autosuggest_start'

## MODULES

# Enables completion list-colors
zmodload zsh/complist

# Allows the use of terminfo array for keybindings
zmodload -i zsh/terminfo

# Load the zsh/nearcolor module in terminals that do not support 24bit colors
[[ "$COLORTERM" = (24bit|truecolor) || "${terminfo[colors]}" -eq '16777216' ]] || zmodload zsh/nearcolor

## COMPLETION

# Enable tab completion menu-based
zstyle ':completion:*' menu select
# Colors for ls completion.
zstyle -e ':completion:*' list-colors 'reply=(${(s[:])LS_COLORS})'
# always disable sort when completing (keep the completion output order as is)
zstyle ':completion:*' sort false

# Speed up completions
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
# Completion cache is rebuilt each time we invoke completion
# (no need to start new zsh when installing new packages for example)
# This may make the upper 2 lines useless
zstyle ":completion:*:commands" rehash true

## BINDINGS

# backward-kill-word stops at slashes and equals
WORDCHARS=${WORDCHARS/\/}
WORDCHARS=${WORDCHARS/=}
# Set Ctrl+Backspace to delete previous word
bindkey '^H' backward-kill-word
# Set Ctrl+Delete to delete the next word
bindkey '^[[3;5~' kill-word
# Same as above but for vscode integrated terminal
bindkey '^[d' kill-word
# Set Ctrl+Left to skip previous word
bindkey '^[[1;5D' backward-word
# Set Ctrl+Right to skip the next word
bindkey '^[[1;5C' forward-word
# Set Delete to delete the next char
bindkey "${terminfo[kdch1]}" delete-char
# Set Insert to enable/disable insert mode
bindkey "${terminfo[kich1]}" overwrite-mode
# Set Up/Down arrows substring history search
bindkey '^[[A' history-substring-search-up # "${terminfo[kcuu1]}" is more portable but doesn't work with gnome terminal
bindkey '^[[B' history-substring-search-down # "${terminfo[kcud1]}" is more portable but doesn't work with gnome terminal
# Exit zsh on Ctrl+D even if line is not empty
exit_zsh() { exit }
zle -N exit_zsh
bindkey '^D' exit_zsh
# Enable Shift+Tab to go to previous entry in completion menu
bindkey -M menuselect "${terminfo[kcbt]}" reverse-menu-complete
# Disable Shift+Tab strange behaviour outside completion menu
none() {}
zle -N none
bindkey "${terminfo[kcbt]}" none

## SETTINGS

# Enable spelling correction
#setopt correctall

# Shell history
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
HISTFILE=~/.zhistory
SAVEHIST=1000
HISTSIZE=1000

# Easy url support (fix globbing in urls)
autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic

# This causes problems with intellij integrated terminal
# automatically resets terminal for each new prompt in case a command messes it up
# autoload -Uz add-zsh-hook
# reset_broken_terminal () {
# 	printf '%b' '\e[0m\e(B\e)0\017\e[?5l\e7\e[0;0r\e8'
# }
# add-zsh-hook -Uz precmd reset_broken_terminal

# manually resets terminal if a command really messes it up and the precmd hook wasn't enough
fix() {
    reset
    stty sane
    tput rs1
    clear
    echo -e "\e[0m"
}

## ALIASES

# download audio from youtube
alias "audio-dl=youtube-dl -x --audio-format 'm4a' --audio-quality 0 --embed-thumbnail --add-metadata --output '%(title)s.%(ext)s'"
alias "df=df -h"
alias "cp=cp -i"
alias "bat=bat --theme=TwoDark"
# uninstall unused dependency packages
alias 'rmu=yay -Rcns $(yay -Qtdq)'
