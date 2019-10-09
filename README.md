# dotfiles

My dotfiles.

## Installation

requires awesomewm 4.3+, [mpdbus](https://github.com/mpostaire/mpdbus), [awdctl](https://github.com/mpostaire/awdctl), rofi, networkmanager_dmenu, mpd, i3lock-color, compton and zsh

TODO

## Screenshots

TODO

## TODO

### high priority
- make mediakeys, etc work when popups like music player, calendar, etc

- notification when usb plugged/unplugged

- handle proxy lost connection

- network menu

- clipboard so when a program is closed the content copied inside it is still useable

- only one popup instance for each widget having a popup

- make a popup subclass wich make clicking outside hide itself
- --> place all widgets inside a container widget. if its width is too high, collapse (windows xp or windows 10 style) or make widgets without labels / with toggleable labels, or instead of width, show only x widgets and all n > x widgets are hidden tray icons count for 1 widget, then move music widget to the right area of the wibar

### low priority

- Better Readme
- Add cursor, icons and gtk theme (remake gtk colors so the are more like my color scheme).
- Better install script.

- make calendar days clickable + linked to a calendar app (maybe: make calendar widget side panel with events for the day + notifs like gnome calendar)

- music player: find cover in folder first, then find it from the file (the latter cost more performances)

- bluetooth widget

- replace client borders by titlebars (not necessary but titlebar can have widgets)

- autoupdate script (with popups ?)

- popup_menu uses a lot of cpu when updating an item

- script that git pull zsh plugins when necessary (take inspiration from this [link](https://github.com/TamCore/autoupdate-oh-my-zsh-plugins/blob/master/autoupdate.plugin.zsh))

- remove dbus_proxy, awdctl and mpdbus dependencies if possible.
