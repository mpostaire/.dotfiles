local awful = require("awful")
local variables = require("config.variables")
local beautiful = require("beautiful")
local hotkeys_popup = require("awful.hotkeys_popup")
-- local popup_menu = require("util.popup_menu")
local gears = require("gears")

local submenu = {
    { "hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
    { "manual", variables.terminal .. " -e man awesome" },
    { "edit config", variables.editor_cmd .. " " .. awesome.conffile },
    { "restart", awesome.restart },
    { "quit", awesome.quit },
}

local mainmenu = awful.menu(
    {
        items = {
            { "awesome", submenu, beautiful.awesome_icon },
            { "open terminal", variables.terminal }
        }
    }
)

-- local mainmenu = popup_menu:new(
--     {
--         {
--             text = "awesome",
--             cmd = {
--                 {
--                     text = "hotkeys",
--                     cmd = function() hotkeys_popup.show_help(nil, awful.screen.focused()) end
--                 },
--                 {
--                     text = "manual",
--                     cmd = variables.terminal .. " -e man awesome"
--                 },
--                 {
--                     text = "edit config",
--                     cmd = variables.editor_cmd .. " " .. awesome.conffile
--                 },
--                 {
--                     text = "restart",
--                     cmd = awesome.restart
--                 },
--                 {
--                     text = "quit",
--                     cmd = awesome.quit
--                 },
--             },
--             icons = { beautiful.awesome_icon }
--         },
--         {
--             text = "open terminal",
--             cmd = variables.terminal
--         }
--     }
-- )

root.buttons(gears.table.join(root.buttons(), awful.button({ }, 3, function () mainmenu:toggle() end)))

return mainmenu
