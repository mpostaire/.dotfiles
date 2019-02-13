# Prompt theme 
#              (add support git ? + zsh auto highlight regler couleurs + autres ?)
# setopt more and co

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

## SETTINGS

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
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Enable tab completion menu-based
zstyle ':completion:*' menu select
# Default colors for listings.
zstyle ':completion:*:default' list-colors "${(s.:.)LS_COLORS}"
# Speed up completions
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

## PLUGINS

# Colored man pages (needs colors and format tweaking)
source ~/.zsh/zsh-colored-man-pages/colored-man-pages.plugin.zsh

# backward-kill stops at slashes
autoload -U select-word-style
select-word-style bash

autoload -U compinit && compinit # (useless ? don't really know so if bugs place at top)

# Cycle through history based on characters already typed on the line
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "$terminfo[kcuu1]" up-line-or-beginning-search
bindkey "$terminfo[kcud1]" down-line-or-beginning-search

# Easy url support (fix globbing in urls)
autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic

# fish-like autosuggestions (a bit slow)
#ZSH_AUTOSUGGEST_USE_ASYNC=1 # seems to have no impact on performances but incompatibility with up-line-or-beginning-search and down-line-or-beginning-search (there might be a fix by looking into zsh-autosuggestions code)
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

## PROMPT

setopt PROMPT_SUBST # Allow variables in prompt

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
    echo "%B%(?:%F{green}:%F{red})┌ %F{green}%n@%m: %F{blue}$current_path
%(?:%F{green}:%F{red})└ $ret_status%f%b "
}

PROMPT='$(_createprompt)'
#RPROMPT='%F{yellow}%T%f'
RPROMPT='%F{yellow}%(?::[%?])'

