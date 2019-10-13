# Prompt theme 
#              (add support git ? + zsh auto highlight regler couleurs + autres ?)
# setopt more and co

export PATH=$PATH:$HOME"/.local/bin"

## Bindings (cause the first char of the keycode to be slow when typed in terminal)

# Set Ctrl+Backspace to delete previous word
bindkey '^H' backward-kill-word
# Set Ctrl+Delete to delete the next word
bindkey '^[[3;5~' kill-word
# Set Ctrl+Left to skip previous word
bindkey '^[[1;5D' backward-word
# Set Ctrl+Right to skip the next word
bindkey '^[[1;5C' forward-word
# Set Delete to delete the next char
bindkey '^[[3~' delete-char
# Exit zsh on Ctrl+D even if line is not empty
exit_zsh() { exit }
zle -N exit_zsh
bindkey '^D' exit_zsh
# Enable Shift+Tab to go to previous entry in completion menu
zmodload zsh/complist
bindkey -M menuselect '^[[Z' reverse-menu-complete
# Disable Shift+Tab strange behaviour outside completion menu
none() {}
zle -N none
bindkey '^[[Z' none

## SETTINGS

# Enable spelling correction
setopt correctall

# Shell history
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
HISTFILE=~/.zhistory
SAVEHIST=1000
HISTSIZE=1000

# ls colors
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto --group-directories-first'
    # alias dir='dir --color=auto'
    # alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

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

# auto ls when cd (chpwd function is executed each time zsh changes directory)
chpwd() { ls }

# download audio from youtube
audio-dl() { youtube-dl -x --audio-format 'm4a' --audio-quality 0 --embed-thumbnail --add-metadata --output '%(title)s.%(ext)s' $1 }

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

## PLUGINS

# Colored man pages (needs colors and format tweaking)
source ~/.zsh/zsh-colored-man-pages/colored-man-pages.plugin.zsh

# backward-kill stops at slashes
autoload -U select-word-style
select-word-style bash

autoload -U compinit && compinit # init completion

# Cycle through history based on characters already typed on the line
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

# Easy url support (fix globbing in urls)
autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic

# fish-like autosuggestions (a bit slow)
ZSH_AUTOSUGGEST_USE_ASYNC=1
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

## PROMPT

setopt PROMPT_SUBST # Allow variables in prompt
autoload -U colors && colors # Enable colors in prompt

# _ssh_info and _git_info taken and modified from https://joshdick.net/2017/06/08/my_git_prompt_for_zsh_revisited.html
# Echoes a username/host string when connected over SSH (empty otherwise)
# not tested now
_ssh_info() {
    [[ "$SSH_CONNECTION" != '' ]] && echo '%(!.%{$fg[red]%}.%{$fg[yellow]%})%n%{$reset_color%}@%{$fg[green]%}%m%{$reset_color%}:' || echo ''
}

# Echoes information about Git repository status when inside a Git repository
# partially tested
# TODO: edit to my preferences
_git_info() {
    # Exit if not inside a Git repository
    ! git rev-parse --is-inside-work-tree > /dev/null 2>&1 && return

    # Git branch/tag, or name-rev if on detached head
    local GIT_LOCATION=${$(git symbolic-ref -q HEAD || git name-rev --name-only --no-undefined --always HEAD)#(refs/heads/|tags/)}
    local GIT_ICON="±"
    local MAIN_COLOR="15"

    local AHEAD="%F{red}⇡NUM%f"
    local BEHIND="%F{cyan}⇣NUM%f"
    local MERGING="%F{magenta}⚡︎%f"
    local UNTRACKED="%F{red}●%f"
    local MODIFIED="%F{yellow}●%f"
    local STAGED="%F{green}●%f"

    local -a DIVERGENCES
    local -a FLAGS

    local NUM_AHEAD="$(git log --oneline @{u}.. 2> /dev/null | wc -l | tr -d ' ')"
    if [ "$NUM_AHEAD" -gt 0 ]; then
        DIVERGENCES+=( "${AHEAD//NUM/$NUM_AHEAD}" )
    fi

    local NUM_BEHIND="$(git log --oneline ..@{u} 2> /dev/null | wc -l | tr -d ' ')"
    if [ "$NUM_BEHIND" -gt 0 ]; then
        DIVERGENCES+=( "${BEHIND//NUM/$NUM_BEHIND}" )
    fi

    local GIT_DIR="$(git rev-parse --git-dir 2> /dev/null)"
    if [ -n $GIT_DIR ] && test -r $GIT_DIR/MERGE_HEAD; then
        FLAGS+=( "$MERGING" )
    fi

    if [[ -n $(git ls-files --other --exclude-standard 2> /dev/null) ]]; then
        FLAGS+=( "$UNTRACKED" )
    fi

    if ! git diff --quiet 2> /dev/null; then
        FLAGS+=( "$MODIFIED" )
    fi

    if ! git diff --cached --quiet 2> /dev/null; then
        FLAGS+=( "$STAGED" )
    fi

    local -a GIT_INFO
    GIT_INFO+=( "%F{$MAIN_COLOR}[$GIT_LOCATION" )
    [ -n "$GIT_STATUS" ] && GIT_INFO+=( "$GIT_STATUS" )
    [[ ${#DIVERGENCES[@]} -ne 0 ]] && GIT_INFO+=( "${(j::)DIVERGENCES}" )
    [[ ${#FLAGS[@]} -ne 0 ]] && GIT_INFO+=( "${(j::)FLAGS}" )
    GIT_INFO+=( "%F{$MAIN_COLOR}$GIT_ICON]%f" )
    echo "${(j: :)GIT_INFO}"
}

# Correct the prompt when PWD is big
_format_lines() {
    local newline=$'%(?:%F{green}:%F{red})\n│%F{blue} '
    (( width = $COLUMNS - 3 )) # -3 parce que le append de la barre + l'espace + margin
    (( width_rem = $width + 1 ))
    local login_hostname=$(print -P "  %n@%m:  ")
    (( width1st = $COLUMNS - ${#login_hostname} ))
    (( width1st_rem = $width1st + 1 ))
    local rest=$@ # le reste a traiter
    
    if [[ ${#rest} -le $width1st ]]; then
        echo $rest
    else
        if [[ $width1st -le 0 ]]; then # when terminal too small don't show PWD
            return 0
        fi
        # Premiere ligne est speciale
        local temp=$(echo $rest | cut -c1-$width1st) # get the beginning of the line
        rest=$(echo $rest | cut -c$width1st_rem-) # get the remaining
        local result=$temp
        while [[ ${#rest} -gt $width ]]; do
            temp=$(echo $rest | cut -c1-$width)
            rest=$(echo $rest | cut -c$width_rem-)
            result=$result$newline$temp
        done
        echo $result$newline$rest
    fi
}
# Encapsulate variables used for prompt creation
_createprompt() {
    local current_path=$(_format_lines $(print -P %~))
    local ret_status="%(?:%F{green}%(#:#:$):%F{red}%(#:#:$))"
    echo "$(_ssh_info)%B%(?:%F{green}:%F{red})┌ %F{green}%n@%m: %F{blue}$current_path
%(?:%F{green}:%F{red})└ $ret_status%f%b "
}

PROMPT='$(_createprompt)'
RPROMPT='%(?:$(_git_info):$(_git_info) %F{yellow}[%?])'
SPROMPT="Correct %F{red}'%R'%f to %F{green}'%r'%f [Yes, No, Abort, Edit]? "
