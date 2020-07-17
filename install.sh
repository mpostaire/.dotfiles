yay -S rxvt-unicode-better-wheel-scrolling picom i3lock-color urxv-perls vte3 evince-light suru-icon-theme-git xfce4-screenshooter xss-lock systemd-numlockontty

cd ~/dotfiles
stow */

systemctl enable --user redshift.service
systemctl start --user redshift.service

systemctl enable numLockOnTty.service
systemctl start numLockOnTty.service
