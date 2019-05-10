#!/bin/sh

DATEFTM="${DATEFTM:-+%a. %d. %b. %Y}"
SHORTFMT="${SHORTFMT:-+%d.%m.%Y}"
LABEL="${LABEL:-}"
blockdate=$(date "$DATEFTM")
shortblockdate=$(date "$SHORTFMT")

year=$(date '+%Y')
month=$(date '+%m')
case "$1" in
    1|2)
        date=$(date '+%a %d %b %Y');;
    3)
        (( month == 12 )) && month=1 && year=$((year + 1)) || month=$((month + 1))
        date=$(cal $month $year | sed -n '1s/^  *//;1s/  *$//p')
esac

case "$1" in
    1|2|3)
        days=$(cal | head -n 2 | tail -n 1)
        calendar="$(cal --color=always $month $year \
        | sed 's/\x1b\[[7;]*m/\<b\>\<u\>/g' \
        | sed 's/\x1b\[[27;]*m/\<\/u\>\<\/b\>/g' \
        | tail -n +3)"
        echo "$calendar" | rofi \
        -dmenu \
        -markup-rows \
        -selected-row 0 \
        -theme leclipse \
        -theme-str 'window {location: northeast; width: 28ch; y-offset: 34px;}
                    listview {scrollbar: false; lines: 10;} inputbar {children: [dummy, prompt, dummy];}
                    message {margin: 0 25px -8px 25px;}
                    element selected {background-color: @black;} element selected normal {text-color: @white;}' \
        -no-custom \
        -mesg "$days" \
        -p "$date" > /dev/null
esac

kill -USR1 $2