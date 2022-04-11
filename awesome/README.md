# awesome config

NOTE: I'm not using awesome anymore so this config will not be updated until I decide otherwise.

## Installation

Use GNU stow to install this as explained [here](../README.md).

| Dependency | Usage |
| - | - |
| awesomewm-git | awesomewm version my config is made for. |
| i3lock-color | optional: lock screen. |
| picom | optional: compositor used for window shadows/fading. |
| zsh | optional: shell. |
| redshift | optional: reduces eye strain. |
| clipit | optional: clipboard manager. |

## Screenshots

TODO add screenshots


## TODO

### high priority
- rewrite using lgi or use helpers.dbus_watch_name_or_prefix() on util.geoclue and util.network and corresponding widgets
- notification center
- notification when usb plugged/unplugged
- network menu
- redo alt tab menu
- rewrite base panel widget because it's too complicated + remove panel group widget (no longer needed)

- make music widget more beautiful : big cover with progress underline then below: music controls (add shuffle + repeat) + add tabs to select between multiple players (the active tab is the one that is controlled by keyboard controls)

### low priority
- when something goes in front of an autoclose wibox/popup, it breaks the detection of the mouse leaving, and then the close on click outside does not work
- replace dbus_proxy library by my own with lgi cause this one is too complex for what I'm doing and sometimes buggy (signals). The Variant functions can be reused.
- Better Readme
- redo awesomewm config files structure
- redo awesomewm theme (it needs a little refresh)
- make calendar days clickable + linked to a calendar app (maybe: make calendar widget side panel with events for the day + notifs like gnome calendar)
- bluetooth widget
