local awful = require("awful")

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    -- awful.layout.suit.tile.left,
    -- awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    -- awful.layout.suit.fair,
    -- awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    -- awful.layout.suit.max,
    -- awful.layout.suit.max.fullscreen,
    -- awful.layout.suit.magnifier,
    -- awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}

local layouts = awful.layout.layouts
local tags = {
    names  = { "1", "2", "3", "4", "5", "6" },
    layout = { layouts[2], layouts[2], layouts[2], layouts[2], layouts[2], layouts[2] }
}

awful.screen.connect_for_each_screen(function(s)
    -- Each screen has its own tag table.
    awful.tag(tags.names, s, tags.layout)
end)