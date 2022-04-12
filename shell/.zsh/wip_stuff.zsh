# WIP: (slow -> find way to speed it up) History menu (ctrl+r) syntax higlighting. It works most of the time (some commands have buggy colors).
# echo ${(@qq)out} ---> (@qq) modifier escapes problematic chars for input use later (but don't escape '%')
function highlight_command() {
    local reply=""
    local ret="$*"
    -fast-highlight-process "" "$ret" 0
    
    # TODO use $fg_bold, etc instead of %B, etc
    local color_reset="$reset_color"
    local offset=0

    for ((i = 1; i <= ${#reply}; i++)); do
        [ -z "${reply[${i}]}" ] && continue
        
        local color_info=(${(s[ ])reply[${i}]})

        local color=(${(s[,])color_info[3]})

        local color_fg=${${color[1]}:3}
        local to_insert="${fg[${color_fg}]}"
        # TODO handle multiple modifiers (e.g. bold + underline) for now we only handle one at a time
        # [ "${color[2]}" = "underline" ] && to_insert="${to_insert}%U"
        # [ "${color[2]}" = "bold" ] && to_insert="${to_insert}%B"
        
        local start="${color_info[1]}"
        (( start += offset ))
        ret=${ret:0:$start}$to_insert${ret:$start}
        (( offset += ${#to_insert} ))

        local end="${color_info[2]}"
        (( end += offset ))
        ret=${ret:0:$end}$color_reset${ret:$end}
        (( offset += ${#color_reset} ))
    done

    # echo $reply # debug
    print -r $ret
}
function highlight_command_from_history() {
    hist_results=("${(@f)$(fc -rl 1)}")
    
    for ((i = 1; i <= ${#hist_results}; i++)); do
        local hist_command=${hist_results[$i]##*[0-9]  }
        print -r "${${hist_results[$i]}%%$hist_command}$(highlight_command $hist_command)"
    done
}

# # Color fzf alt+c output (faster than alternative below but links everything is colored like a directory wich they technically are)
# export FZF_ALT_C_OPTS="--ansi"
# export FZF_ALT_C_COMMAND='command find -L . -mindepth 1 \( -path "*/\.*" -o -fstype "sysfs" -o -fstype "devfs" -o -fstype "devtmpfs" -o -fstype "proc" \) \
# -prune -o -type d -printf "\033[${${(s[:])LS_COLORS}[2]:3}m%P\033[0m\n" 2> /dev/null'

# # # Color fzf alt+c output (a bit slow but symlinks are accurately colored)
# # export FZF_ALT_C_COMMAND="command find -L . -mindepth 1 \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
# # -o -type d -exec ls --color=always -d {} \; 2> /dev/null"
