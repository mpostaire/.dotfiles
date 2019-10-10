require("popups.volume") -- show popup
local beautiful = require("beautiful")
local awful = require("awful")
local gears = require("gears")
local alsa = require("util.alsa")
local base_panel_widget = require("widgets.panel.base")
local volume_control_widget = require("widgets.controls.volume")
local capi = {root = root}

local volume_widget = setmetatable({}, {__index = base_panel_widget})
volume_widget.__index = volume_widget

local icons = {
    normal = "",
    muted = ""
}

local function update_widget(widget)
    local icon
    if alsa.muted then
        widget:set_icon_color(beautiful.white_alt)
        widget:set_label_color(beautiful.white_alt)
        icon = icons.muted
    else
        widget:set_icon_color(beautiful.fg_normal)
        widget:set_label_color(beautiful.fg_normal)
        icon = icons.normal
    end
    widget:update(icon, math.floor(alsa.volume) .. "%")
end

function volume_widget:new(show_label)
    local widget = base_panel_widget:new(_, _, volume_control_widget:new())
    setmetatable(widget, volume_widget)

    -- if nothing specified, we show the label
    if show_label == nil then
        widget:set_label_visible(true)
    else
        widget:set_label_visible(show_label)
    end

    update_widget(widget)

    widget:buttons(gears.table.join(
        awful.button({}, 2, function()
            alsa.toggle_volume()
        end),
        awful.button({}, 4, function()
            alsa.inc_volume(5)
        end),
        awful.button({}, 5, function()
            alsa.dec_volume(5)
        end),
        widget:buttons()
    ))

    local widget_keys = gears.table.join(
        awful.key({}, "XF86AudioRaiseVolume", function()
            alsa.inc_volume(5)
        end,
        {description = "volume up", group = "multimedia"}),
        awful.key({}, "XF86AudioMute", function()
            alsa.toggle_volume()
        end,
        {description = "toggle mute volume", group = "multimedia"}),
        awful.key({}, "XF86AudioLowerVolume", function()
            alsa.dec_volume(5)
        end,
        {description = "volume down", group = "multimedia"})
    )

    capi.root.keys(gears.table.join(capi.root.keys(), widget_keys))

    alsa.on_properties_changed(function()
        update_widget(widget)
    end)

    return widget
end

return volume_widget
