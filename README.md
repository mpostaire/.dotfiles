# dotfiles

My dotfiles.

## Installation

requires awesomewm 4.3+, [mpdbus](https://github.com/mpostaire/mpdbus), [awdctl](https://github.com/mpostaire/awdctl), rofi, networkmanager_dmenu, mpd, i3lock-color, compton and zsh

TODO

## Screenshots

TODO

## TODO

### high priority
- weather inside calendar

- toggle show popup controls and keygrabber inside control_widgets except if it is in a group

- icon theme handler that can handle both svg icons and icon fonts

- find a way to make sliders in group menu have an adaptative length

- make mediakeys, etc work when popups like music player, calendar, etc

- notification when usb plugged/unplugged

- handle proxy lost connection

- network menu

- clipboard so when a program is closed the content copied inside it is still useable

- only one popup instance for each widget having a popup (make another group widget but with only this condition ?)

--> make a popup subclass wich make clicking outside hide itself

- place all right widgets inside a container widget. if its width is too high, collapse (windows xp/10 style)

### low priority

- Better Readme
- Add cursor, icons and gtk theme (remake gtk colors so the are more like my color scheme).
- Better install script.
- theming system
- make calendar days clickable + linked to a calendar app (maybe: make calendar widget side panel with events for the day + notifs like gnome calendar)
- alternative autoclose_popup (see TODO in util/autoclose_popup.lua)
- music player: find cover in folder first, then find it from the file (the latter cost more performances)

- bluetooth widget

- replace client borders by titlebars (not necessary but titlebar can have widgets)

- autoupdate script (with popups ?)

- popup_menu uses a lot of cpu when updating an item

- script that git pull zsh plugins when necessary (take inspiration from this [link](https://github.com/TamCore/autoupdate-oh-my-zsh-plugins/blob/master/autoupdate.plugin.zsh))
