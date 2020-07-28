yay -S rxvt-unicode picom i3lock-color urxv-perls vte3 evince-light suru-icon-theme-git xfce4-screenshooter xss-lock systemd-numlockontty

cd ~/dotfiles
stow */

systemctl enable --user redshift.service
systemctl start --user redshift.service

systemctl enable numLockOnTty.service
systemctl start numLockOnTty.service

# TODO pam gnome keyring thing to make vscode happy (https://wiki.archlinux.org/index.php/GNOME/Keyring#PAM_method)
