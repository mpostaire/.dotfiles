#!/bin/bash

# colors
red=$(xrdb -query | grep "color1" | head -n1 | awk '{print $NF}')
red_alt=$(xrdb -query | grep "color9" | head -n1 | awk '{print $NF}')
green=$(xrdb -query | grep "color2" | head -n1 | awk '{print $NF}')
green_alt=$(xrdb -query | grep "color10" | head -n1 | awk '{print $NF}')
blue=$(xrdb -query | grep "color4" | head -n1 | awk '{print $NF}')
blue_alt=$(xrdb -query | grep "color12" | head -n1 | awk '{print $NF}')
black_alt=$(xrdb -query | grep "color15" | head -n1 | awk '{print $NF}')
black=$(xrdb -query | grep "color0" | head -n1 | awk '{print $NF}')
blank="#00000000"

background=~/Images/lockscreen.png

if [ ! -f $background ]; then
    background=""
else
    background="-i $background"
fi

# kill rofi to prevent locking failure
killall rofi

# suspend dunst notifications
killall -SIGUSR1 dunst

# pause music
mpc pause

i3lock -mn -e $background              \
--insidevercolor=${blue}22            \
--ringvercolor=${blue_alt}88          \
\
--insidewrongcolor=${red}22           \
--ringwrongcolor=${red_alt}88         \
\
--insidecolor=$blank                  \
--ringcolor=${green_alt}88            \
--linecolor=$blank                    \
--separatorcolor=${black_alt}55       \
\
--verifcolor=${black}EE               \
--wrongcolor=${black}EE               \
--timecolor=${black}EE                \
--datecolor=${black}EE                \
--keyhlcolor=${green}FF               \
--bshlcolor=${red}FF                  \
\
--clock                               \
--indicator                           \
--timestr="%H:%M:%S"                  \
--datestr="%d %B %Y"                  \
--radius 160                          \
--ring-width 8.5                      \
\
--noinputtext="Pas d'entrée"          \
--wrongtext="Réessayez"               \
--veriftext="Vérification..."         \
\
--time-font="DejaVu Sans Mono"        \
--date-font="DejaVu Sans Mono"        \
--verif-font="DejaVu Sans Mono"       \
--wrong-font="DejaVu Sans Mono"

# resume dunst notifications
killall -SIGUSR2 dunst
