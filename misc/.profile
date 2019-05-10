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

#[[ $(tty) = "/dev/tty1" ]] && exec startx
