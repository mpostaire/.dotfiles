#!/bin/bash

usage() {
    echo "Usage:
    -g           get volume in percents
    -p           print volume in polybar formatting.
    -i VALUE     increase volume by VALUE percents.
    -d VALUE     decrease volume by VALUE percents.
    -s VALUE     set brightvolumeness by VALUE percents. Mute/unmute if VALUE is 'toggle'
    -h           show this help message." 1>&2
    exit 1
}

show_notification() {
    # Arbitrary but unique message id
    msgId="991049"
    volume=$(get_volume)
    mute=$(amixer -c 0 get Master | tail -1 | awk '{print $6}' | sed 's/[^a-z]*//g')
    # Icons
    volume_muted_icon=/usr/share/icons/Papirus-Dark/symbolic/status/audio-volume-muted-symbolic.svg
    volume_low_icon=/usr/share/icons/Papirus-Dark/symbolic/status/audio-volume-low-symbolic.svg
    volume_medium_icon=/usr/share/icons/Papirus-Dark/symbolic/status/audio-volume-medium-symbolic.svg
    volume_high_icon=/usr/share/icons/Papirus-Dark/symbolic/status/audio-volume-high-symbolic.svg

    # Show the volume notification
    bar=$(seq -s "=" $(($volume / 5)) | sed 's/[0-9]//g')
    # ugly but I can't use sed :(
    bar_spaces=$(seq -s " " $(( 20 - ${#bar})) | sed 's/[0-9]//g')
    if [[ $volume == 0 || $mute == "off" ]]; then
        # Show the sound muted notification
        dunstify -a "changeVolume" -u low -i $volume_muted_icon -r $msgId "Volume muted         " 
    else
        if [[ $volume -le 20 ]]; then
            dunstify -a "changevolume" -i $volume_low_icon -r $msgId -u low "[$bar$bar_spaces]"
        elif [[ $volume -le 50 ]]; then
            dunstify -a "changevolume" -i $volume_medium_icon -r $msgId -u low "[$bar$bar_spaces]"
        else
            dunstify -a "changevolume" -i $volume_high_icon -r $msgId -u low "[$bar$bar_spaces]"
        fi
    fi

    # update all polybars with my custom volume module
    echo hook:module/volume1 >> /tmp/ipc-polybar*
}

get_volume() {
    awk -F"[][]" '/dB/ { print $2 }' <(amixer sget Master) | tr -d %
}

polybar_format() {
    mute=$(amixer -c 0 get Master | tail -1 | awk '{print $6}' | sed 's/[^a-z]*//g')
    volume=$(get_volume)
    if [[ $volume -eq 0 || $mute == "off" ]]; then
        white_alt=$(xrdb -query | grep "color15" | head -n1 | awk '{print $NF}')
        echo "%{F${white_alt}} $volume%%{F-}"
    else
        echo " $volume%"
    fi
}

inc_volume() {
    amixer -q sset 'Master' ${1}%+ unmute
    show_notification
}

dec_volume() {
    amixer -q sset 'Master' ${1}%- unmute
    show_notification
}

set_volume() {
    if [ "$1" == "toggle" ]; then
        if [ $(get_volume) == 0 ]; then
            amixer -q sset 'Master' 10% unmute
        else
            amixer -q sset 'Master' ${1}
        fi
    else
        amixer -q sset 'Master' ${1}%
    fi
    show_notification
}

while getopts "hgi:d:s:p" arg; do
    case $arg in
        g)
            get_volume
            ;;
        i)
            inc_volume $OPTARG
            ;;
        d)
            dec_volume $OPTARG
            ;;
        s)
            set_volume $OPTARG
            ;;
        p)
            polybar_format $OPTARG
            ;;
        h | *)
            usage
            ;;
    esac
done
