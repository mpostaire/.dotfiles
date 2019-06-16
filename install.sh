cd ~/dotfiles
stow */

touch ~/.config/mpd/pid ~/.config/mpd/state

git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
yay -S networkmanager-dmenu-git #bibata-cursor-theme

# see https://wiki.archlinux.org/index.php/acpid
systemctl start acpid.service
