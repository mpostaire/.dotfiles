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
    local widget = wibox.layout.align.horizontal()

    local pulse_updating_value = false
    local mouse_updating_value = false
    local function build_widget()
        widget.volume_slider = wibox.widget {
            bar_active_color = beautiful.fg_normal,
            bar_color = beautiful.bg_focus,
            handle_color = beautiful.fg_normal,
            handle_shape = gears.shape.circle,
            handle_border_color = beautiful.fg_normal,
            handle_width = 14,
            maximum = 100,
            forced_width = width or 150,
            forced_height = 4,
            bar_height = 4,
            widget = wibox.widget.slider
        }

        widget.icon_widget = wibox.widget {
            markup = get_icon(),
            font = helpers.change_font_size(beautiful.icon_font, 16),
            widget = wibox.widget.textbox
        }
        widget.first = wibox.widget {
            widget.icon_widget,
            right = 8,
            widget = wibox.container.margin
        }
        widget.second = widget.volume_slider

        widget.volume_slider:connect_signal("property::value", function()
            -- if we are updating volume_slider.value because pulse changed, we do not want to change it again to prevent loops
            if pulse_updating_value then
                pulse_updating_value = false
                return
            else
                mouse_updating_value = true
                pulseaudio.set_volume(widget.volume_slider.value)
            end
        end)

        widget.icon_widget:buttons({
            awful.button({}, 1, function()
                pulseaudio.toggle_volume()
            end)
        })

        widget.volume_slider:buttons({
            awful.button({}, 4, function()
                pulseaudio.inc_volume(5)
            end),
            awful.button({}, 5, function()
                pulseaudio.dec_volume(5)
            end)
        })

    end

    widget.type = "control_widget"
    
    pulseaudio.on_enabled(function()
        if not widget.volume_slider then build_widget() end
        if mouse_updating_value then
            mouse_updating_value = false
            return
        end
        pulse_updating_value = true
        widget.volume_slider.value = pulseaudio.volume

        widget.visible = pulseaudio.enabled
    end)
    pulseaudio.on_disabled(function()
        widget.visible = pulseaudio.enabled
    end)
    pulseaudio.on_properties_changed(function()
        widget.icon_widget.markup = get_icon()
        
        if mouse_updating_value then
            mouse_updating_value = false
            return
        end
        pulse_updating_value = true
        widget.volume_slider.value = pulseaudio.volume
    end)
    
    return widget
end
