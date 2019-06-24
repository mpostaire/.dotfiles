local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")
local popup_menu = require("util.popup_menu")

local menu_target_client, right_click_menu
local function make_tag_menu()
    local tags = awful.screen.focused().tags
    local menu = {}

    local layouts_icons = {}
    for _,v in ipairs(awful.layout.layouts) do
        layouts_icons[v.name] = beautiful["layout_".. v.name]
    end

    for k,v in ipairs(tags) do
        menu[k] = {
            icons = layouts_icons,
            current_icon = v.layout.name,
            text = v.name,
            cmd = function() menu_target_client:move_to_tag(v) end,
            create_callback = function() end
        }
    end
    return menu
end

-- update tag layout icon in 'move to tag' submenu on tag layout change
tag.connect_signal("property::layout", function(t)
    local tagmenu = right_click_menu.items[#right_click_menu.items].cmd
    tagmenu.items[t.index].current_icon = t.layout.name
    tagmenu:update_item(t.index, false)
end)

right_click_menu = popup_menu:new(
    {
        {
            icons = {beautiful.titlebar_close_button_normal},
            text = "close",
            cmd = function() menu_target_client:kill() end
        },
        {
            icons = {
                inactive = beautiful.titlebar_maximized_button_normal_inactive,
                active = beautiful.titlebar_maximized_button_normal_active,
            },
            text = "maximize",
            cmd = function(item)
                menu_target_client.maximized = not menu_target_client.maximized
                if menu_target_client.maximized then
                    item.current_icon = 'active'
                    item.text_widget.text = "maximized"
                else
                    item.current_icon = 'inactive'
                    item.text_widget.text = "not maximized"
                end
            end
        },
        {
            icons = {beautiful.titlebar_minimize_button_normal},
            text = "minimize",
            cmd = function() menu_target_client.minimized = not menu_target_client.minimized end
        },
        {
            icons = {
                inactive = beautiful.titlebar_floating_button_normal_inactive,
                active = beautiful.titlebar_floating_button_normal_active
            },
            text = "floating",
            cmd = function(item)
                menu_target_client.floating = not menu_target_client.floating
                if menu_target_client.floating then
                    item.current_icon = 'active'
                    item.text_widget.text = "floating"
                else
                    item.current_icon = 'inactive'
                    item.text_widget.text = "tiled"
                end
            end
        },
        {
            icons = {
                inactive = beautiful.titlebar_ontop_button_normal_inactive,
                active = beautiful.titlebar_ontop_button_normal_active
            },
            text = "ontop",
            cmd = function(item)
                menu_target_client.ontop = not menu_target_client.ontop
                if menu_target_client.ontop then
                    item.current_icon = 'active'
                    item.text_widget.text = "ontop"
                else
                    item.current_icon = 'inactive'
                    item.text_widget.text = "not ontop"
                end
            end
        },
        {
            icons = {
                inactive = beautiful.titlebar_sticky_button_normal_inactive,
                active = beautiful.titlebar_sticky_button_normal_active
            },
            text = "sticky",
            cmd = function(item)
                menu_target_client.sticky = not menu_target_client.sticky
                if menu_target_client.sticky then
                    item.current_icon = 'active'
                    item.text_widget.text = "sticky"
                else
                    item.current_icon = 'inactive'
                    item.text_widget.text = "not sticky"
                end
            end
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
            right_click_menu:hide() -- hide if already showed
            right_click_menu:show() -- show at cursor position
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
