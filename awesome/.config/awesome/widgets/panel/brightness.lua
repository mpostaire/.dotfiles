local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")
local brightness = require("util.brightness")
local brightness_popup = require("popups.brightness")
local base_widget_panel = require("widgets.panel.base")
local capi = {mouse = mouse, root = root}

local icon = ""

local brightness_widget = base_widget_panel:new()

local function get_text()
    return math.floor(brightness.brightness)
end

local function update_widget()
    brightness_widget:update(icon, get_text())
end
update_widget()

brightness.on_properties_changed(function()
    update_widget()
    brightness_popup.show()
end)

brightness_widget:buttons(gears.table.join(
    awful.button({}, 4, function()
        brightness.inc_brightness(5)
    end),
    awful.button({}, 5, function()
        brightness.dec_brightness(5)
    end)
))

local widget_keys = gears.table.join(
    awful.key({}, "XF86MonBrightnessUp", function()
        brightness.inc_brightness(5)
        brightness_popup.show()
    end,
    {description = "brightness up", group = "other"}),
    awful.key({}, "XF86MonBrightnessDown", function()
        brightness.dec_brightness(5)
        brightness_popup.show()
    end,
    {description = "brightness down", group = "other"})
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
    bar_color = get_slider_color_pattern(((brightness.brightness - 10) / 90) * 100),
    handle_color = beautiful.fg_normal,
    handle_shape = gears.shape.circle,
    handle_border_color = beautiful.fg_normal,
    handle_border_width = 1,
    value = ((brightness.brightness - 10) / 90) * 100, -- we convert brightness value from [10,100] to [0,100] interval
    maximum = 100,
    forced_width = width,
    forced_height = 4,
    widget = wibox.widget.slider
}

local brightness_updating_value = false
local mouse_updating_value = false
slider:connect_signal("property::value", function()
    slider.bar_color = get_slider_color_pattern(slider.value)

    -- if we are updating slider.value because brightness changed we do not want to change it again to prevent loops
    if brightness_updating_value then
        brightness_updating_value = false
        return
    else
        mouse_updating_value = true
        -- slider.value is changed to fit in the [10,100] interval
        brightness.set_brightness(((slider.value / 100) * 90) + 10)
    end
end)

brightness.on_properties_changed(function()
    if mouse_updating_value then
        mouse_updating_value = false
        return
    end
    brightness_updating_value = true
    slider.value = ((brightness.brightness - 10) / 90) * 100
end)

brightness_widget.popup_widget = wibox.widget {
    {
        markup = icon,
        font = 'Material Icons 16',
        widget = wibox.widget.textbox
    },
    slider,
    spacing = 8,
    layout = wibox.layout.fixed.horizontal
}

return brightness_widget
