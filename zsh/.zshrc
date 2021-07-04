# init completion (must be before ztupide is sourced to enable its completions)
autoload -U compinit && compinit

## PLUGINS

[ -f ~/.zsh/ztupide/ztupide.zsh ] || git -C ~/.zsh clone https://github.com/mpostaire/ztupide
ZTUPIDE_AUTOUPDATE=604800 # 7 days
source ~/.zsh/ztupide/ztupide.zsh

# Colored man pages (needs colors and format tweaking)
ztupide load --async zsh-colored-man-pages

# Colored ls (and set auto ls when cd with chpwd in callback to ensure the auto ls is also colored)
ztupide load --async zsh-colored-ls 'chpwd() { ls }'

# Auto-close and delete matching delimiters in zsh (fork of hlissner/zsh-autopair that handles backward-kill-word)
ztupide load --async mpostaire/zsh-autopair

# Try this plugin when it is less buggy (may be incompatible with fzf-tab plugin)
# ztupide load --async marlonrichert/zsh-autocomplete

# Syntax-highlighting for Zshell (should be before zsh-autosuggestions)
ztupide load --async zdharma/fast-syntax-highlighting

# fish-like autosuggestions
ZSH_AUTOSUGGEST_USE_ASYNC=1
# we call _zsh_autosuggest_start function after the plugin is loaded (it is needed if loading in async mode).
ztupide load --async zsh-users/zsh-autosuggestions _zsh_autosuggest_start

# fzf integration
if command -v fzf > /dev/null; then
    export FZF_CTRL_R_OPTS='--reverse' # put history search prompt on top

    if [[ -a /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
        # Debian installation
        source /usr/share/doc/fzf/examples/key-bindings.zsh
        source /usr/share/doc/fzf/examples/completion.zsh
    else
        # Arch Installation
        source /usr/share/fzf/key-bindings.zsh
        source /usr/share/fzf/completion.zsh
    fi

    # set list-colors to enable filename colorizing
    zstyle -e ':completion:*' list-colors 'reply=(${(s[:])LS_COLORS})'
    # preview directory's content when completing cd
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 --color=always $realpath'
    
    # Replace zsh's default completion selection menu with fzf!
    ztupide load --async Aloxaf/fzf-tab
else
    bindkey "^R" history-incremental-pattern-search-backward
fi

# Prompt (can be async only if it support it or else first prompt may not correctly show up)
ztupide load prompt

## MODULES

# Enables completion list-colors
zmodload zsh/complist

# Allows the use of terminfo array for keybindings
zmodload -i zsh/terminfo

## COMPLETION

# Enable tab completion menu-based
zstyle ':completion:*' menu select
# Default colors for listings.
zstyle ':completion:*:default' list-colors "${(s.:.)LS_COLORS}"
# Speed up completions
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
# Completion cache is rebuilt each time we invoke completion
# (no need to start new zsh when installing new packages for example)
# This may make the upper 2 lines useless
zstyle ":completion:*:commands" rehash true

## BINDINGS

# backward-kill-word stops at slashes
WORDCHARS=${WORDCHARS/\/}
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
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
HISTFILE=~/.zhistory
SAVEHIST=1000
HISTSIZE=1000

# .. # -> go # directories up
..() {
  [[ ${1:-1} =~ '^[0-9]+$' ]] \
    && cd $( printf '../'%.0s {1..${1:-1}} ) \
    || return 1
}

# resets terminal if a command messes it up
fix() {
    reset;
    stty sane;
    tput rs1;
    clear;
    echo -e "\e[0m";
}

# download audio from youtube
audio-dl() { youtube-dl -x --audio-format 'm4a' --audio-quality 0 --embed-thumbnail --add-metadata --output '%(title)s.%(ext)s' $@ }

alias "df=df -h"
alias "cp=cp -i"

# Cycle through history based on characters already typed on the line
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
# Up/Down arrows history search
bindkey "\e[A" up-line-or-beginning-search # "${terminfo[kcuu1]}" is more portable but doesn't work with gnome terminal
bindkey "\e[B" down-line-or-beginning-search # "${terminfo[kcud1]}" is more portable but doesn't work with gnome terminal

# Easy url support (fix globbing in urls)
autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic
