local awful = require("awful")
local variables = require("configuration.variables")
local beautiful = require("beautiful")
local hotkeys_popup = require("awful.hotkeys_popup")

local submenu = {
    { "hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
    { "manual", variables.terminal .. " -e man awesome" },
    { "edit config", variables.editor_cmd .. " " .. awesome.conffile },
    { "restart", awesome.restart },
    { "quit", function() awesome.quit() end },
}

local mainmenu = awful.menu(
    {
        items = {
            { "awesome", submenu, beautiful.awesome_icon },
            { "open terminal", variables.terminal }
        }
    }
)

return mainmenu
