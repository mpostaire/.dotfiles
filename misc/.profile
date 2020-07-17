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
[ -d "$HOME/bin" ] && PATH="$HOME/bin:$PATH"
[ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"

# auto startx if connected in tty1 (useful if not using a login manager)
[[ -z $DISPLAY && $(tty) = "/dev/tty1" ]] && exec startx
