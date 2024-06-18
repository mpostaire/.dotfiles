# fix "xdg-open fork-bomb" export your preferred browser from here
export BROWSER=/usr/bin/firefox

if [[ -x /usr/bin/nvim ]]; then
    export EDITOR=/usr/bin/nvim
elif [[ -x /usr/bin/vim ]]; then
    export EDITOR=/usr/bin/vim
else
    export EDITOR=/usr/bin/nano
fi

# qt native gtk integration
export QT_QPA_PLATFORMTHEME=qt5ct

# fix android emulator
export ANDROID_EMULATOR_USE_SYSTEM_LIBS=1

# time command format
export TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S'

# enable ssh gnome-keyring password popup
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh"

export GOPATH="$HOME/.go"

# set PATH so it includes user's private bin if it exists
[ -d "$HOME/bin" ] && PATH="$PATH:$HOME/bin"
[ -d "$HOME/.local/bin" ] && PATH="$PATH:$HOME/.local/bin"
[ -d "$HOME/.cargo/bin" ] && PATH="$PATH:$HOME/.cargo/bin"
[ -d "$HOME/.go/bin" ] && PATH="$PATH:$HOME/.go/bin"

# enable gtk appmenu
if [ -n "$GTK_MODULES" ]; then
    export GTK_MODULES="${GTK_MODULES}:appmenu-gtk-module"
else
    export GTK_MODULES="appmenu-gtk-module"
fi

if [ -z "$UBUNTU_MENUPROXY" ]; then
    export UBUNTU_MENUPROXY=1
fi

# auto startx if connected in tty1 and X is not running (useful if not using a login manager)
[[ -z $DISPLAY && $(tty) = "/dev/tty1" ]] && exec startx
