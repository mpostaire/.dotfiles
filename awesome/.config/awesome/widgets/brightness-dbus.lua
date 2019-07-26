-- TODO: handle when proxy lose connection (also check this in all dbus based widgets)
-- TODO: replace ascii progressbar with wibox.widget.progressbar (also do this in all widgets that uses one)

local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")
local popup_notification = require("util.popup_notification")

local p = require("dbus_proxy")

local proxy = p.Proxy:new(
    {
        bus = p.Bus.SESSION,
        name = "fr.mpostaire.awdctl",
        interface = "fr.mpostaire.awdctl.Brightness",
        path = "/fr/mpostaire/awdctl/Brightness"
    }
)

if not proxy then
    return nil
end

local icon = ""

local mouse_hover = false

local notification = popup_notification:new()
notification:set_icon(icon)

local icon_widget = wibox.widget {
    {
        markup = icon,
        id = "icon",
        font = "Material Icons 12",
        widget = wibox.widget.textbox
    },
    widget = wibox.container.margin(_, beautiful.wibar_widgets_padding, beautiful.widgets_inner_padding, 0, 0)
}

local function get_message()
    local bar = "[                    ]"

    local s = math.floor(proxy.Percentage / 5)

    bar = bar:gsub(" ", "=", s)
    return bar
end

local function get_text()
    if mouse_hover then
        return '<span foreground="'..beautiful.fg_normal_hover..'">'..math.floor(proxy.Percentage)..'%</span>'
    else
        return '<span foreground ="' ..beautiful.fg_normal.. '">' ..math.floor(proxy.Percentage).. '%</span>'
    end
end

local function get_title()
    return "<b>Luminosité: " ..math.floor(proxy.Percentage).. "%</b>"
end

local text_widget = wibox.widget {
    {
        id = "text",
        widget = wibox.widget.textbox
    },
    widget = wibox.container.margin(_, 0, beautiful.wibar_widgets_padding, 0, 0)
}

local brightness_widget = wibox.widget {
    icon_widget,
    text_widget,
    layout = wibox.layout.fixed.horizontal
}

local function update_widget()
    icon_widget:get_children_by_id('icon')[1]:set_markup_silently(icon)
    text_widget:get_children_by_id('text')[1]:set_markup_silently(get_text())

    notification:set_markup(get_title(), get_message())
    notification:set_icon(icon)
end
update_widget()

proxy:on_properties_changed(function (p, changed, invalidated)
    assert(p == proxy)
    for k, v in pairs(changed) do
        if k == "Percentage" then
            update_widget()
            notification:show(true)
        end
    end
end)

brightness_widget:buttons(gears.table.join(
    awful.button({}, 1, function() notification:toggle() end),
    awful.button({}, 4, function()
        proxy:IncBrightness(5)
    end),
    awful.button({}, 5, function()
        proxy:DecBrightness(5)
    end)
))

local old_cursor, old_wibox
brightness_widget:connect_signal("mouse::enter", function()
    -- mouse_hover color highlight
    mouse_hover = true
    icon_widget:get_children_by_id('icon')[1]:set_markup_silently('<span foreground="'..beautiful.fg_normal_hover..'">'..icon..'</span>')
    text_widget:get_children_by_id('text')[1]:set_markup_silently(get_text())

    local w = mouse.current_wibox
    old_cursor, old_wibox = w.cursor, w
    w.cursor = "hand1"
end)

brightness_widget:connect_signal("mouse::leave", function()
    -- no mouse_hover color highlight
    mouse_hover = false
    icon_widget:get_children_by_id('icon')[1]:set_markup_silently(icon)
    text_widget:get_children_by_id('text')[1]:set_markup_silently(get_text())

    if old_wibox then
        old_wibox.cursor = old_cursor
        old_wibox = nil
    end
end)

local widget_keys = gears.table.join(
    awful.key({}, "XF86MonBrightnessUp", function()
        proxy:IncBrightness(5)
    end,
    {description = "brightness up", group = "multimedia"}),
    awful.key({}, "XF86MonBrightnessDown", function()
        proxy:DecBrightness(5)
    end,
    {description = "brightness down", group = "multimedia"})
)

root.keys(gears.table.join(root.keys(), widget_keys))

return brightness_widget
