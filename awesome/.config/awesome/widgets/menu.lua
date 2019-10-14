local awful = require("awful")
local variables = require("config.variables")
local beautiful = require("beautiful")
local hotkeys_popup = require("awful.hotkeys_popup")
local gears = require("gears")
local capi = {awesome = awesome, root = root}

-- TODO: close when click outside

local submenu = {
    { "hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
    { "documentation", function()
        awful.spawn.easy_async(variables.browser .. " https://awesomewm.org/doc/api/", function() end)
        local screen = awful.screen.focused()
        local tag = screen.tags[2] -- TODO: automatic tag detection
        if tag then
           tag:view_only()
        end
    end },
    { "edit config", variables.gui_editor .. " " .. variables.home .. "/dotfiles" },
    { "restart", capi.awesome.restart },
    { "quit", capi.awesome.quit },
}

local mainmenu = awful.menu(
    {
        items = {
            { "awesome", submenu, beautiful.awesome_icon },
            { "open terminal", variables.terminal }
        }
    }
)

capi.root.buttons(gears.table.join(capi.root.buttons(), awful.button({ }, 3, function () mainmenu:toggle() end)))

return mainmenu
