local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local awful = require("awful")
local alsa = require("util.alsa")

local volume_widget = {}
volume_widget.__index = volume_widget

local icons = {
    normal = "",
    muted = ""
}

local function get_icon()
    if alsa.muted then
        return '<span foreground="'..beautiful.white_alt..'">'..icons.muted..'</span>'
    else
        return icons.normal
    end
end

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

function volume_widget:new(width)
    local slider_width = width or 150
    -- we convert brightness value from [10,100] to [0,100] interval
    local volume_value = ((alsa.volume - 10) / 90) * 100

    local slider = wibox.widget {
        bar_height = 4,
        bar_color = get_slider_color_pattern(volume_value, slider_width),
        handle_color = beautiful.fg_normal,
        handle_shape = gears.shape.circle,
        handle_border_color = beautiful.fg_normal,
        handle_border_width = 1,
        value = volume_value,
        maximum = 100,
        forced_width = slider_width,
        forced_height = 4,
        widget = wibox.widget.slider
    }

    local icon_widget = wibox.widget {
        markup = get_icon(),
        font = 'Material Icons 16',
        widget = wibox.widget.textbox
    }
    local widget = wibox.widget {
        icon_widget,
        slider,
        spacing = 8,
        layout = wibox.layout.fixed.horizontal
    }
    setmetatable(widget, volume_widget)

    widget._private.alsa_updating_value = false
    widget._private.mouse_updating_value = false
    slider:connect_signal("property::value", function()
        slider.bar_color = get_slider_color_pattern(slider.value, slider_width)

        -- if we are updating slider.value because alsa changed we do not want to change it again to prevent loops
        if widget._private.alsa_updating_value then
            widget._private.alsa_updating_value = false
            return
        else
            widget._private.mouse_updating_value = true
            -- slider.value is changed to fit in the [10,100] interval
            alsa.set_volume(((slider.value / 100) * 90) + 10)
        end
    end)

    alsa.on_properties_changed(function()
        icon_widget.markup = get_icon()

        if widget._private.mouse_updating_value then
            widget._private.mouse_updating_value = false
            return
        end
        widget._private.alsa_updating_value = true
        slider.value = ((alsa.volume - 10) / 90) * 100
    end)

    icon_widget:buttons(gears.table.join(
        awful.button({}, 1, function()
            alsa.toggle_volume()
        end)
    ))

    slider:buttons(gears.table.join(
        awful.button({}, 4, function()
            alsa.inc_volume(5)
        end),
        awful.button({}, 5, function()
            alsa.dec_volume(5)
        end)
    ))

    widget.type = "control_widget"

    return widget
end

return volume_widget
