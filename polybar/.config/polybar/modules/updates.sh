#!/usr/bin/env bash

# Icons
BAR_ICON=""

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
fi

