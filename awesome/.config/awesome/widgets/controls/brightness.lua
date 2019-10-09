local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local brightness = require("util.brightness")

local icon = ""

local brightness_widget = {}
brightness_widget.__index = brightness_widget

local function get_slider_color_pattern(value, maximum)
    -- we convert value from [0,100] to [0,slider.forced_width] interval
    value = (value / 100) * maximum

    return gears.color.create_pattern({
        type = "linear",
        from = { value, 0 },
        to = { value + 1, 0 },
        stops = { { 0, beautiful.fg_normal }, { 1, beautiful.bg_focus } }
    })
end

function brightness_widget:new(width)
    local slider_width = width or 150
    -- we convert brightness value from [10,100] to [0,100] interval
    local brightness_value = ((brightness.brightness - 10) / 90) * 100

    local slider = wibox.widget {
        bar_height = 4,
        bar_color = get_slider_color_pattern(brightness_value, slider_width),
        handle_color = beautiful.fg_normal,
        handle_shape = gears.shape.circle,
        handle_border_color = beautiful.fg_normal,
        handle_border_width = 1,
        value = brightness_value,
        maximum = 100,
        forced_width = slider_width,
        forced_height = 4,
        widget = wibox.widget.slider
    }

    local icon_widget = wibox.widget {
        markup = icon,
        font = 'Material Icons 16',
        widget = wibox.widget.textbox
    }
    local widget = wibox.widget {
        icon_widget,
        slider,
        spacing = 8,
        layout = wibox.layout.fixed.horizontal
    }
    setmetatable(widget, brightness_widget)

    widget._private.brightness_updating_value = false
    widget._private.mouse_updating_value = false
    slider:connect_signal("property::value", function()
        slider.bar_color = get_slider_color_pattern(slider.value, slider_width)

        -- if we are updating slider.value because brightness changed we do not want to change it again to prevent loops
        if widget._private.brightness_updating_value then
            widget._private.brightness_updating_value = false
            return
        else
            widget._private.mouse_updating_value = true
            -- slider.value is changed to fit in the [10,100] interval
            brightness.set_brightness(((slider.value / 100) * 90) + 10)
        end
    end)

    brightness.on_properties_changed(function()
        if widget._private.mouse_updating_value then
            widget._private.mouse_updating_value = false
            return
        end
        widget._private.brightness_updating_value = true
        slider.value = ((brightness.brightness - 10) / 90) * 100
    end)

    widget.type = "control_widget"

    return widget
end

return brightness_widget
