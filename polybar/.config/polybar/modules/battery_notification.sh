#!/bin/sh

state=$(acpi -b | awk '{print substr($3, 1, length($3)-1)}')
remaining=$(acpi -b | awk '{print substr($5, 1, length($5)-3)}')

hours=$(echo $remaining | awk '{x=substr($0, 1, 2);x=x+0;print x}')
minutes=$(echo $remaining | awk '{x=substr($0, 4, length($0));x=x+0;print x}')

if [ "$hours" == "0" ]; then
    if [ "$minutes" == "1"  ]; then
        formatted_remaining="$minutes minute"
    else
        formatted_remaining="$minutes minutes"
    fi
    # case when $minutes == 0 and $hours == 0 should never happen
else
    if [ "$hours" == "1"  ]; then
        formatted_remaining="$hours heure"
    else
        formatted_remaining="$hours heures"
    fi

    if [ "$minutes" == "1"  ]; then
        formatted_remaining="$formatted_remaining et $minutes minute"
    elif [ "$minutes" != "0" ]; then
        formatted_remaining="$formatted_remaining et $minutes minutes"
    fi
fi

if [ "$state" == "Discharging" ]; then
    if [[ ("$hours" == "1" && "$minutes" == "0") || ("$hours" == "0" && "$minutes" == "1") ]]; then
        notify-send "Batterie en décharge" "$formatted_remaining restante"
    else
        notify-send "Batterie en décharge" "$formatted_remaining restantes"
    fi
elif [ "$state" == "Charging" ]; then
    notify-send "Batterie en charge" "$formatted_remaining avant charge complète"
else
    notify-send "Batterie chargée"
fi
