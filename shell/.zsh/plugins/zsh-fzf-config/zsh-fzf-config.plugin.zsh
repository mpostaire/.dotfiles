0="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
0="${${(M)0:#/*}:-$PWD/$0}"

# ctrl-r keybinding is double toggle-preview to reload preview window contents (not using the reload() action that reevaluate the fzf command)
export FZF_DEFAULT_OPTS="--info=inline --cycle --tabstop=4 --pointer='>' --marker='>'
--bind=ctrl-d:abort,ctrl-H:backward-kill-word,ctrl-p:toggle-preview,ctrl-r:toggle-preview+toggle-preview,ctrl-space:select,tab:down,shift-tab:up,home:first,end:last
--color=hl:underline:italic:green,bg+:bright-black,gutter:black,hl+:underline:italic:green,info:italic:bright-black,border:bright-black,prompt:bright-blue,pointer:red,marker:bright-yellow,spinner:green,header:yellow"
# TODO: color fzf ctrl+t, ctrl+r (syntax higlighting), alt+c -> ~/.zsh/wip_stuff.zsh contains wip implementations (but very slow)
export FZF_CTRL_R_OPTS="--cycle --reverse --preview 'print {2..}' --preview-window=hidden,wrap"
export FZF_ALT_C_OPTS="--cycle --ansi --preview 'export realpath={}; source ${0:A:h}/functions.zsh && fzf_preview_files' --preview-window=~2"
export FZF_CTRL_T_OPTS="--cycle --preview 'export realpath={}; source ${0:A:h}/functions.zsh && fzf_preview_files' --preview-window=~2"

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

# preview manpages
zstyle ':fzf-tab:complete:man:*' fzf-preview \
    'man $word'

# preview-window at the bottom for git checkout completion
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview \
    'git show --summary --oneline --color=always $word'
zstyle ':fzf-tab:complete:git-checkout:*' fzf-flags \
    '--preview-window=down:3:wrap'

# git branch preview show logs with graph
zstyle ':fzf-tab:complete:git-branch:*' fzf-preview \
    "git log --oneline --graph --date=short --color=always --pretty='format:%C(auto)%cd %h%d %s' \$word"

# preview file/directory during completion
# TODO (maybe impossible?): add keybind to toggle show/hide hidden files in directory preview
zstyle ':fzf-tab:complete:*:*:files' fzf-preview \
    "source ${0:A:h}/functions.zsh && fzf_preview_files"
zstyle ':fzf-tab:complete:*:*:files' fzf-flags \
    '--preview-window=~2'
# preview systemd unit status during completion
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview \
    'SYSTEMD_COLORS=1 systemctl status $word'
# zstyle ':fzf-tab:complete:*:*:files' fzf-bindings 'ctrl-h:reload(echo ok)'
# despite its name, this sets the height of fzf-tab menu even without using tmux
FZF_TMUX_HEIGHT=70%

# overwrite -ftb-colorize function from fzf-tab to fix symlinks targets not properly colored
# also overwrites -ftb-fzf function from fzf-tab to allow custom preview window when the completion
# list contains files and/or directories.
# TODO: open PR to merge the fix instead of overwriting this
fpath+=(${0:A:h}/fzf-tab-overriden-functions)
