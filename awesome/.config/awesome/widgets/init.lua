require("widgets.taglist")
require("widgets.tasklist")
require("widgets.layoutbox")

-- TODO: detect if watcher is online, if not use non dbus widget for brightness and volume

return {
    -- TODO: when clicking on one of these widgets, close any potential popup from another widget
    -- (show only one popup at a time)
    clock = require("widgets.clock"),
    battery = require("widgets.battery-dbus"),
    archupdates = require("widgets.archupdates"),
    -- volume = require("widgets.volume"),
    volume = require("widgets.volume-dbus"),
    -- brightness = require("widgets.brightness"),
    brightness = require("widgets.brightness-dbus"),
    network = require("widgets.network-dbus"),
    music = require("widgets.music"),
    launcher = require("widgets.launcher"),
    menu = require("widgets.menu")
}
