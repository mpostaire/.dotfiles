require("widgets.taglist")
require("widgets.tasklist")
require("widgets.layoutbox")

return {
    -- panel widgets
    timedate = require("widgets.panel.timedate"),
    battery = require("widgets.panel.battery"),
    archupdates = require("widgets.panel.archupdates"),
    volume = require("widgets.panel.volume"),
    brightness = require("widgets.panel.brightness"),
    network = require("widgets.panel.network"),
    music = require("widgets.panel.music"),
    launcher = require("widgets.panel.launcher"),

    -- control widgets
    player = require("widgets.controls.player"),

    -- other widgets
    menu = require("widgets.menu"),
    group = require("widgets.group"),
}
