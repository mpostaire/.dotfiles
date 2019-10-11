-- this should look like the kde plasma 5 container for widget at the end
local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")

local group = {}
group.__index = group

function group:new(children)
    local g = wibox.layout.fixed.horizontal()
    setmetatable(g, group)

    local panel_children, control_children = {}, {}

    for _,v in pairs(children) do
        if v.type == "panel_widget" then
            panel_children[#panel_children + 1] = v
        elseif v.type == "control_widget" then
            control_children[#control_children + 1] = v
        end
    end

    g.control_widgets = wibox.layout.fixed.vertical()
    g.control_widgets.spacing = 8

    for _,v in ipairs(panel_children) do
        v:set_popup_enabled(false)
        v:enable_mouse_hover_effects(true, false)
        g:add(v)
        if v.control_widget then
            g.control_widgets:add(v.control_widget)
        end
    end

    for _,v in ipairs(control_children) do
        g.control_widgets:add(v)
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

    g:connect_signal("mouse::enter", function()
        for _,v in pairs(panel_children) do
            v:highlight(true)
        end
    end)

    g:connect_signal("mouse::leave", function()
        for _,v in pairs(panel_children) do
            v:highlight(false)
        end
    end)

    g:buttons(gears.table.join(
        awful.button({}, 1, function() g.popup.visible = not g.popup.visible end)
    ))

    return g
end

return group
