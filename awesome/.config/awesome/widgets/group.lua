-- this should look like the kde plasma 5 container for widget at the end
local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")

local group = {}
group.__index = group

-- TODO: faire que tous les widgets qui ont un control_widget et non présent dans un group puissent
-- faire apparaître un popup contenant leur control widget.
-- Du coup quand ils sont dans un group désactiver leur capacité à faire apparaître leur popup

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

    g.popup_widgets = wibox.layout.fixed.vertical()

    for _,v in ipairs(panel_children) do
        v:set_label_visible(false)
        v:enable_mouse_hover_effects(true, false)
        g:add(v)
        if v.popup_widget then
            g.popup_widgets:add(v.popup_widget)
        end
    end

    for _,v in ipairs(control_children) do
        g.popup_widgets:add(v)
    end

    g.popup = awful.popup {
        widget = {
            {
                g.popup_widgets,
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
