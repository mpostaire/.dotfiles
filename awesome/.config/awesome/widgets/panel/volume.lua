local wibox = require("wibox")
local beautiful = require("beautiful")
local awful = require("awful")
local gears = require("gears")
local alsa = require("util.alsa")
local popup = require("popups.volume")
local base_panel_widget = require("widgets.panel.base")
local capi = {mouse = mouse, root = root}

local icons = {
    normal = "",
    muted = ""
}

local volume_widget = base_panel_widget:new()

local function get_icon()
    if alsa.muted then
        volume_widget:set_icon_color(beautiful.white_alt)
        return icons.muted
    else
        volume_widget:set_icon_color(beautiful.fg_normal)
        return icons.normal
    end
end

local function get_text()
    if alsa.muted then
        volume_widget:set_label_color(beautiful.white_alt)
    else
        volume_widget:set_label_color(beautiful.fg_normal)
    end
    return math.floor(alsa.volume).."%"
end

local function update_widget()
    volume_widget:update(get_icon(), get_text())
end
update_widget()

alsa.on_properties_changed(function()
    update_widget()
    popup.show()
end)

volume_widget:buttons(gears.table.join(
    awful.button({}, 2, function()
        alsa.toggle_volume()
    end),
    awful.button({}, 4, function()
        alsa.inc_volume(5)
    end),
    awful.button({}, 5, function()
        alsa.dec_volume(5)
    end)
))

local widget_keys = gears.table.join(
    awful.key({}, "XF86AudioRaiseVolume", function()
        alsa.inc_volume(5)
        popup.show()
    end,
    {description = "volume up", group = "multimedia"}),
    awful.key({}, "XF86AudioMute", function()
        alsa.toggle_volume()
        popup.show()
    end,
    {description = "toggle mute volume", group = "multimedia"}),
    awful.key({}, "XF86AudioLowerVolume", function()
        alsa.dec_volume(5)
        popup.show()
    end,
    {description = "volume down", group = "multimedia"})
)

capi.root.keys(gears.table.join(capi.root.keys(), widget_keys))

----- control widget

local width = 150
local function get_slider_color_pattern(value)
    -- we convert value from [0,100] to [0,slider.forced_width] interval
    value = (value / 100) * width

    return gears.color.create_pattern({
        type = "linear",
        from = { value, 0 },
        to = { value + 1, 0 },
        stops = { { 0, beautiful.fg_normal }, { 1, beautiful.bg_focus } }
    })
end

local slider = wibox.widget {
    bar_height = 4,
    bar_color = get_slider_color_pattern(alsa.volume),
    handle_color = beautiful.fg_normal,
    handle_shape = gears.shape.circle,
    handle_border_color = beautiful.fg_normal,
    handle_border_width = 1,
    value = alsa.volume,
    maximum = 100,
    forced_width = width,
    forced_height = 4,
    widget = wibox.widget.slider
}

local alsa_updating_value = false
local mouse_updating_value = false
slider:connect_signal("property::value", function()
    slider.bar_color = get_slider_color_pattern(slider.value)

    -- if we are updating slider.value because brightness changed we do not want to change it again to prevent loops
    if alsa_updating_value then
        alsa_updating_value = false
        return
    else
        mouse_updating_value = true
        alsa.set_volume(slider.value)
    end
end)

alsa.on_properties_changed(function()
    if mouse_updating_value then
        mouse_updating_value = false
        return
    end
    alsa_updating_value = true
    slider.value = alsa.volume
end)

local icon = wibox.widget {
    markup = get_icon(),
    font = 'Material Icons 16',
    widget = wibox.widget.textbox
}
icon:buttons(gears.table.join(
    awful.button({}, 1, function()
        alsa.toggle_volume()
    end)
))

volume_widget.popup_widget = wibox.widget {
    icon,
    slider,
    spacing = 8,
    layout = wibox.layout.fixed.horizontal
}

return volume_widget
