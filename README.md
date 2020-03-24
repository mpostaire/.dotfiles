# dotfiles

My dotfiles.

## Installation

requires awesomewm 4.3+, [mpdbus](https://github.com/mpostaire/mpdbus), [awdctl](https://github.com/mpostaire/awdctl), mpd, i3lock-color, picom and zsh

TODO

## Screenshots

TODO

## TODO

### high priority
- try a global background wibox for click outside events (have one wibox for all instances where we want click outside detection)

- each reload, floating clients lose height equivalent to their title bar height

- toggle show popup controls and keygrabber inside control_widgets except if it is in a group

- make mediakeys, etc work when popups like music player, calendar, etc

- notification when usb plugged/unplugged

- handle dbus proxy lost connection

- network menu

- clipboard so when a program is closed the content copied inside it is still useable

- only one popup instance for each widget having a popup (make another group widget but with only this condition ?)

### low priority

- Better Readme
- Add cursor, icons and gtk theme (remake gtk colors so the are more like my color scheme).
- Better install script.
- make calendar days clickable + linked to a calendar app (maybe: make calendar widget side panel with events for the day + notifs like gnome calendar)
- music player: find cover in folder first, then find it from the file (the latter cost more performances)

- bluetooth widget

- autoupdate script (with popups ?)

- script that git pull zsh plugins when necessary (take inspiration from this [link](https://github.com/TamCore/autoupdate-oh-my-zsh-plugins/blob/master/autoupdate.plugin.zsh))
