cd ~/dotfiles
stow */

git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions

systemctl enable --user redshift.service
systemctl start --user redshift.service

touch ~/.config/mpd/pid ~/.config/mpd/state
systemctl enable --user mpd.service
systemctl start --user mpd.service
