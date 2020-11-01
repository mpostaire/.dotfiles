require("popups.brightness") -- show popup
local awful = require("awful")
local brightness = require("util.brightness")
local base_panel_widget = require("widgets.panel.base")
local brightness_control_widget = require("widgets.controls.brightness")
local helpers = require("util.helpers")

local icon = ""

return function(show_label)
    local widget = base_panel_widget{icon = icon, control_widget = brightness_control_widget()}
    widget.visible = false

    -- if nothing specified, we show the label
    if show_label == nil then
        widget:show_label(true)
    else
        widget:show_label(show_label)
    end

    local function update_widget()
        widget:update_label(math.floor(brightness.brightness) .. "%")
    end

    brightness.on_enabled(function()
        update_widget()
        widget.visible = brightness.enabled
    end)
    brightness.on_disabled(function()
        widget.visible = brightness.enabled
    end)
    brightness.on_properties_changed(update_widget)

    widget:buttons({
        awful.button({}, 4, function()
            brightness.inc_brightness(5)
        end),
        awful.button({}, 5, function()
            brightness.dec_brightness(5)
        end),
        widget:buttons()
    })

    return widget
end
