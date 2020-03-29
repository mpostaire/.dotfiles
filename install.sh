yay -S rxvt-unicode-better-wheel-scrolling picom i3lock-color urxv-perls vte3 evince-light suru-icon-theme-git xfce4-screenshooter xss-lock

cd ~/dotfiles
stow */

git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions

systemctl enable --user redshift.service
systemctl start --user redshift.service

touch ~/.config/mpd/pid ~/.config/mpd/state
systemctl enable --user mpd.service
systemctl start --user mpd.service
