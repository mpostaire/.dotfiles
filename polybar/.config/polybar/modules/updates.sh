#!/usr/bin/env bash

# Icons
BAR_ICON=""

get_total_updates() { UPDATES=$(checkupdates 2>/dev/null | wc -l); }

while true; do
    get_total_updates
    if (( UPDATES == 0 )); then
        echo
        sleep 1800
    else
        echo "$BAR_ICON $UPDATES"
        sleep 60
    fi
done

