-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

require("awful.autofocus") -- when a client is closed, another client will be focused
-- Theme handling library
local beautiful = require("beautiful")

-- error handling
require("configuration.error_handling")

-- Themes define colours, icons, font and wallpapers.
-- do not place this line below
beautiful.init(require("themes.theme"))

-- tags
require("configuration.tags")

-- rules
require("configuration.rules")

-- bindings
require("configuration.bindings")

-- panel
require("configuration.panel")

-- signals
require("configuration.signals")

-- titlebars
require("configuration.titlebars")

-- app switcher (alt+tab)
require("popups.app_switcher")

-- autostart
require("configuration.autostart")

-- collision (TODO make my own)
-- require("collision")()
