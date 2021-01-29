local beautiful = require("beautiful")
local color = require("themes.util.color")
local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local pulseaudio = require("util.pulseaudio")
local helpers = require("util.helpers")

local volume_popup = {}

local icons = {
    low = "",
    medium = "",
    high = "",
    muted = "" -- TODO: make a muted_low, muted_medium, muted_high
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

local popup, progressbar, icon_widget
local function build_popup()
    progressbar = wibox.widget {
        max_value = 100,
        value = pulseaudio.volume,
        forced_height = 6,
        forced_width = 0,
        color = beautiful.fg_normal,
        background_color = beautiful.border_normal,
        widget = wibox.widget.progressbar
    }
    
    icon_widget = wibox.widget {
        markup = get_icon(),
        font = helpers.change_font_size(beautiful.icon_font, 128),
        widget = wibox.widget.textbox
    }
    
    popup = awful.popup {
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
        input_passthrough = true,
        visible = false
    }
end

volume_popup.timer = gears.timer {
    timeout   = 1,
    callback  = function()
        popup.visible = false
        volume_popup.timer:stop()
    end
}

function volume_popup.show()
    if not popup or not popup.enabled then return end

    if popup.visible then
        volume_popup.timer:again()
    else
        popup.visible = true
        volume_popup.timer:start()
    end
    progressbar.value = pulseaudio.volume
    if pulseaudio.muted then
        progressbar.color = color.white_alt
    else
        progressbar.color = beautiful.fg_normal
    end
    icon_widget:set_markup_silently(get_icon())
end

pulseaudio.on_enabled(function()
    if not popup then build_popup() end
    popup.enabled = pulseaudio.enabled
end)
pulseaudio.on_disabled(function()
    popup.enabled = pulseaudio.enabled
end)
pulseaudio.on_properties_changed(function()
    volume_popup.show()
end)

return volume_popup
