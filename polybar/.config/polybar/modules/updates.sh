#!/usr/bin/env bash

notification() {
    if [ $UPDATES == 1 ]; then
        majstr="mise à jour"
    else
        majstr="mises à jour"
    fi

    if [[ $UPDATES == 0 && $UPDATES_AUR == 0 ]]; then
        notify-send "Mises à jour" "Le système est à jour"
    elif [[ $UPDATES == 0 ]]; then
        notify-send "Mises à jour" "Il y a $UPDATES_AUR $majstr venant du AUR"
    elif [[ $UPDATES_AUR == 0 ]]; then
        notify-send "Mises à jour" "Il y a $UPDATES $majstr"
    else
        notify-send "Mises à jour" "Il y a $UPDATES $majstr et $UPDATES_AUR venant du AUR"
    fi
}

trap "notification" USR1

# Icons
BAR_ICON=""

while true; do
    UPDATES=$(checkupdates 2>/dev/null | wc -l)
    UPDATES_AUR=$(yay -Qum 2> /dev/null | wc -l)
    if [[ $UPDATES == 0 && $UPDATES_AUR == 0 ]]; then
        echo
    else
        yellow=$(xrdb -query | grep "color6" | head -n1 | awk '{print $NF}')
        if [[ $UPDATES == 0 ]]; then
            echo "$BAR_ICON %{F${yellow}}$UPDATES_AUR%{F-}"
        elif [[ $UPDATES_AUR == 0 ]]; then
            echo "$BAR_ICON $UPDATES"
        else
            echo "$BAR_ICON $UPDATES%{F${yellow}}+$UPDATES_AUR%{F-}"
        fi
        notification
    fi
    sleep 1800 &
    wait
done
