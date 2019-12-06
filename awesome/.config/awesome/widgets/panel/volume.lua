require("popups.volume") -- show popup
local beautiful = require("beautiful")
local awful = require("awful")
local gears = require("gears")
local alsa = require("util.alsa")
local base_panel_widget = require("widgets.panel.base")
local volume_control_widget = require("widgets.controls.volume")

-- BUG: when muted slider does not update volume -> not exactly that but check

local icons = {
    low = "",
    medium = "",
    high = "",
    muted = ""
}

return function(show_label)
    local widget = base_panel_widget:new{control_widget = volume_control_widget:new()}

    -- if nothing specified, we show the label
    if show_label == nil then
        widget:show_label(true)
    else
        widget:show_label(show_label)
    end

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

    local function update_widget()
        if alsa.muted then
            widget:set_icon_color(beautiful.white_alt)
            widget:set_label_color(beautiful.white_alt)
        else
            widget:set_icon_color(beautiful.fg_normal)
            widget:set_label_color(beautiful.fg_normal)
        end
        widget:update(get_icon(), math.floor(alsa.volume) .. "%")
    end

    update_widget()

    alsa.on_properties_changed(update_widget)

    widget:buttons(gears.table.join(
        awful.button({}, 2, function()
            alsa.toggle_volume()
        end),
        awful.button({}, 4, function()
            alsa.inc_volume(5)
        end),
        awful.button({}, 5, function()
            alsa.dec_volume(5)
        end),
        widget:buttons()
    ))

    return widget
end
