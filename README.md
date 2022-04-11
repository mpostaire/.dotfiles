# dotfiles

My dotfiles.

See awesomewm instructions [here](awesome/.config/awesome/README.md).

## Installation

```bash
# 1. Install GNU stow using a package manager
# 2. Clone this repo inside the $HOME directory
git clone https://github.com/mpostaire/dotfiles.git
# 3. cd inside
cd dotfiles
# 4. Use stow to install them
# Examples:
# Install all the dotfiles (the '*/' matches any directory)
stow */
# Install only shell, defaultapps and gtk-bookmarks dotfiles
stow shell defaultapps gtk-bookmarks
# Read the stow manpage for more info
```
