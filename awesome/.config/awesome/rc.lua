-- set locale
os.setlocale(os.getenv("LANG"))

-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

local naughty = require("naughty")

-- Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
naughty.connect_signal("request::display_error", function(message, startup)
    naughty.notification {
        urgency = "critical",
        title   = "Oops, an error happened"..(startup and " during startup!" or "!"),
        message = message
    }
end)

-- Handle runtime errors after startup
do
    local in_error = false
    _G.awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notification {
            urgency = "critical",
            title = "Oops, an error happened!",
            text = tostring(err)
        }
        in_error = false
    end)
end

_G.awesome.connect_signal("debug::deprecation", function(hint, see, args)
    naughty.notification {
        urgency = "critical",
        title = "Deprecated warning!",
        text = tostring(hint)
    }
end)

-- when a client is closed, another client will be focused
require("awful.autofocus")

-- Themes define colours, icons, font and wallpapers.
-- do not place this line below
require("beautiful").init(require("themes.xresources"))

-- configuration
require("config")

-- app switcher (alt+tab)
require("popups.appswitcher")

-- TODO make my own simplified version
-- require("collision")()
