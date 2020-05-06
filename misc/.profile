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

# qt native gtk integration
export QT_QPA_PLATFORMTHEME=gtk2

# better time command formatting
export TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S'

# enable numlock
if [ -x /usr/bin/numlockx ]; then
      /usr/bin/numlockx on
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# auto startx if connected in tty1 (useful if not using a login manager)
#[[ $(tty) = "/dev/tty1" ]] && exec startx
