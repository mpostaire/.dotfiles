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
_make_prompt() {
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

autoload -Uz add-zsh-hook
# the precmd hook is executed before displaying each prompt
add-zsh-hook -Uz precmd _make_prompt












# # Reduce prompt latency by fetching git status asynchronously.
# add-zsh-hook precmd .prompt.git-status.async
# .prompt.git-status.async() {
#   local fd
#   exec {fd}< <( .prompt.git-status.parse )
#   zle -Fw "$fd" .prompt.git-status.callback
# }
# zle -N .prompt.git-status.callback
# .prompt.git-status.callback() {
#   local fd=$1 REPLY
#   {
#     zle -F "$fd"  # Unhook this callback.

#     [[ $2 == (|hup) ]] ||
#         return  # Error occured.

#     read -ru $fd
#     .prompt.git-status.repaint "$REPLY"
#   } always {
#     exec {fd}<&-  # Close file descriptor.
#   }
# }

# # Periodically sync git status in prompt.
# TMOUT=2  # Update interval in seconds
# trap .prompt.git-status.sync ALRM
# .prompt.git-status.sync() {
#   [[ $CONTEXT == start ]] ||
#       return  # Update only on primary prompt.

#   (
#     # Fetch only if no fetch has occured within the last 2 minutes.
#     local gitdir=$( git rev-parse --git-dir 2> /dev/null )
#     [[ -n $gitdir && -z $gitdir/FETCH_HEAD(Nmm-2) ]] &&
#         git fetch -q &> /dev/null
#   ) &|
#   .prompt.git-status.repaint "$( .prompt.git-status.parse )"
# }

# .prompt.git-status.repaint() {
#   [[ $1 == $RPS1 ]] &&
#       return  # Don't repaint when there's no change.

#   RPS1=$1
#   zle .reset-prompt
# }

# .prompt.git-status.parse() {
#   local MATCH MBEGIN MEND
#   local -a lines

#   lines=( ${(f)"$( git status -sbu 2> /dev/null )"} ) ||
#       { print; return } # Not a git repo

#   local -aU symbols=( ${(@MSu)lines[2,-1]##[^[:blank:]]##} )
#   print -r -- "${${lines[1]/'##'/$symbols}//(#m)$'\C-[['[;[:digit:]]#m/%{${MATCH}%\}}"
# }

# # Continuation prompt
# () {
#   local -a indent=( '%('{1..36}'_,  ,)' )
#   PS2="${(j::)indent}" RPS2='%F{11}%^'
# }

# # Debugging prompt
# () {
#   local -a indent=( '%('{1..36}"e,$( echoti cuf 2 ),)" )
#   local i=$'\t'${(j::)indent}
#   PS4=$'\r%(?,,'$i$'  -> %F{9}%?%f\n)%{\e[2m%}%F{10}%1N%f\r'$i$'%I%b %(1_,%F{11}%_%f ,)'
# }
