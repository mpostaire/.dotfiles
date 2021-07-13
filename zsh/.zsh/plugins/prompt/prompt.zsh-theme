## PROMPT

autoload -U colors && colors # Enable colors in prompt

# _prompt_git_info taken and modified from https://joshdick.net/2017/06/08/my_git_prompt_for_zsh_revisited.html

# Echoes information about Git repository status when inside a Git repository
# partially tested
# TODO: edit to my preferences
_prompt_git_info() {
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

    if [[ -n $(git ls-files --other --exclude-standard 2> /dev/null) ]]; then
        FLAGS+=( "${UNTRACKED}" )
    fi

    if ! git diff --quiet 2> /dev/null; then
        FLAGS+=( "${MODIFIED}" )
    fi

    if ! git diff --cached --quiet 2> /dev/null; then
        FLAGS+=( "${STAGED}" )
    fi

    local -a GIT_INFO
    GIT_INFO+=( "%F{${MAIN_COLOR}}[${GIT_LOCATION}" )
    [ -n "${GIT_STATUS}" ] && GIT_INFO+=( "${GIT_STATUS}" )
    [[ ${#DIVERGENCES[@]} -ne 0 ]] && GIT_INFO+=( "${(j::)DIVERGENCES}" )
    [[ ${#FLAGS[@]} -ne 0 ]] && GIT_INFO+=( "${(j::)FLAGS}" )
    GIT_INFO+=( "%F{${MAIN_COLOR}}${GIT_ICON}]%f" )
    echo "${(j: :)GIT_INFO}"
}

# Correct the prompt when PWD is big
_prompt_format_path() {
    # $1 is the color, following arg(s) are the path
    local newline="%(?:%F{green}:%F{red})\n│${1} "
    (( width = ${COLUMNS} - 3 )) # -3 parce que le append de la barre + l'espace + margin
    local login_hostname=$(print -P "  %n@%m:  ")
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

_prompt_retcode_rprompt='%(?:: %F{yellow}[%?])'
_rprompt_async_proc=0
# the precmd function is executed before displaying each prompt
precmd() {
    # TODO parse LS_COLORS to get colors automatically
    local path_color="%F{blue}"
    local link_target=$(readlink -f ${PWD})
    if [[ ${link_target} != ${PWD} ]]; then
        link_target="${rsv/$HOME/~}"
        path_color="%F{cyan}"
    fi

    local ssh_status
    [[ -n ${SSH_CONNECTION} ]] && ssh_status=' %F{yellow}(ssh)%F{green}'

    local current_path=$(_prompt_format_path ${path_color} $(print -P %~))
    PROMPT="%B%(?:%F{green}:%F{red})┌ %F{green}%n@%m${ssh_status}: ${current_path}
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
    RPROMPT="$(cat /tmp/zsh_prompt_$$)${_prompt_retcode_rprompt}"

    # reset proc number
    rm /tmp/zsh_prompt_$$
    _rprompt_async_proc=0

    # redisplay
    zle && zle reset-prompt
}

PROMPT="%B%F{green}>%f%b "
RPROMPT="${_prompt_retcode_rptompt}"
SPROMPT="Correct %F{red}'%R'%f to %F{green}'%r'%f [Yes, No, Abort, Edit]? "
