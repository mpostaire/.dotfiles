-- this should look like the kde plasma 5 container for widget at the end
local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local capi = {mouse = mouse}

return function(children)
    local g = wibox.layout.fixed.horizontal()

    g.control_widgets = wibox.layout.fixed.vertical()
    g.control_widgets.spacing = 8

    local panel_children, control_children = {}, {}

    for _,v in pairs(children) do
        if v.type == "panel_widget" then
            panel_children[#panel_children + 1] = v
            v:set_popup_enabled(false)
            v:set_mouse_effects(false)
            g:add(v)
            if v.control_widget then
                g.control_widgets:add(v.control_widget)
            end
        elseif v.type == "control_widget" then
            control_children[#control_children + 1] = v
            g.control_widgets:add(v)
        end
    end

    g.popup = awful.popup {
        widget = {
            {
                g.control_widgets,
                margins = beautiful.notification_margin,
                widget = wibox.container.margin
            },
            color = beautiful.border_normal,
            left = beautiful.border_width,
            bottom = beautiful.border_width,
            widget = wibox.container.margin
        },
        placement = function(d, args)
            awful.placement.top_right(d, args)
            d.y = d.y + beautiful.wibar_height - beautiful.border_width
        end,
        visible = false,
        ontop = true
    }

    local old_cursor, old_wibox = nil, nil

    g:connect_signal("mouse::enter", function()
        for _,v in pairs(panel_children) do
            v:highlight(true)
        end

        local w = capi.mouse.current_wibox
        old_cursor, old_wibox = w.cursor, w
        w.cursor = "hand1"
    end)

    g:connect_signal("mouse::leave", function()
        for _,v in pairs(panel_children) do
            v:highlight(false)
        end

        if old_wibox then
            old_wibox.cursor = old_cursor
            old_wibox = nil
        end
    end)

    g:buttons(gears.table.join(
        awful.button({}, 1, function() g.popup.visible = not g.popup.visible end)
    ))

    return g
end
