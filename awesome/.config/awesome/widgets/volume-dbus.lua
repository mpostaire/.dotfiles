local wibox = require("wibox")
local beautiful = require("beautiful")
local awful = require("awful")
local gears = require("gears")
local popup_notification = require("util.popup_notification")

local p = require("dbus_proxy")

local proxy = p.Proxy:new(
    {
        bus = p.Bus.SESSION,
        name = "fr.mpostaire.awdctl",
        interface = "fr.mpostaire.awdctl.Volume",
        path = "/fr/mpostaire/awdctl/Volume"
    }
)

if not proxy then
    return nil
end

local icons = {
    "",
    ""
}

local mouse_hover = false

local notification = popup_notification:new()

local icon_widget = wibox.widget {
    {
        markup = icons[1],
        id = "icon",
        font = "Material Icons 12",
        widget = wibox.widget.textbox
    },
    widget = wibox.container.margin(_, beautiful.wibar_widgets_padding, beautiful.widgets_inner_padding, 0, 0)
}

local text_widget = wibox.widget {
    {
        id = "text",
        widget = wibox.widget.textbox
    },
    widget = wibox.container.margin(_, 0, beautiful.wibar_widgets_padding, 0, 0)
}

local volume_widget = wibox.widget {
    icon_widget,
    text_widget,
    layout = wibox.layout.fixed.horizontal
}

local function get_message()
    local bar = "[                    ]"

    local s = math.floor(proxy.Percentage / 5)

    if proxy.Muted then
        bar = bar:gsub(" ", "+", s)
        return '<span foreground="' ..beautiful.white_alt.. '">' ..bar.. '</span>'
    else
        bar = bar:gsub(" ", "=", s)
        return bar
    end
end

local function get_title()
    if proxy.Muted then
        return "<b>Volume coupé</b>"
    else
        return "<b>Volume: " ..math.floor(proxy.Percentage).. "%</b>"
    end
end

local function get_icon(hover)
    if proxy.Muted then
        if mouse_hover then
            return '<span foreground="'..beautiful.white_alt_hover..'">'..icons[2]..'</span>'
        else
            return '<span foreground ="' ..beautiful.white_alt.. '">' ..icons[2].. '</span>'
        end
    else
        if mouse_hover and not hover then
            return '<span foreground="'..beautiful.fg_normal_hover..'">'..icons[1]..'</span>'
        else
            return icons[1]
        end
    end
end

local function get_text()
    if proxy.Muted then
        if mouse_hover then
            return '<span foreground="'..beautiful.white_alt_hover..'">'..math.floor(proxy.Percentage)..'%</span>'
        else
            return '<span foreground ="' ..beautiful.white_alt.. '">' ..math.floor(proxy.Percentage).. '%</span>'
        end
    else
        if mouse_hover then
            return '<span foreground="'..beautiful.fg_normal_hover..'">'..math.floor(proxy.Percentage)..'%</span>'
        else
            return math.floor(proxy.Percentage).."%"
        end
    end
end

local function update_widget()
    icon_widget:get_children_by_id('icon')[1]:set_markup_silently(get_icon(mouse_hover))
    text_widget:get_children_by_id('text')[1]:set_markup_silently(get_text())

    notification:set_markup(get_title(), get_message())
    notification:set_icon(get_icon(false))
end
update_widget()

proxy:on_properties_changed(function (p, changed, invalidated)
    assert(p == proxy)
    for k, v in pairs(changed) do
        if k == "Percentage" or k == "Muted" then
            update_widget()
            notification:show(true)
        end
    end
end)

volume_widget:buttons(gears.table.join(
    awful.button({}, 1, function() notification:toggle() end),
    awful.button({}, 2, function()
        proxy:ToggleVolume()
    end),
    awful.button({}, 4, function()
        if proxy.Muted then
            proxy:ToggleVolume()
        end
        proxy:IncVolume(5)
    end),
    awful.button({}, 5, function()
        if proxy.Muted then
            proxy:ToggleVolume()
        end
        proxy:DecVolume(5)
    end)
))

local old_cursor, old_wibox
volume_widget:connect_signal("mouse::enter", function()
    -- mouse_hover color highlight
    mouse_hover = true
    icon_widget:get_children_by_id('icon')[1]:set_markup_silently(get_icon())
    text_widget:get_children_by_id('text')[1]:set_markup_silently(get_text())

    local w = mouse.current_wibox
    old_cursor, old_wibox = w.cursor, w
    w.cursor = "hand1"
end)

volume_widget:connect_signal("mouse::leave", function()
    -- no mouse_hover color highlight
    mouse_hover = false
    icon_widget:get_children_by_id('icon')[1]:set_markup_silently(get_icon())
    text_widget:get_children_by_id('text')[1]:set_markup_silently(get_text())

    if old_wibox then
        old_wibox.cursor = old_cursor
        old_wibox = nil
    end
end)

local widget_keys = gears.table.join(
    awful.key({}, "XF86AudioRaiseVolume", function()
        if proxy.Muted then
            proxy:ToggleVolume()
        end
        proxy:IncVolume(5)
    end,
    {description = "volume up", group = "multimedia"}),
    awful.key({}, "XF86AudioMute", function()
        proxy:ToggleVolume()
    end,
    {description = "toggle mute volume", group = "multimedia"}),
    awful.key({}, "XF86AudioLowerVolume", function()
        if proxy.Muted then
            proxy:ToggleVolume()
        end
        proxy:DecVolume(5)
    end,
    {description = "volume down", group = "multimedia"})
)

root.keys(gears.table.join(root.keys(), widget_keys))

return volume_widget
