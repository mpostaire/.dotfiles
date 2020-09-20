local wibox = require("wibox")
local dpi = require("beautiful").xresources.apply_dpi
local helpers = require("util.helpers")
local systray = require("util.systray")

return function(include_legacy_systray)
    local item_container = wibox.widget {
        layout = wibox.layout.fixed.horizontal
    }

    local widget = wibox.widget {
        {
            {
                include_legacy_systray and wibox.widget.systray() or nil, -- legacy
                item_container,
                spacing = dpi(4),
                layout = wibox.layout.fixed.horizontal
            },
            widget = wibox.container.background
        },
        top = dpi(4),
        bottom = dpi(4),
        widget = wibox.container.margin
    }

    local index = 0
    local id_index = {}

    systray.on_sni_added(function(sni)
        local icon = helpers.get_icon(sni._private.proxy.IconName, sni._private.proxy.IconThemePath)
        local icon_widget = wibox.widget {
            image = icon,
            widget = wibox.widget.imagebox
        }
        local item = wibox.widget {
            icon_widget,
            left = dpi(6),
            right = dpi(6),
            widget = wibox.container.margin
        }

        helpers.change_cursor_on_hover(item, "hand2")

        item_container:add(item)
        index = index + 1
        id_index[sni.id] = index

        sni.on_icon_changed(function(icon)
            icon_widget.image = helpers.get_icon(icon, sni._private.proxy.IconThemePath)
        end)
    end)

    systray.on_sni_removed(function(id)
        table.remove(item_container.children, id_index.id)
        id_index[id] = nil
        index = index - 1
        item_container:emit_signal("widget::layout_changed")
    end)

    return widget
end
