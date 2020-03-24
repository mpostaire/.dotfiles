local beautiful = require("beautiful")
local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local alsa = require("util.alsa")
local helpers = require("util.helpers")

if not alsa.enabled then return end

local volume_popup = {}

local icons = {
    low = "",
    medium = "",
    high = "",
    muted = "" -- TODO: make a muted_low, muted_medium, muted_high
}

local function get_icon()
    if alsa.muted then
        return '<span foreground="'..color.white_alt..'">'..icons.muted..'</span>'
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

local progressbar = wibox.widget {
    max_value = 100,
    value = alsa.volume,
    forced_height = 6,
    forced_width = 0,
    color = beautiful.fg_normal,
    background_color = beautiful.border_normal,
    widget = wibox.widget.progressbar
}

local icon_widget = wibox.widget {
    markup = get_icon(),
    font = helpers.change_font_size(beautiful.icon_font, 128),
    widget = wibox.widget.textbox
}

local popup = awful.popup {
    widget = {
        {
            icon_widget,
            progressbar,
            spacing = 8,
            layout = wibox.layout.fixed.vertical
        },
        margins = beautiful.notification_margin,
        widget = wibox.container.margin
    },
    border_color = beautiful.border_normal,
    border_width = beautiful.border_width,
    ontop = true,
    placement = awful.placement.centered,
    visible = false
}

volume_popup.timer = gears.timer {
    timeout   = 1,
    callback  = function()
        popup.visible = false
        volume_popup.timer:stop()
    end
}

function volume_popup.show()
    if popup.visible then
        volume_popup.timer:again()
    else
        popup.visible = true
        volume_popup.timer:start()
    end
    progressbar.value = alsa.volume
    if alsa.muted then
        icon_widget:set_markup_silently('<span foreground="'..color.white_alt..'">'..get_icon()..'</span>')
        progressbar.color = color.white_alt
    else
        icon_widget:set_markup_silently(get_icon())
        progressbar.color = beautiful.fg_normal
    end
end

alsa.on_properties_changed(function()
    volume_popup.show()
end)

return volume_popup
