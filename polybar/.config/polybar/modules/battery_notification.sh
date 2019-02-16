#!/bin/sh

state=$(acpi -b | awk '{print substr($3, 1, length($3)-1)}')
remaining=$(acpi -b | awk '{print substr($5, 1, length($5)-3)}')

if [ "$state" == "Discharging" ]; then
    notify-send "Batterie en décharge" "$remaining restants"
elif [ "$state" == "Charging" ]; then
    notify-send "Batterie en charge" "$remaining avant charge complète"
else
    notify-send "Batterie chargée"
fi
