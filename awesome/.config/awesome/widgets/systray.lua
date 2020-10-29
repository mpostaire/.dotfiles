local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local helpers = require("util.helpers")
local systray = require("util.systray")

-- TODO make this and util version of this widget functions inside local variables and then put them in callbacks args
--      so Lua does not need to parse them every time

return function(include_legacy_systray)
    local item_container = wibox.widget {
        layout = wibox.layout.fixed.horizontal
    }

    local legacy_tray
    if include_legacy_systray then
        legacy_tray = wibox.widget {
            wibox.widget.systray() or nil,
            top = dpi(4),
            bottom = dpi(4),
            widget = wibox.container.margin
        }
    end

    local widget = wibox.widget {
        {
            legacy_tray,
            item_container,
            spacing = beautiful.systray_icon_spacing and beautiful.systray_icon_spacing / 2 or dpi(6),
            layout = wibox.layout.fixed.horizontal
        },
        widget = wibox.container.background
    }

    local index = 0
    local id_index = {}

    local menu
    local background = wibox {
        x = 0,
        y = 0,
        width = _G.mouse.screen.geometry.width,
        height = _G.mouse.screen.geometry.height,
        opacity = 0,
        visible = false,
        ontop = true,
        type = 'normal'
    }
    background:connect_signal("button::press", function()
        background.visible = false
        menu:hide()
    end)

    systray.on_sni_added(function(sni)
        local icon_widget = wibox.widget {
            image = helpers.get_icon(sni.icon, sni.icon_theme),
            widget = wibox.widget.imagebox
        }
        local item = wibox.widget {
            {
                icon_widget,
                top = dpi(4),
                bottom = dpi(4),
                widget = wibox.container.margin
            },
            left = beautiful.systray_icon_spacing and beautiful.systray_icon_spacing / 2 or dpi(6),
            right = beautiful.systray_icon_spacing and beautiful.systray_icon_spacing / 2 or dpi(6),
            widget = wibox.container.margin
        }

        -- scroll deltas are arbitrarily set to 32 cause I don't know of a way to get them
        item:buttons {
            awful.button({}, 1, function(arg)
                sni.activate(arg.x, arg.y)
            end),
            awful.button({}, 2, function()
                local coords = mouse.coords()
                sni.secondary_activate(coords.x, coords.y)
            end),
            awful.button({}, 4, function()
                sni.scroll(-32, "vertical")
            end),
            awful.button({}, 5, function()
                sni.scroll(32, "vertical")
            end),
            awful.button({}, 6, function()
                sni.scroll(-32, "horizontal")
            end),
            awful.button({}, 7, function()
                sni.scroll(32, "horizontal")
            end)
        }

        helpers.change_cursor_on_hover(item, "hand2")

        item_container:add(item)
        index = index + 1
        id_index[sni.id] = index

        sni.on_new_icon(function(icon)
            icon_widget.image = icon
        end)

        sni.on_new_status(function(status)
            item.visible = status
        end)
        
        sni.on_show_menu(function(menu_items, x, y)
            if menu then menu:hide() end
            menu = awful.menu { items = menu_items }
            background.visible = true

            -- TODO menu select none when mouse leave menu
            menu:show { coords = { x = x, y = y } }

            -- TODO this is a temporary way to enable autohide on click outside
            menu:get_root().wibox:connect_signal("property::visible", function()
                background.visible = menu:get_root().wibox.visible
            end)
        end)
    end)

    local dump = require("gears.debug").dump

    systray.on_sni_removed(function(id)
        item_container.children[id_index[id]] = nil
        id_index[id] = nil
        index = index - 1
        item_container:emit_signal("widget::layout_changed")
    end)

    return widget
end
