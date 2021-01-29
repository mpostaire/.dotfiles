local beautiful = require("beautiful")
local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local backlight = require("util.backlight")
local helpers = require("util.helpers")

local brightness_popup = {}

local icon = ""

local progressbar = wibox.widget {
    max_value     = 100,
    value         = backlight.brightness,
    forced_height = 6,
    forced_width  = 0,
    color = beautiful.fg_normal,
    background_color = beautiful.border_normal,
    widget = wibox.widget.progressbar
}

local popup = awful.popup {
    widget = {
        {
            {
                markup = icon,
                font = helpers.change_font_size(beautiful.icon_font, 128),
                widget = wibox.widget.textbox
            },
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

brightness_popup.timer = gears.timer {
    timeout   = 1,
    callback  = function()
        popup.visible = false
        brightness_popup.timer:stop()
    end
}

function brightness_popup.show()
    if popup.visible then
        brightness_popup.timer:again()
    else
        popup.visible = true
        brightness_popup.timer:start()
    end
    progressbar.value = backlight.brightness
end

backlight.on_changed(brightness_popup.show)

return brightness_popup
