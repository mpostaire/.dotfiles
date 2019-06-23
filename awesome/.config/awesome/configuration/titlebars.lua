local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")
local popup_menu = require("util.popup_menu")

-- todo: make this have dynamic icons and text and implement tag switch
-- make tag names icons be the icon of the layout

local menu_target_client
local function make_tag_menu()
    local tags = awful.screen.focused().tags
    local menu = {}
    for k,v in ipairs(tags) do
        menu[k] = {
            text = v.name,
            cmd = function() menu_target_client:move_to_tag(v) end
        }
    end
    return menu
end

local right_click_menu = popup_menu:new(
    {
        {
            icon = beautiful.titlebar_close_button_normal,
            text = "close",
            cmd = function() menu_target_client:kill() end
        },
        {
            icon = beautiful.titlebar_maximized_button_normal_inactive,
            text = "maximize",
            cmd = function() menu_target_client.maximized = not menu_target_client.maximized end
        },
        {
            icon = beautiful.titlebar_minimize_button_normal,
            text = "minimize",
            cmd = function() menu_target_client.minimized = not menu_target_client.minimized end
        },
        {
            icon = beautiful.titlebar_floating_button_normal_inactive,
            text = "floating",
            cmd = function() menu_target_client.floating = not menu_target_client.floating end
        },
        {
            icon = beautiful.titlebar_ontop_button_normal_inactive,
            text = "ontop",
            cmd = function() menu_target_client.ontop = not menu_target_client.ontop end
        },
        {
            icon = beautiful.titlebar_sticky_button_normal_inactive,
            text = "sticky",
            cmd = function() menu_target_client.sticky = not menu_target_client.sticky end
        },
        {
            text = "move to tag",
            cmd = make_tag_menu()
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
