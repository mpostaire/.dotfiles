local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local color = require("themes.util.color")
local awful = require("awful")
local pulseaudio = require("util.pulseaudio")
local helpers = require("util.helpers")

local icons = {
    low = "",
    medium = "",
    high = "",
    muted = ""
}

local function get_icon()
    if pulseaudio.muted then
        return '<span foreground="'..color.black_alt..'">'..icons.muted..'</span>'
    else
        if pulseaudio.volume < 33 then
            return icons.low
        elseif pulseaudio.volume < 66 then
            return icons.medium
        else
            return icons.high
        end
    end
end

return function(width)
    local private = {}
    
    local function build_widget()
        local slider_width = width or 150

        private.volume_slider = wibox.widget {
            bar_active_color = beautiful.fg_normal,
            bar_color = beautiful.bg_focus,
            handle_color = beautiful.fg_normal,
            handle_shape = gears.shape.circle,
            handle_border_color = beautiful.fg_normal,
            handle_width = 14,
            value = volume_value,
            maximum = 100,
            forced_width = slider_width,
            forced_height = 4,
            bar_height = 4,
            widget = wibox.widget.slider
        }

        private.icon_widget = wibox.widget {
            markup = get_icon(),
            font = helpers.change_font_size(beautiful.icon_font, 16),
            widget = wibox.widget.textbox
        }
        private.widget = wibox.widget {
            {
                private.icon_widget,
                right = 8,
                widget = wibox.container.margin
            },
            private.volume_slider,
            nil,
            layout = wibox.layout.align.horizontal
        }

        private.pulse_updating_value = false
        private.mouse_updating_value = false
        private.volume_slider:connect_signal("property::value", function()
            -- if we are updating volume_slider.value because pulse changed, we do not want to change it again to prevent loops
            if private.pulse_updating_value then
                private.pulse_updating_value = false
                return
            else
                private.mouse_updating_value = true
                pulseaudio.set_volume(private.volume_slider.value)
            end
        end)

        private.icon_widget:buttons({
            awful.button({}, 1, function()
                pulseaudio.toggle_volume()
            end)
        })
    
        private.volume_slider:buttons({
            awful.button({}, 4, function()
                pulseaudio.inc_volume(5)
            end),
            awful.button({}, 5, function()
                pulseaudio.dec_volume(5)
            end)
        })

        private.widget.type = "control_widget"
    end
    
    pulseaudio.on_enabled(function()
        if not private.widget then build_widget() end
        if private.mouse_updating_value then
            private.mouse_updating_value = false
            return
        end
        private.pulse_updating_value = true
        private.volume_slider.value = pulseaudio.volume

        private.widget.visible = pulseaudio.enabled
    end)
    pulseaudio.on_disabled(function()
        private.widget.visible = pulseaudio.enabled
    end)
    pulseaudio.on_properties_changed(function()
        private.icon_widget.markup = get_icon()
        
        if private.mouse_updating_value then
            private.mouse_updating_value = false
            return
        end
        private.pulse_updating_value = true
        private.volume_slider.value = pulseaudio.volume
    end)
    
    return private.widget
end
