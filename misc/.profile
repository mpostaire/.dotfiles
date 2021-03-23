# qt native gtk integration
export QT_QPA_PLATFORMTHEME=gtk2
export EDITOR=/usr/bin/vim
export TERMINAL=/usr/bin/urxvt
export GTK2_RC_FILES="$HOME/.gtkrc-2.0"
# fix "xdg-open fork-bomb" export your preferred browser from here
export BROWSER=/usr/bin/firefox

# fix android studio starting with blank screen
export _JAVA_AWT_WM_NONREPARENTING=1

# fix android emulator
export ANDROID_EMULATOR_USE_SYSTEM_LIBS=1

# time command format
export TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S'

# set PATH so it includes user's private bin if it exists
[ -d "$HOME/bin" ] && PATH="$PATH:$HOME/bin"
[ -d "$HOME/.local/bin" ] && PATH="$PATH:$HOME/.local/bin"

# enable gtk appmenu
if [ -n "$GTK_MODULES" ]; then
    GTK_MODULES="${GTK_MODULES}:appmenu-gtk-module"
else
    GTK_MODULES="appmenu-gtk-module"
fi

if [ -z "$UBUNTU_MENUPROXY" ]; then
    UBUNTU_MENUPROXY=1
fi

export GTK_MODULES
export UBUNTU_MENUPROXY

# auto startx if connected in tty1 (useful if not using a login manager)
[[ -z $DISPLAY && $(tty) = "/dev/tty1" ]] && exec startx
