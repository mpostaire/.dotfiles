# dotfiles

My dotfiles.

## Installation

| Dependency | Usage |
| - | - |
| awesomewm git | awesomewm version my config is made for. |
| [awdctl](https://github.com/mpostaire/awdctl) | Optional: used for volume and brightness control in my awesomewm config. |
| i3lock-color | optional: lock screen. |
| picom | optional: compositor used for window shadows/fading. |
| zsh | optional: shell. |
| redshift | optional: reduces eye strain. |

Use GNU stow to install dotfiles.

TODO

## Screenshots

TODO

## TODO

### high priority
- make the applauncher keyboard input/scrollable list selection a standalone widget (e.g. to use in networkmanager widget). FIX weird bug

- try a global background wibox for click outside events (have one wibox for all instances where we want click outside detection)

- toggle show popup controls and keygrabber inside control_widgets

- make mediakeys, etc work when popups like music player, calendar, etc

- notification when usb plugged/unplugged

- handle dbus proxy lost connection

- network menu

- clipboard so when a program is closed the content copied inside it is still useable

- redo alt tab menu

### low priority

- Better Readme
- Add cursor, icons and gtk theme (remake gtk colors so the are more like my color scheme).
- Better install script.
- make calendar days clickable + linked to a calendar app (maybe: make calendar widget side panel with events for the day + notifs like gnome calendar)
- music player: find cover in folder first, then find it from the file (the latter cost more performances)

- bluetooth widget
