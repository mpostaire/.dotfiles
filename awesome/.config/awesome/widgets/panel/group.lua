-- this should look like the kde plasma 5 container for widget at the end
local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local helpers = require("util.helpers")
local autoclose_popup = require("util.autoclose_popup")
local capi = {mouse = mouse}

local popup_spawn_button = 1

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
                local index = #control_children + 1
                control_children[index] = v.control_widget
                v.control_widget.index = index
                if not v.control_widget.group then v.control_widget.group = "other" end
                v.control_widget.parent = g
            end
        elseif v.type == "control_widget" then
            local index = #control_children + 1
            control_children[index] = v
            v.index = index
            if not v.group then v.group = "other" end
        end
    end

    local separator = wibox.widget {
        color = beautiful.black_alt,
        span_ratio = 0.9,
        orientation = "horizontal",
        forced_width = 0, -- force separator to adapt its width to the popup width
        forced_height = 25,
        thickness = 1,
        widget = wibox.widget.separator
    }
    local last_group
    for _,v in ipairs(control_children) do
        if last_group and last_group ~= v.group then
            g.control_widgets:add(separator)
        end
        g.control_widgets:add(v)
        last_group = v.group
    end

    g.control_popup = autoclose_popup {
        widget = {
            {
                g.control_widgets,
                margins = beautiful.notification_margin,
                widget = wibox.container.margin
            },
            color = beautiful.border_normal,
            left = beautiful.border_width,
            right = beautiful.border_width,
            bottom = beautiful.border_width,
            widget = wibox.container.margin
        },
        ontop = true,
        spawn_button = popup_spawn_button
    }

    local old_cursor, old_wibox = nil, nil

    g:connect_signal("mouse::enter", function()
        for _,v in pairs(panel_children) do
            v:highlight(true)
        end

        local w = capi.mouse.current_wibox
        old_cursor, old_wibox = w.cursor, w
        w.cursor = "hand2"
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

    function g.show_popup()
        local geo = helpers.get_widget_geometry(g)
        local screen_geo = awful.screen.focused().geometry

        if geo.x + g.control_popup.width > screen_geo.width then
            geo.x = screen_geo.width - g.control_popup.width + beautiful.border_width
        end

        g.control_popup.x = geo.x
        g.control_popup.y = geo.y + beautiful.wibar_height - beautiful.border_width

        for _,v in pairs(control_children) do
            if v.show_callback then
                v.show_callback()
            end
        end

        g.control_popup.visible = true
    end

    function g.toggle_popup()
        if g.control_popup.visible then
            g.control_popup.visible = not g.control_popup.visible
        else
            g.show_popup()
        end
    end

    g:buttons(gears.table.join(
        awful.button({}, popup_spawn_button, g.toggle_popup)
    ))

    -- we hide it this way because we want it to be visible by default to calculate its position
    g.control_popup.visible = false

    return g
end
