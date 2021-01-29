require("popups.volume") -- show popup
local beautiful = require("beautiful")
local color = require("themes.util.color")
local awful = require("awful")
local pulseaudio = require("util.pulseaudio")
local base_panel_widget = require("widgets.panel.base")
local volume_control_widget = require("widgets.controls.volume")
local helpers = require("util.helpers")

local icons = {
    low = "",
    medium = "",
    high = "",
    muted = ""
}

return function(show_label)   
    local widget = base_panel_widget{control_widget = volume_control_widget()}
    widget.visible = false

    -- if nothing specified, we show the label
    if show_label == nil then
        widget:show_label(true)
    else
        widget:show_label(show_label)
    end

    local function get_icon()
        if pulseaudio.muted then
            return icons.muted
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

    local function update_widget()
        if pulseaudio.muted then
            widget:set_icon_color(color.black_alt)
            widget:set_label_color(color.black_alt)
        else
            widget:set_icon_color(beautiful.fg_normal)
            widget:set_label_color(beautiful.fg_normal)
        end
        widget:update(get_icon(), math.floor(pulseaudio.volume) .. "%")
    end

    pulseaudio.on_enabled(function()
        update_widget()
        widget.visible = pulseaudio.enabled
    end)
    pulseaudio.on_disabled(function()
        widget.visible = pulseaudio.enabled
    end)
    pulseaudio.on_properties_changed(update_widget)

    widget:buttons({
        awful.button({}, 2, function()
            pulseaudio.toggle_volume()
        end),
        awful.button({}, 4, function()
            pulseaudio.inc_volume(5)
        end),
        awful.button({}, 5, function()
            pulseaudio.dec_volume(5)
        end),
        widget:buttons()
    })

    return widget
end
