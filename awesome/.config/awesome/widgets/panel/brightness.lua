require("popups.brightness") -- show popup
local awful = require("awful")
local gears = require("gears")
local brightness = require("util.brightness")
local base_panel_widget = require("widgets.panel.base")
local brightness_control_widget = require("widgets.controls.brightness")
local capi = {root = root}

local brightness_widget = setmetatable({}, {__index = base_panel_widget})
brightness_widget.__index = brightness_widget

local icon = ""

function brightness_widget:new(show_label)
    local widget = base_panel_widget:new(_, _, brightness_control_widget:new())
    setmetatable(widget, brightness_widget)

    -- if nothing specified, we show the label
    if show_label == nil then
        widget:set_label_visible(true)
    else
        widget:set_label_visible(show_label)
    end

    widget:update(icon, math.floor(brightness.brightness) .. "%")

    widget:buttons(gears.table.join(
        awful.button({}, 4, function()
            brightness.inc_brightness(5)
        end),
        awful.button({}, 5, function()
            brightness.dec_brightness(5)
        end),
        widget:buttons()
    ))

    local widget_keys = gears.table.join(
        awful.key({}, "XF86MonBrightnessUp", function()
            brightness.inc_brightness(5)
        end,
        {description = "brightness up", group = "other"}),
        awful.key({}, "XF86MonBrightnessDown", function()
            brightness.dec_brightness(5)
        end,
        {description = "brightness down", group = "other"})
    )

    capi.root.keys(gears.table.join(capi.root.keys(), widget_keys))

    brightness.on_properties_changed(function()
        widget:update(icon, math.floor(brightness.brightness) .. "%")
    end)

    return widget
end

return brightness_widget
