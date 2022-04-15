## PROMPT

autoload -U colors && colors # Enable colors in prompt

# TODO async RPROMPT that updates itself regularly (every second?)

# _prompt_git_info taken and modified from https://joshdick.net/2017/06/08/my_git_prompt_for_zsh_revisited.html
# Echoes information about Git repository status when inside a Git repository
_prompt_git_info() {
    # Exit if not inside a Git repository
    ! git rev-parse --is-inside-work-tree > /dev/null 2>&1 && return

    # Git branch/tag, or name-rev if on detached head
    local GIT_LOCATION=${$(git symbolic-ref -q HEAD || git name-rev --name-only --no-undefined --always HEAD)#(refs/heads/|tags/)}

    local AHEAD="%F{red}⇡NUM%f"
    local BEHIND="%F{cyan}⇣NUM%f"
    local MERGING="%F{magenta}✖%f"
    local STAGED="%F{green}⦁%f"
    local UNTRACKED="%F{red}?%f"
    local MODIFIED="%F{yellow}!%f"
    local STASHED="%F{gray}*%f"

    local -a DIVERGENCES
    local -a FLAGS

    local NUM_AHEAD="$(git log --oneline @{u}.. 2> /dev/null | wc -l | tr -d ' ')"
    if [ "${NUM_AHEAD}" -gt 0 ]; then
        DIVERGENCES+=( "${AHEAD//NUM/${NUM_AHEAD}}" )
    fi

    local NUM_BEHIND="$(git log --oneline ..@{u} 2> /dev/null | wc -l | tr -d ' ')"
    if [ "${NUM_BEHIND}" -gt 0 ]; then
        DIVERGENCES+=( "${BEHIND//NUM/${NUM_BEHIND}}" )
    fi

    local GIT_DIR="$(git rev-parse --git-dir 2> /dev/null)"
    if [ -n ${GIT_DIR} ] && test -r ${GIT_DIR}/MERGE_HEAD; then
        FLAGS+=( "${MERGING}" )
    fi

    if ! git diff --cached --quiet 2> /dev/null; then
        FLAGS+=( "${STAGED}" )
    fi

    if ! git diff --quiet 2> /dev/null; then
        FLAGS+=( "${MODIFIED}" )
    fi
    
    if [[ -n $(git ls-files --others --exclude-standard 2> /dev/null) ]]; then
        FLAGS+=( "${UNTRACKED}" )
    fi

    if [[ -n $(git stash list 2> /dev/null) ]]; then
        FLAGS+=( "${STASHED}" )
    fi

    local -a GIT_INFO
    GIT_INFO+=( "%F{15}(${GIT_LOCATION}" )
    [ -n "${GIT_STATUS}" ] && GIT_INFO+=( "${GIT_STATUS}" )
    [[ ${#DIVERGENCES[@]} -ne 0 ]] && GIT_INFO+=( "${(j::)DIVERGENCES}" )
    [[ ${#FLAGS[@]} -ne 0 ]] && GIT_INFO+=( "${(j::)FLAGS}" )
    print "${(j: :)GIT_INFO}%F{15})%f"
}

# Correct the prompt when PWD is big
_prompt_format_path() {
    # $1 is the color, following arg(s) are the path
    local newline="%(?:%F{green}:%F{red})\n│${1} "
    (( width = ${COLUMNS} - 3 )) # -3 parce que le append de la barre + l'espace + margin
    local login_hostname=$(print -P "  %n@%M:  ")
    (( width1st = ${COLUMNS} - ${#login_hostname} ))
    local rest=${@[@]:2} # le reste a traiter

    if [[ ${#rest} -le ${width1st} ]]; then
        result=${1}${rest}
    else
        if [[ ${width1st} -le 0 ]]; then # when terminal too small don't show PWD
            return 0
        fi
        # Premiere ligne est speciale
        local temp=${rest:0:${width1st}} # get the beginning of the line
        rest=${rest:${width1st}} # get the remaining

        local result=${1}${temp}
        while [[ ${#rest} -gt ${width} ]]; do
            temp=${rest:0:${width}}
            rest=${rest:${width}}
            result=${result}${newline}${1}${temp}
        done
        result=${result}${newline}${1}${rest}
    fi

    print ${result}
}

# put the return value in rprompt if it is > 0
_prompt_rprompt='%(?:: %F{red}[%?]%f)'
# put a ssh notification in rprompt if we are in a ssh session
[[ -n ${SSH_CONNECTION-}${SSH_CLIENT-}${SSH_TTY-} ]] && _prompt_rprompt=' %F{magenta}(ssh)%f'${_prompt_rprompt}
# put the number of running background jobs in rprompt if there are any
_prompt_rprompt='%(1j: %F{yellow}%jj%f:)'${_prompt_rprompt}

_rprompt_async_proc=0
_make_prompt() {
    local path_color="%F{blue}"
    local link_target=$(readlink -f ${PWD})
    if [[ ${link_target} != ${PWD} ]]; then
        link_target="${rsv/$HOME/~}"
        path_color="%F{cyan}"
    fi

    local current_path=$(_prompt_format_path ${path_color} $(print -P %~))
    
    PROMPT="%B%(?:%F{green}:%F{red})┌ %F{green}%n@%M${ssh_status}: ${current_path}
%(?:%F{green}:%F{red})└ %(?:%F{green}%(#:#:$):%F{red}%(#:#:$))%f%b "

    async() {
        # save to temp file
        printf "%s" "$(_prompt_git_info)" > "/tmp/zsh_prompt_$$"

        # signal parent
        kill -s USR1 $$
    }

    # do not clear RPROMPT, let it persist

    # kill child if necessary
    if [[ "${_rprompt_async_proc}" != 0 ]]; then
        kill -s HUP ${_rprompt_async_proc} >/dev/null 2>&1 || :
    fi

    # start background computation
    async &!
    _rprompt_async_proc=$!
}

TRAPUSR1() {
    # read from temp file
    RPROMPT="$(</tmp/zsh_prompt_$$)${_prompt_rprompt}"

    # reset proc number
    rm /tmp/zsh_prompt_$$
    _rprompt_async_proc=0

    # redisplay
    zle && zle reset-prompt
}

PROMPT="%B%F{green}>%f%b "
RPROMPT="${_prompt_rprompt}"
SPROMPT="Correct %F{red}'%R'%f to %F{green}'%r'%f [Yes, No, Abort, Edit]? "

autoload -Uz add-zsh-hook
# the precmd hook is executed before displaying each prompt
add-zsh-hook -Uz precmd _make_prompt
