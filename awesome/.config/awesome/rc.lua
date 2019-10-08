-- set locale
os.setlocale('fr_FR.utf8')

-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

local naughty = require("naughty")
local capi = {awesome = awesome}

-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if capi.awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = capi.awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    capi.awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end

-- when a client is closed, another client will be focused
require("awful.autofocus")

-- Themes define colours, icons, font and wallpapers.
-- do not place this line below
require("beautiful").init(require("themes.xresources-red"))

-- configuration
require("config")

-- app switcher (alt+tab)
require("popups.app_switcher")

-- collision (TODO make my own simplified version)
-- require("collision")()
