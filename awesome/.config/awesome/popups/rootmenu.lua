local awful = require("awful")
local wibox = require("wibox")
local menu = require("popups.menu")
local variables = require("config.variables")
local beautiful = require("beautiful")
local hotkeys_popup = require("awful.hotkeys_popup")

local submenu = {
    { "_hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
    { "_documentation", function()
        awful.spawn.easy_async(variables.browser .. " https://awesomewm.org/apidoc/", function() end)
        local screen = awful.screen.focused()
        local tag = screen.tags[2] -- TODO: automatic tag detection
        if tag then
           tag:view_only()
        end
    end },
    { "edit _config", function()
        awful.spawn.easy_async(variables.gui_editor .. " " .. variables.home .. "/dotfiles", function() end)
    end },
    { "_restart", _G.awesome.restart },
    { "_quit", function()
        _G.awesome.quit()
    end },
}

local mainmenu = menu {
    { "_awesome", submenu, beautiful.awesome_icon },
    { "open _terminal", function()
        awful.spawn.easy_async(variables.terminal, function() end)
    end }
}

return mainmenu
