local beautiful = require("beautiful")
local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local brightness = require("util.brightness")
local helpers = require("util.helpers")

local brightness_popup = {}

local icon = ""

local popup, progressbar
local function build_popup()
    progressbar = wibox.widget {
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
        visible = false
    }
end

brightness_popup.timer = gears.timer {
    timeout   = 1,
    callback  = function()
        popup.visible = false
        brightness_popup.timer:stop()
    end
}

function brightness_popup.show()
    if not popup or not popup.enabled then return end

    if popup.visible then
        brightness_popup.timer:again()
    else
        popup.visible = true
        brightness_popup.timer:start()
    end
    progressbar.value = brightness.brightness
end

brightness.on_enabled(function()
    if not popup then build_popup() end
    popup.enabled = brightness.enabled
end)
brightness.on_disabled(function()
    popup.enabled = brightness.enabled
end)
brightness.on_properties_changed(function()
    brightness_popup.show()
end)

return brightness_popup
