# init completion (must be before ztupide is sourced to enable its completions)
autoload -U compinit && compinit

## PLUGINS

[ -f ~/.zsh/ztupide/ztupide.zsh ] || git -C ~/.zsh clone https://github.com/mpostaire/ztupide
# ZTUPIDE_AUTOUPDATE=604800 # 7 days (disabled because annoying - maybe add background update?)
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
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# this adds a huge prompt display speedup but may cause problems (see plugin's readme)
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
# we call _zsh_autosuggest_start function after the plugin is loaded (it's needed if loading in async mode and if using ZSH_AUTOSUGGEST_USE_ASYNC=1).
ztupide load --async zsh-users/zsh-autosuggestions _zsh_autosuggest_start

# fzf integration
[[ -a ~/.fzf.zsh ]] && source ~/.fzf.zsh
if command -v fzf > /dev/null; then
    local _fzf_preview_files='
# if realpath empty or doesnt exit, it likely is an argument so print it and return
if [[ -z $realpath || ! -e $realpath ]]; then
    print $desc
    return
fi

local type="$(file -biL $realpath)"
local file="$(ls -d1 --color=always $realpath)"
local title separator
if [ -d $realpath ]; then
    title="Directory: $file"
else
    title="File: $file"
fi
# get target if this is a link and append it to title after coloring it using ls
if [ -L $realpath ]; then
    local rsv=$(readlink $realpath)
    local rsv=${realpath:h}/${rsv#$HOME}
    rsv=${rsv:a}
    local rsv_str="${rsv/$HOME/~}"
    rsv=$(ls -d1 --color=always "$rsv")
    local rsv_str="${rsv/$HOME/~}"
    title="$title -> $rsv_str"
fi
printf -v separator "%.0s─" {1..$FZF_PREVIEW_COLUMNS}
print "${title}\n\033[1;90m${separator}\033[0m"

# try previewing directory content
if [[ -d $realpath ]]; then
    local out
    # add hidden files to preview if we are browsing dotfiles
    if [[ "${buffer[-1]}" = "." ]]; then
        out=$(ls -A1 --color=always $realpath)
    else
        out=$(ls -1 --color=always $realpath)
    fi
    # if no output, show message for empty directory
    if [ -z "$out" ]; then
        out="Empty directory"
        printf -v out "\033[37m%*s\033[0m" $(((${#out}+$FZF_PREVIEW_COLUMNS)/2)) "$out"
        printf "%.0s\n" {1..$((($FZF_PREVIEW_LINES/2)-2))}
    fi
    print $out
    return
# try previewing image
elif [[ "${type/\/*/}" = "image" ]]; then
    if command -v chafa > /dev/null; then
        chafa -s ${FZF_PREVIEW_COLUMNS}x$(($FZF_PREVIEW_LINES-2)) $realpath 2> /dev/null
    else
        print "Install the \"chafa\" package to enable image preview."
    fi
    return
# try previewing binary file content
elif [[ "${type/*charset=/}" = "binary" ]]; then
    hexdump -C -n 500 $realpath
    return
# try previewing ascii file content
else
    if command -v bat > /dev/null; then
        bat --theme=TwoDark --color=always --style=numbers,changes --line-range=:500 $realpath
    else
        head --lines=500 $realpath
    fi
fi'

    # ctrl-r keybinding is double toggle-preview to reload preview window contents (not using the reload() action that reevaluate the fzf command)
    export FZF_DEFAULT_OPTS="--info=inline --bind=ctrl-d:abort,ctrl-H:backward-kill-word,ctrl-p:toggle-preview,ctrl-r:toggle-preview+toggle-preview
    --color=hl:underline:italic:green,bg+:bright-black,gutter:black,hl+:underline:italic:green,info:italic:bright-black,border:bright-black,prompt:bright-blue,pointer:red,marker:bright-yellow,spinner:green,header:yellow"
    # TODO: color fzf ctrl+t, ctrl+r (syntax higlighting), alt+c -> ~/.zsh/wip_stuff.zsh contains wip implementations (but very slow)
    export FZF_CTRL_R_OPTS="--cycle --reverse --preview 'print {2..}' --preview-window=hidden,wrap"
    export FZF_ALT_C_OPTS="--cycle --ansi --preview 'export realpath={}; ${_fzf_preview_files}' --preview-window=~2"
    export FZF_CTRL_T_OPTS="--cycle --preview 'export realpath={}; ${_fzf_preview_files}' --preview-window=~2"

    if [[ -a /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
        # Debian installation
        source /usr/share/doc/fzf/examples/key-bindings.zsh
        source /usr/share/doc/fzf/examples/completion.zsh
    elif [[ -a /usr/share/fzf/key-bindings.zsh ]]; then
        # Arch installation
        source /usr/share/fzf/key-bindings.zsh
        source /usr/share/fzf/completion.zsh
    fi

    # show file/directory preview during completion
    # TODO (maybe impossible?): add keybind to toggle show/hide hidden files in directory preview
    zstyle ':fzf-tab:complete:*:*:files' fzf-preview ${_fzf_preview_files}
    zstyle ':fzf-tab:complete:*:*:files' fzf-flags '--preview-window=~2'
    # zstyle ':fzf-tab:complete:*:*:files' fzf-bindings 'ctrl-h:reload(echo ok)'
    # despite its name, this sets the height of fzf-tab menu even without using tmux
    FZF_TMUX_HEIGHT=70%

    # overwrite -ftb-colorize function from fzf-tab to fix symlinks targets not properly colored
    # also overwrites -ftb-fzf function from fzf-tab to allow custom preview window when the completion
    # list are files/directories as well as new variable buffer to get the user input in the zsh (not fzf) prompt
    # TODO: open PR to merge the fix instead of overwriting this
    fpath+=(${ZDOTDIR:-$HOME/.zsh}/functions)
    # Replace zsh's default completion selection menu with fzf!
    ztupide load --async Aloxaf/fzf-tab
else
    echo 'Install the "fzf" package to enable fzf integration.'
    bindkey "^R" history-incremental-pattern-search-backward
fi

# Prompt (can be async only if it support it or else first prompt may not correctly show up)
ztupide load prompt

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

# This causes problems with intellij integrated terminal (and maybe the cause of delayed exit on some cases?)
# automatically resets terminal for each new prompt in case a command messes it up
# autoload -Uz add-zsh-hook
# reset_broken_terminal () {
# 	printf '%b' '\e[0m\e(B\e)0\017\e[?5l\e7\e[0;0r\e8'
# }
# add-zsh-hook -Uz precmd reset_broken_terminal

# manually resets terminal if a command really messes it up and the precmd hook wasn't enough
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
