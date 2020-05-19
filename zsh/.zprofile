emulate sh -c 'source $HOME/.profile'

skip_global_compinit=1

# Execute code in the background to not affect the current session
(
    zcompile () {
        [[ ! "${1}".zwc -nt "${1}" && -r "${1}" && -w "${1:h}" ]] && builtin zcompile "${1:P}"
    }

    # <https://github.com/zimfw/zimfw/blob/master/login_init.zsh>
    setopt LOCAL_OPTIONS EXTENDED_GLOB

    # Compile zcompdump, if modified, to increase startup speed.
    zcompile ${ZDOTDIR:-$HOME}/.zcompdump

    # zcompile .zshrc
    zcompile ${ZDOTDIR:-${HOME}}/.zshrc
    zcompile ${ZDOTDIR:-${HOME}}/.zprofile
    zcompile ${ZDOTDIR:-${HOME}}/.zshenv
) &!
