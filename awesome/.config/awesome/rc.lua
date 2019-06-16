-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

require("awful.autofocus") -- dont know what it's for
-- Theme handling library
local beautiful = require("beautiful")

-- error handling
require("configuration.error_handling")

-- variables
-- require("configuration.variables")

-- Themes define colours, icons, font and wallpapers.
-- do not place this line below
beautiful.init(require("themes.theme"))

-- rules
require("configuration.rules")

-- bindings
require("configuration.bindings")

-- tags
require("configuration.tags")

-- panel
require("configuration.panel")

-- signals
require("configuration.signals")

-- app switcher (alt+tab)
require("popups.app_switcher")

-- autostart
require("configuration.autostart")

-- collision (TODO make my own)
-- require("collision")()
