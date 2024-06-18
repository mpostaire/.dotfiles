fzf_preview_files() {
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
        rsv=${realpath:h}/${rsv#$HOME}
        rsv=${rsv:a}
        local out=$(ls -d1 --color=always "$rsv" 2> /dev/null)
        # if out is empty, it means ls encountered an error (it may be a link destination file that in sysfs)
        # and we cannot do anything about it so we print it without colors.
        rsv=${out:-$rsv}
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
    fi
}
