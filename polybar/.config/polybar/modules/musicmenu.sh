#!/bin/bash

# extract cover from music file
#ffmpeg -i file.mp3 file.jpg

# put converted images to /tmp/

# resize image keeping aspect ratio centering it ant filling the gaps with specified color
#convert default_cover.png -resize 64x64 -background red -gravity center -extent 64x64 default_cover.png 

# add border of size 25 whith color white (it always makes a white color ??)
#convert default_cover.png -border 25 -bordercolor white input.jpg output.jpg default_cover.png

play_icon=""
pause_icon=""
prev_icon=""
next_icon=""

find_cover() {
    cover="~/.config/polybar/modules/default_cover.png"
    echo $cover
}

ret=0
while [ $ret -eq 0 ]; do
    if mpc status | awk 'NR==2' | grep playing > /dev/null; then
        artist="$(mpc status | head -1 | cut -d '-' -f1)"
        title="$(mpc status | head -1 | cut -d '-' -f2 | tail -c +2)"
        playbutton=$pause_icon
    elif mpc status | awk 'NR==2' | grep paused > /dev/null; then
        artist="$(mpc status | head -1 | cut -d '-' -f1)"
        title="$(mpc status | head -1 | cut -d '-' -f2 | tail -c +2)"
        playbutton=$play_icon
    else
        artist="Pas de lecture en"
        title="cours..."
        playbutton=$play_icon
    fi

    # truncate strings and add '...' if lenght > $maxstrlen
    maxstrlen=22
    if [ ${#artist} -gt $maxstrlen ]; then
        artist=$(awk -v n=$maxstrlen -v r='...' 'length > n{$0 = substr($0, 1, n - length(r)) r} {printf "%-" n "s", $0}' <<< $artist)
    fi
    if [ ${#title} -gt $maxstrlen ]; then
        title=$(awk -v n=$maxstrlen -v r='...' 'length > n{$0 = substr($0, 1, n - length(r)) r} {printf "%-" n "s", $0}' <<< $title)
    fi

    MENU=$(echo "$prev_icon|$playbutton|$next_icon" | rofi -dmenu -mesg "$artist
$title" -selected-row 1 -fake-background $(find_cover) \
    -fake-transparency -scroll-method 0 -sep "|" -theme musicmenu)
    ret=$?

    case $MENU in
        $prev_icon) mpc prev > /dev/null;;
        $playbutton) mpc toggle > /dev/null;;
        $next_icon) mpc next > /dev/null
    esac
done
