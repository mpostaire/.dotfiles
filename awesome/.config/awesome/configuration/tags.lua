local awful = require("awful")
-- nice tree layout but useless gaps support works poorly
-- it does not work well with my smart gaps too
-- local treetile = require("treetile")

-- Table of layouts to cover with awful.layout.inc, order matters.
-- some layouts do not work well with my smart gaps but it is easy to fix (ex: make a condition for these layouts)
awful.layout.layouts = {
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    -- treetile,
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