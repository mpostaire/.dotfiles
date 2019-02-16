#!/bin/bash

MENU="$(rofi -sep "|" -dmenu -i -theme powermenu -p 'Système' \
        <<< " Verrouiller| Déconnexion| Mettre en veille| Redémarrer| Éteindre")"
case "$MENU" in
    *Verrouiller) ~/.scripts/lock.sh;;
    *Déconnexion) bspc quit;;
    *Mettre\ en\ veille) systemctl suspend;;
    *Redémarrer) systemctl reboot;;
    *Éteindre) systemctl -i poweroff
esac
