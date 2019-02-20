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
maxstrlen=22
music_dir="$HOME/Musique"

find_cover() {
    # find cover in folder. if not generate one from file

    # default cover
    cover="~/.config/polybar/modules/default_cover.png"
    out_dir="/tmp"
    song_dir="$music_dir/$(mpc current -f %file%)"

    out_file="$out_dir/$(mpc current -f %album%).png"

    if [ ! -f "$out_file" ]; then
        ffmpeg -hide_banner -loglevel quiet -i "$song_dir" "$out_file" -y > /dev/null

        if [ $? -eq 0 ]; then
            black=$(xrdb -query | grep "color0" | head -n1 | awk '{print $NF}')
            convert "$out_file" -resize 64x64 -background "$black" -gravity center -extent 64x64 "$out_file"
            convert "$out_file" -border 25 -bordercolor white "$out_file"
            cover="$out_file"
        fi
    else
        cover="$out_file"
    fi    

    echo $cover
}

# kill all background processes when this process stops
# useful to stop trying to update rofi if song/state changed when this script is terminated
# trap 'kill $(jobs -p)' SIGKILL SIGINT SIGTERM EXIT

ret=0
while [[ $ret == 0 ]]; do
    if mpc status | awk 'NR==2' | grep playing > /dev/null; then
        artist="$(mpc current -f %artist%)"
        title="$(mpc current -f %title%)"
        playbutton=$pause_icon
    elif mpc status | awk 'NR==2' | grep paused > /dev/null; then
        artist="$(mpc current -f %artist%)"
        title="$(mpc current -f %title%)"
        playbutton=$play_icon
    else
        artist="Pas de lecture en"
        title="cours..."
        playbutton=$play_icon
    fi

    # truncate strings and add '...' if lenght > $maxstrlen
    if [ ${#artist} -gt $maxstrlen ]; then
        artist=$(awk -v n=$maxstrlen -v r='...' 'length > n{$0 = substr($0, 1, n - length(r)) r} {printf "%-" n "s", $0}' <<< $artist)
    fi
    if [ ${#title} -gt $maxstrlen ]; then
        title=$(awk -v n=$maxstrlen -v r='...' 'length > n{$0 = substr($0, 1, n - length(r)) r} {printf "%-" n "s", $0}' <<< $title)
    fi

    # if current song or state changes, reload rofi
    # force_reload varriable is not accessible because it is in a subshell
    # writing it in a temp file instead does not work because its in a background
    # process and so it's not reliable due do racing conditions
    # (mpc idle > /dev/null; killall rofi; force_reload=0) &

    MENU=$(rofi -dmenu -mesg "$artist
$title" -selected-row 1 -fake-background "$(find_cover)" \
    -fake-transparency -scroll-method 0 -sep "|" -theme musicmenu <<< "$prev_icon|$playbutton|$next_icon")
    ret=$?

    case $MENU in
        $prev_icon) mpc prev > /dev/null;;
        $playbutton) mpc toggle > /dev/null;;
        $next_icon) mpc next > /dev/null
    esac
done
