local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local brightness = require("util.brightness")
local helpers = require("util.helpers")

local icon = ""

return function(width)
    local private = {}

    local function build_widget()
        local slider_width = width or 150
        -- we convert brightness value from [10,100] to [0,100] interval
        local brightness_value = ((brightness.brightness - 10) / 90) * 100
    
        private.brightness_slider = wibox.widget {
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
    
        local icon_widget = wibox.widget {
            markup = icon,
            font = helpers.change_font_size(beautiful.icon_font, 16),
            widget = wibox.widget.textbox
        }
        private.widget = wibox.widget {
            {
                icon_widget,
                right = 8,
                widget = wibox.container.margin
            },
            private.brightness_slider,
            nil,
            layout = wibox.layout.align.horizontal
        }
    
        private.brightness_updating_value = false
        private.mouse_updating_value = false
        private.brightness_slider:connect_signal("property::value", function()
            -- if we are updating brightness_slider.value because brightness changed we do not want to change it again to prevent loops
            if private.brightness_updating_value then
                private.brightness_updating_value = false
                return
            else
                private.mouse_updating_value = true
                -- brightness_slider.value is changed to fit in the [10,100] interval
                brightness.set_brightness(((private.brightness_slider.value / 100) * 90) + 10)
            end
        end)

        private.brightness_slider:buttons({
            awful.button({}, 4, function()
                brightness.inc_brightness(5)
            end),
            awful.button({}, 5, function()
                brightness.dec_brightness(5)
            end)
        })

        private.widget.type = "control_widget"
    end

    brightness.on_enabled(function()
        if not private.widget then build_widget() end
        private.widget.visible = brightness.enabled
    end)
    brightness.on_disabled(function()
        private.widget.visible = brightness.enabled
    end)
    brightness.on_properties_changed(function()
        if private.mouse_updating_value then
            private.mouse_updating_value = false
            return
        end
        private.brightness_updating_value = true
        private.brightness_slider.value = ((brightness.brightness - 10) / 90) * 100
    end)

    return private.widget
end
