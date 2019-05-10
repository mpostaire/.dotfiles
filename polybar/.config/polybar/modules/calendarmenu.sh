#!/bin/bash

datepid=~/.config/polybar/modules/datepid

green=$(xrdb -query | grep "color2" | head -n1 | awk '{print $NF}')
blue=$(xrdb -query | grep "color4" | head -n1 | awk '{print $NF}')

calendar=$(~/.config/polybar/modules/calendar $green $blue)

echo "$calendar" | rofi -dmenu -theme calendarmenu -markup-rows -scroll-method 0 > /dev/null

kill -USR1 $(cat $datepid)