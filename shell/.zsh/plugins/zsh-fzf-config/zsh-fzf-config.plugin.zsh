# TODO handle case can't ls for colors cause permissions or dont exist (in case of links dest)
#       ex: try completing '/sys/class/power_supply/BAT0/<tab>' and hover 'device'
# TODO use ctrl+h binding to toggle show/hide hidden files in preview (save in file this status for presistency?)

local _fzf_preview_files='# if realpath empty or doesnt exit, it likely is an argument so print it and return
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
    # show files (including hidden files) in preview
    local out=$(ls -A1 --color=always $realpath)
    # if no output, show message for empty directory
    if [ -z "$out" ]; then
        out="Empty directory"
        printf -v out "\033[37m%*s\033[0m" $(((${#out}+$FZF_PREVIEW_COLUMNS)/2)) "$out"
        printf "%.0s\n" {1..$((($FZF_PREVIEW_LINES/2)-2))}
    fi
    print $out
    return
fi

# try previewing image
if [[ "${type/\/*/}" = "image" ]]; then
    if command -v chafa > /dev/null; then
        chafa -s ${FZF_PREVIEW_COLUMNS}x$(($FZF_PREVIEW_LINES-2)) $realpath 2> /dev/null
    else
        print "Install the \"chafa\" package to enable image preview."
    fi
# try previewing binary file content
elif [[ "${type/*charset=/}" = "binary" ]]; then
    hexdump -C -n 500 $realpath
# try previewing ascii file content
else
    if command -v bat > /dev/null; then
        bat --color=always --theme=TwoDark --style=numbers,changes --line-range=:500 $realpath
    else
        head --lines=500 $realpath
    fi
fi'

# ctrl-r keybinding is double toggle-preview to reload preview window contents (not using the reload() action that reevaluate the fzf command)
export FZF_DEFAULT_OPTS="--info=inline --cycle --tabstop=4
--bind=ctrl-d:abort,ctrl-H:backward-kill-word,ctrl-p:toggle-preview,ctrl-r:toggle-preview+toggle-preview,ctrl-space:select,tab:down,shift-tab:up
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
[[ -a ~/.fzf.zsh ]] && source ~/.fzf.zsh

# preview-window at the bottom for git checkout completion 
zstyle ':fzf-tab:complete:git-checkout:*' fzf-flags '--preview-window=down:3:wrap'
# preview file/directory during completion
# TODO (maybe impossible?): add keybind to toggle show/hide hidden files in directory preview
zstyle ':fzf-tab:complete:*:*:files' fzf-preview ${_fzf_preview_files}
zstyle ':fzf-tab:complete:*:*:files' fzf-flags '--preview-window=~2'
# preview systemd unit status during completion
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
# zstyle ':fzf-tab:complete:*:*:files' fzf-bindings 'ctrl-h:reload(echo ok)'
# despite its name, this sets the height of fzf-tab menu even without using tmux
FZF_TMUX_HEIGHT=70%

# overwrite -ftb-colorize function from fzf-tab to fix symlinks targets not properly colored
# also overwrites -ftb-fzf function from fzf-tab to allow custom preview window when the completion
# list are files/directories as well as new variable buffer to get the user input in the zsh (not fzf) prompt
# TODO: open PR to merge the fix instead of overwriting this
fpath+=(${0:A:h}/functions)
