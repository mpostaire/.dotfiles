local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local awful = require("awful")
local alsa = require("util.alsa")
local helpers = require("util.helpers")
local slider = require("widgets.slider")

-- // FIXME sound mute + no move click on slider = slider graphics updates but not alsa
--          this is caused by the fact that when we mute, alsa_updating_value is set to true
--          but because this change did not come from a slider.value change, it's not set back to false
--          in the property signal handler of the slider value afterwards. (idea : in alsa.on_properties_changed
--          add a table argument of all changed properties to check if a mute change is the origin of the callback)

local volume_widget = {}
volume_widget.__index = volume_widget

local icons = {
    low = "",
    medium = "",
    high = "",
    muted = ""
}

local function get_icon()
    if alsa.muted then
        return '<span foreground="'..beautiful.white_alt..'">'..icons.muted..'</span>'
    else
        if alsa.volume < 33 then
            return icons.low
        elseif alsa.volume < 66 then
            return icons.medium
        else
            return icons.high
        end
    end
end

function volume_widget:new(width)
    local slider_width = width or 150
    -- we convert brightness value from [10,100] to [0,100] interval
    local volume_value = ((alsa.volume - 10) / 90) * 100

    local volume_slider = slider {
        bar_left_color = beautiful.white,
        bar_right_color = beautiful.bg_focus,
        handle_color = beautiful.fg_normal,
        handle_shape = gears.shape.circle,
        handle_border_color = beautiful.fg_normal,
        handle_width = 12,
        value = volume_value,
        maximum = 100,
        forced_width = slider_width,
        forced_height = 4
    }

    local icon_widget = wibox.widget {
        markup = get_icon(),
        font = helpers.change_font_size(beautiful.icon_font, 16),
        widget = wibox.widget.textbox
    }
    local widget = wibox.widget {
        {
            icon_widget,
            right = 8,
            widget = wibox.container.margin
        },
        volume_slider,
        nil,
        layout = wibox.layout.align.horizontal
    }
    setmetatable(widget, volume_widget)

    widget._private.alsa_updating_value = false
    widget._private.mouse_updating_value = false
    local handle = volume_slider.handle
    handle:connect_signal("property::value", function()
        -- if we are updating handle.value because alsa changed we do not want to change it again to prevent loops
        if widget._private.alsa_updating_value then
            widget._private.alsa_updating_value = false
            return
        else
            widget._private.mouse_updating_value = true
            -- handle.value is changed to fit in the [10,100] interval
            alsa.set_volume(((handle.value / 100) * 90) + 10)
        end
    end)

    alsa.on_properties_changed(function()
        icon_widget.markup = get_icon()

        if widget._private.mouse_updating_value then
            widget._private.mouse_updating_value = false
            return
        end
        widget._private.alsa_updating_value = true
        handle.value = ((alsa.volume - 10) / 90) * 100
    end)

    icon_widget:buttons(gears.table.join(
        awful.button({}, 1, function()
            alsa.toggle_volume()
        end)
    ))

    volume_slider:buttons(gears.table.join(
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
