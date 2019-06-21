local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")

-- TODO: change this by my own implementation of a menu that can change
-- its icon dynamically and can interact with a specific client easily
local menu_target_client
local right_click_menu = awful.menu(
    {
        items = {
            { "close", function() menu_target_client:kill() end, beautiful.titlebar_close_button_normal },
            { "maximize", function() menu_target_client.maximized = not menu_target_client.maximized end, beautiful.titlebar_maximized_button_normal_inactive },
            { "minimize", function() menu_target_client.minimized = not menu_target_client.minimized end, beautiful.titlebar_minimize_button_normal },
            { "floating", function() menu_target_client.floating = not menu_target_client.floating end, beautiful.titlebar_floating_button_normal_inactive },
            { "ontop", function() menu_target_client.ontop = not menu_target_client.ontop end, beautiful.titlebar_ontop_button_normal_inactive },
            { "sticky", function() menu_target_client.sticky = not menu_target_client.sticky end, beautiful.titlebar_sticky_button_normal_inactive },
        }
    }
)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            menu_target_client = c
            right_click_menu:toggle()
        end)
    )

    awful.titlebar(c):setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            -- awful.titlebar.widget.floatingbutton (c),
            -- awful.titlebar.widget.stickybutton   (c),
            -- awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.minimizebutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)
