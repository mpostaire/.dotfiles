#!/bin/bash

# does not work well when the screen and image have not the same aspect ratio
# tweak 'convert' command options to fix this

if [ -f $1 ] && [ $# -gt 0 ]; then
    feh --bg-fill $1
    convert $1 -resize $(xdpyinfo | awk '/dimensions/{print $2}') -blur 0x0 ~/Images/lockscreen.png
else
    echo "Veuillez entrer un fichier valide."
fi
