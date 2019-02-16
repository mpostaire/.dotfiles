#!/bin/bash

min=10

usage() {
    echo "Usage:
    -g           get brightness in percents
    -p           print volume in polybar formatting.
    -i VALUE     increase brightness by VALUE percents.
    -d VALUE     decrease brightness by VALUE percents.
    -s VALUE     set brightness by VALUE percents.
    -h           show this help message." 1>&2
    exit 1
}

show_notification() {
    # Arbitrary but unique message id
    msgId="940199"
    brightness=$(get_brightness)
    brightness_icon=/usr/share/icons/Papirus-Dark/symbolic/status/display-brightness-medium-symbolic.svg

    # Show the volume notification
    bar=$(seq -s "=" $(($brightness / 5)) | sed 's/[0-9]//g')
    # ugly but I can't use sed :(
    bar_spaces=$(seq -s " " $(( 20 - ${#bar})) | sed 's/[0-9]//g')
    dunstify -a "changebrightness" -i $brightness_icon -r "$msgId" -u low "[$bar$bar_spaces]"

    # update all polybars with my custom brightness module
    echo hook:module/brightness1 >> /tmp/ipc-polybar*
}

get_brightness() {
    echo $(($(brightnessctl g) * 100 / $(brightnessctl m)))
}

polybar_format() {    
    echo " $(($(brightnessctl g) * 100 / $(brightnessctl m)))%"
}

inc_brightness() {
    brightnessctl -q s ${1}%+
    show_notification
}

dec_brightness() {
    # if new brightness value is greater than min, apply new brightness else set it to min
    if [ $(($(get_brightness)-$1)) -gt $min ]; then
        brightnessctl -q s ${1}%-
    else
        brightnessctl -q s ${min}%
    fi
    show_notification
}

set_brightness() {
    # if new brightness value is greater than min, apply new brightness else set it to min
    if [ $1 -gt $min ]; then
        brightnessctl -q s ${1}%
    else
        brightnessctl -q s ${min}%
    fi
    show_notification
}

while getopts "hgi:d:s:p" arg; do
    case $arg in
        g)
            get_brightness
            ;;
        i)
            inc_brightness $OPTARG
            ;;
        d)
            dec_brightness $OPTARG
            ;;
        s)
            set_brightness $OPTARG
            ;;
        p)
            polybar_format $OPTARG
            ;;
        h | *)
            usage
            ;;
    esac
done

#shift $((OPTIND-1))
