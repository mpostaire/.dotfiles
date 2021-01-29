local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local backlight = require("util.backlight")
local helpers = require("util.helpers")

local icon = ""

return function(width)
    if backlight.read_only then return end

    local slider_width = width or 150
    -- we convert brightness value from [backlight.min_brightness,100] to [0,100] interval
    local brightness_value = ((backlight.brightness - backlight.min_brightness) / (100 - backlight.min_brightness)) * 100
    
    local brightness_slider = wibox.widget {
        bar_active_color = beautiful.fg_normal,
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

    local widget = wibox.widget {
        {
            {
                markup = icon,
                font = helpers.change_font_size(beautiful.icon_font, 16),
                widget = wibox.widget.textbox
            },
            right = 8,
            widget = wibox.container.margin
        },
        brightness_slider,
        nil,
        layout = wibox.layout.align.horizontal
    }

    local brightness_updating_value = false
    local mouse_updating_value = false
    brightness_slider:connect_signal("property::value", function()
        -- if we are updating brightness_slider.value because brightness changed we do not want to change it again to prevent loops
        if brightness_updating_value then
            brightness_updating_value = false
            return
        else
            mouse_updating_value = true
            -- brightness_slider.value is changed to fit in the [backlight.min_brightness,100] interval
            backlight.set(((brightness_slider.value / 100) * (100 - backlight.min_brightness)) + backlight.min_brightness)
        end
    end)

    brightness_slider:buttons({
        awful.button({}, 4, function()
            backlight.increase(5)
        end),
        awful.button({}, 5, function()
            backlight.decrease(5)
        end)
    })

    widget.type = "control_widget"

    backlight.on_changed(function()
        if mouse_updating_value then
            mouse_updating_value = false
            return
        end
        brightness_updating_value = true
        brightness_slider.value = ((backlight.brightness - backlight.min_brightness) / (100 - backlight.min_brightness)) * 100
    end)

    return widget
end
