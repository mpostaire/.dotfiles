#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar
rm /tmp/ipc-polybar*

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch bar(s)
bars=( top )

for elem in ${bars[@]}; do
    polybar $elem &
    ln -s /tmp/polybar_mqueue.$! /tmp/ipc-polybar_$elem
    echo "Bar $elem launched..."
done
