#!/usr/bin/env zsh

# IF ZTUPIDE_ZCOMPILE, use zcompile on all plugins and load the compiled result
# Make an autocompletion file/module/??? for these commands
# periodic updates

# TODO what happens when a loaded (installed in ZTUPIDE_PLUGIN_PATH) plugin is not loaded but not uninstalled with ztupide unload ?
# the plugin dir is in ZTUPIDE_PLUGIN_PATH but really should be in cache ? -- clean command should prompt user for unloaded plugin that
# are present in ZTUPIDE_PLUGIN_PATH and ask to remove-place in cache or le them there

ZTUPIDE_PLUGIN_PATH=${ZTUPIDE_PLUGIN_PATH:-~/.zsh/plugins}
[ -d ~/.zsh/cache/plugins ] || mkdir -p ~/.zsh/cache/plugins

# TODO make these variables' scope inside this file only
_ztupide_to_load=()
typeset -A _ztupide_to_source

_ztupide_load() {
    # TODO: support for .zsh-theme
    [ -d "${ZTUPIDE_PLUGIN_PATH}" ] || mkdir "${ZTUPIDE_PLUGIN_PATH}"

    if [[ "${1}" =~ .+"/".+ ]]; then
        local plugin_name="${${(@s:/:)1}[2]}"
        [ -d ~/.zsh/cache/plugins/"${plugin_name}" ] && mv -f ~/.zsh/cache/plugins/"${plugin_name}" "${ZTUPIDE_PLUGIN_PATH}"
        local plugin_path="${ZTUPIDE_PLUGIN_PATH}"/"${plugin_name}"
        [ -d "${plugin_path}" ] || git -C "${ZTUPIDE_PLUGIN_PATH}" clone https://github.com/"${1}" --quiet
    else
        local plugin_name="${1}"
        [ -d ~/.zsh/cache/plugins/"${plugin_name}" ] && mv -f ~/.zsh/cache/plugins/"${plugin_name}" "${ZTUPIDE_PLUGIN_PATH}"
        local plugin_path="${ZTUPIDE_PLUGIN_PATH}"/"${plugin_name}"
    fi
    
    local plugin_file=("${plugin_path}"/*.plugin.zsh(NY1)) # match first .plugin.zsh found, prevents multiple .plugin.zsh
    if [ -d "${plugin_path}" ] && [ "${#plugin_file}" -eq 1 ]; then
        echo "_end_success:${1}:${plugin_file[1]}:${2}"
    else
        rm -rf "${plugin_path}"
        echo "_end_fail:${1}"
    fi
}

_ztupide_unload() {
    [ -z "${1}" ] && echo "plugin unload error: none specified" && return

    if [[ "${1}" =~ .+"/".+ ]]; then
        local plugin_name="${${(@s:/:)1}[2]}"
        local plugin_path="${ZTUPIDE_PLUGIN_PATH}"/"${plugin_name}"
    else
        local plugin_name="${1}"
        local plugin_path="${ZTUPIDE_PLUGIN_PATH}"/"${plugin_name}"
    fi

    if [ -d "${plugin_path}" ]; then
        mv -f "${plugin_path}" ~/.zsh/cache/plugins/
        echo "${plugin_name} plugin unloaded"
    else
        echo "plugin unload error: ${plugin_name} plugin not found"
    fi
}

_ztupide_update() {
    # TODO: also update ztupide plugin manager (we can't just git pull because it would overwrite this script and cause undetermined bad things to happen)
    local plugin_path
    for plugin_path in "${ZTUPIDE_PLUGIN_PATH}"/*(/N); do
        if [ -d "${plugin_path}"/.git ]; then
            local plugin_file=("${plugin_path}"/*.plugin.zsh(NY1))
            if [ "${#plugin_file}" -eq 1 ]; then
                git -C "${plugin_path}" pull origin master --quiet
                local plugin_name="${${(@s:/:)plugin_path}[-1]}"
                echo "${plugin_name} plugin updated"
            fi
        fi
    done
}

_ztupide_clean() {
    local plugin_path
    for plugin_path in ~/.zsh/cache/plugins/*(/N); do
        if [ -d "${plugin_path}"/.git ]; then
            rm -rf "${plugin_path}"
        else
            read "ans?${${(@s:/:)plugin_path}[-1]}is a local plugin. Do you want to remove it (y/N)? "
            [[ "${ans}" =~ ^[Yy]$ ]] && rm -rf "${plugin_path}"
        fi
    done
}

_ztupide_load_async_handler() {
    if read -r -u "${1}" line && [[ "${line}" =~ "_end*" ]]; then
        # close FD
        exec {1}<&-
        # remove handler
        zle -F "${1}"

        if [[ "${line}" =~ "_end_success:*" ]]; then
            local ret=(${(@s/:/)line})
            _ztupide_to_source["${ret[2]}"]="${ret[3]}"

            for e in ${_ztupide_to_load}; do
                if [ -z "${_ztupide_to_source["${e}"]}" ]; then
                    return
                elif [ "${_ztupide_to_source["${e}"]}" = "_fail" ]; then
                    _ztupide_to_load=(${_ztupide_to_load:1})
                else
                    _ztupide_to_load=(${_ztupide_to_load:1})
                    source "${_ztupide_to_source["${e}"]}"
                    [ -z "${ret[4]}" ] || eval "${ret[4]}"
                fi
            done
        else
            _ztupide_to_source["${${(@s/:/)line}[2]}"]="_fail"
            echo "plugin load error: "${${(@s/:/)line}[2]}" is not a valid plugin"
        fi
    fi
}

_ztupide_load_async() {
    # create async_fd
    local async_fd
    exec {async_fd}< <(_ztupide_load ${@})

    # needed to fix ctrl+c not working in some cases
    command true

    # zle -F installs input handler on given FD
    zle -F "${async_fd}" _ztupide_load_async_handler
}

ztupide() {
    case "${1}" in
    load)
        [ -z "${2}" ] && echo "plugin load error: none specified" && return
        # _ztupide_load "${2}"
        _ztupide_to_load+="${2}"
        _ztupide_load_async ${@:2}
        ;;
    unload)
        _ztupide_unload "${2}"
        ;;
    update)
        _ztupide_update && exec zsh
        ;;
    clean)
        _ztupide_clean
        ;;
    *)
        # TODO: this message
        echo "Usage : ztupide ACTION\n\tACTIONs: update - update plugins"
        ;;
    esac
}
