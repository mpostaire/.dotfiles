local beautiful = require("beautiful")
local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local brightness = require("util.brightness")

local brightness_popup = {}

local icon = ""

local progressbar = wibox.widget {
    max_value     = 100,
    value         = brightness.brightness,
    forced_height = 6,
    forced_width  = 0,
    color = beautiful.fg_normal,
    background_color = beautiful.border_normal,
    widget = wibox.widget.progressbar
}

local icon_widget = wibox.widget {
    markup = icon,
    font = "Material Icons 128",
    widget = wibox.widget.textbox
}

local popup = awful.popup {
    widget = {
        {
            icon_widget,
            progressbar,
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
    progressbar.value = brightness.brightness
end

return brightness_popup
