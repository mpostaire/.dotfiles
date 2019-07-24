require("widgets.taglist")
require("widgets.tasklist")
require("widgets.layoutbox")

return {
    -- TODO: when clicking on one of these widgets, close any potential popup from another widget
    -- (show only one popup at a time)
    clock = require("widgets.clock"),
    battery = require("widgets.battery-dbus"),
    archupdates = require("widgets.archupdates"),
    -- volume = require("widgets.volume-dbus"),
    volume = require("widgets.volume"),
    -- brightness = require("widgets.brightness-dbus"),
    brightness = require("widgets.brightness"),
    network = require("widgets.network-dbus"),
    music = require("widgets.music"),
    launcher = require("widgets.launcher"),
    menu = require("widgets.menu")
}
