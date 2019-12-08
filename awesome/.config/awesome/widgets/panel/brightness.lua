require("popups.brightness") -- show popup
local awful = require("awful")
local gears = require("gears")
local brightness = require("util.brightness")
local base_panel_widget = require("widgets.panel.base")
local brightness_control_widget = require("widgets.controls.brightness")

local icon = ""

return function(show_label)
    local widget = base_panel_widget{icon = icon, control_widget = brightness_control_widget()}

    -- if nothing specified, we show the label
    if show_label == nil then
        widget:show_label(true)
    else
        widget:show_label(show_label)
    end

    widget:update_label(math.floor(brightness.brightness) .. "%")

    brightness.on_properties_changed(function()
        widget:update_label(math.floor(brightness.brightness) .. "%")
    end)

    widget:buttons(gears.table.join(
        awful.button({}, 4, function()
            brightness.inc_brightness(5)
        end),
        awful.button({}, 5, function()
            brightness.dec_brightness(5)
        end),
        widget:buttons()
    ))

    return widget
end
