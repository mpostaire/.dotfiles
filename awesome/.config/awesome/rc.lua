-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

require("awful.autofocus") -- when a client is closed, another client will be focused

-- error handling
require("util.error_handling")

-- Themes define colours, icons, font and wallpapers.
-- do not place this line below
require("beautiful").init(require("themes.xresources-red"))

-- configuration
require("config")

-- app switcher (alt+tab)
require("popups.app_switcher")

-- collision (TODO make my own simplified version)
-- require("collision")()
