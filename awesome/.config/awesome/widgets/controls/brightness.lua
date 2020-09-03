local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local color = require("themes.util.color")
local brightness = require("util.brightness")
local helpers = require("util.helpers")
local slider = require("widgets.slider")

local icon = ""

return function(width)
    if not brightness.enabled then return nil end
    
    local slider_width = width or 150
    -- we convert brightness value from [10,100] to [0,100] interval
    local brightness_value = ((brightness.brightness - 10) / 90) * 100

    local brightness_slider = wibox.widget {
        bar_active_color = color.white,
        bar_color = beautiful.bg_focus,
        handle_color = beautiful.fg_normal,
        handle_shape = gears.shape.circle,
        handle_border_color = beautiful.fg_normal,
        handle_width = 14,
        value = brightness_value,
        maximum = 100,
        forced_width = slider_width,
        forced_height = 4,
        bar_height = 4,
        widget = wibox.widget.slider
    }

    local icon_widget = wibox.widget {
        markup = icon,
        font = helpers.change_font_size(beautiful.icon_font, 16),
        widget = wibox.widget.textbox
    }
    local widget = wibox.widget {
        {
            icon_widget,
            right = 8,
            widget = wibox.container.margin
        },
        brightness_slider,
        nil,
        layout = wibox.layout.align.horizontal
    }

    widget._private.brightness_updating_value = false
    widget._private.mouse_updating_value = false
    brightness_slider:connect_signal("property::value", function()
        -- if we are updating brightness_slider.value because brightness changed we do not want to change it again to prevent loops
        if widget._private.brightness_updating_value then
            widget._private.brightness_updating_value = false
            return
        else
            widget._private.mouse_updating_value = true
            -- brightness_slider.value is changed to fit in the [10,100] interval
            brightness.set_brightness(((brightness_slider.value / 100) * 90) + 10)
        end
    end)

    brightness.on_properties_changed(function()
        if widget._private.mouse_updating_value then
            widget._private.mouse_updating_value = false
            return
        end
        widget._private.brightness_updating_value = true
        brightness_slider.value = ((brightness.brightness - 10) / 90) * 100
    end)

    brightness_slider:buttons(gears.table.join(
        awful.button({}, 4, function()
            brightness.inc_brightness(5)
        end),
        awful.button({}, 5, function()
            brightness.dec_brightness(5)
        end)
    ))

    widget.type = "control_widget"

    return widget
end
