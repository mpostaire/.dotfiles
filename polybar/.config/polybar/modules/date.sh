#!/bin/sh

echo $$ > ~/.config/polybar/modules/datepid

t=0

toggle() {
    t=$(((t + 1) % 2))
}

trap "toggle" USR1

while true; do
    if [ $t -eq 0 ]; then
        echo " $(date "+%H:%M")"
    else
        echo " $(date "+%H:%M")"
        ~/.config/polybar/modules/calendarmenu &
    fi
    sleep 30 &
    wait
done