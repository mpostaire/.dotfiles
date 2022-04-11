#!/bin/sh
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps

if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# set the cursor
xsetroot -cursor_name left_ptr

# set the lockscreen
xss-lock -- $HOME/.scripts/lock.sh &

# dim the screen after 10 minutes of inactivity, lock 10 seconds later
#xset s 600 10
#xset s 20 10
#xss-lock -n /usr/share/doc/xss-lock/dim-screen.sh -- ~/.scripts/lock.sh

# start some nice programs

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

command -v numlockx > /dev/null && numlockx
authentication_agent=/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
command -v $authentication_agent > /dev/null && $authentication_agent &

# fix android studio starting with blank screen
export _JAVA_AWT_WM_NONREPARENTING=1
exec awesome > ~/.cache/awesome/stdout 2> ~/.cache/awesome/stderr
# exec awesome
