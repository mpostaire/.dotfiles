require("popups.brightness") -- show popup
local awful = require("awful")
local backlight = require("util.backlight")
local base_panel_widget = require("widgets.panel.base")
local brightness_control_widget = require("widgets.controls.brightness")
local helpers = require("util.helpers")

local icon = ""

return function(show_label)
    if backlight.read_only then return end

    local widget = base_panel_widget{icon = icon, control_widget = brightness_control_widget()}

    -- if nothing specified, we show the label
    if show_label == nil then
        widget:show_label(true)
    else
        widget:show_label(show_label)
    end

    local function update_widget()
        widget:update_label(math.floor(backlight.brightness) .. "%")
    end
    update_widget()

    backlight.on_changed(update_widget)

    widget:buttons({
        awful.button({}, 4, function()
            backlight.increase(5)
        end),
        awful.button({}, 5, function()
            backlight.decrease(5)
        end),
        widget:buttons()
    })

    return widget
end
