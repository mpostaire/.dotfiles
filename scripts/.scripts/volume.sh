#!/bin/bash

# Icons
volume_muted_icon=/usr/share/icons/Papirus-Dark/symbolic/status/audio-volume-muted-symbolic.svg
volume_low_icon=/usr/share/icons/Papirus-Dark/symbolic/status/audio-volume-low-symbolic.svg
volume_medium_icon=/usr/share/icons/Papirus-Dark/symbolic/status/audio-volume-medium-symbolic.svg
volume_high_icon=/usr/share/icons/Papirus-Dark/symbolic/status/audio-volume-high-symbolic.svg


# Arbitrary but unique message id
msgId=991049

# Change the volume using alsa(might differ if you use pulseaudio)
amixer -c 0 set Master "$@" > /dev/null

# Query amixer for the current volume and whether or not the speaker is muted
volume=$(amixer -c 0 get Master | tail -1 | awk '{print $4}' | sed 's/[^0-9]*//g')
mute=$(amixer -c 0 get Master | tail -1 | awk '{print $6}' | sed 's/[^a-z]*//g')

if [[ $volume == 0 || $mute == "off" ]]; then
    # Show the sound muted notification
    dunstify -a "changeVolume" -u low -i $volume_muted_icon -r $msgId "Volume muted       " 
else
    # Show the volume notification
    bar=$(seq -s "=" $(($volume / 5)) | sed 's/[0-9]//g')
    # ugly but I can't use sed :(
    bar_spaces=$(seq -s " " $(( 20 - ${#bar})) | sed 's/[0-9]//g')
    if [[ $volume -le 20 ]]; then
        dunstify -a "changevolume" -i $volume_low_icon -r $msgId -u low "[$bar$bar_spaces]"
    elif [[ $volume -le 50 ]]; then
        dunstify -a "changevolume" -i $volume_medium_icon -r $msgId -u low "[$bar$bar_spaces]"
    else
        dunstify -a "changevolume" -i $volume_high_icon -r $msgId -u low "[$bar$bar_spaces]"
    fi
fi
