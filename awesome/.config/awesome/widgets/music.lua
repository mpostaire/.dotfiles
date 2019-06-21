local wibox = require("wibox")
local beautiful = require("beautiful")
local rofi = require("util.rofi")
local awful = require("awful")
local variables= require("configuration.variables")
local gears = require("gears")
local spawn = require("awful.spawn")
local popup_notification = require("util.popup_notification")

local icon = ""

local notification = popup_notification:new()
notification:set_icon(icon)
notification:set_markup("<b>Musique</b>", "En construction")
notification.popup.placement = function(d, args)
    awful.placement.top_left(d, args)
    notification.popup.y = notification.popup.y + beautiful.wibar_height + beautiful.notification_offset
    notification.popup.x = notification.popup.x + beautiful.notification_offset
end

local icon_widget = wibox.widget {
    {
        markup = icon,
        id = "icon",
        font = "Material Icons 12",
        widget = wibox.widget.textbox
    },
    widget = wibox.container.margin(_, beautiful.wibar_widgets_padding, beautiful.widgets_inner_padding, 0, 0)
}

local text_widget = wibox.widget {
    {
        markup = "Musique - 00:00",
        id = "text",
        widget = wibox.widget.textbox
    },
    widget = wibox.container.margin(_, 0, beautiful.wibar_widgets_padding, 0, 0)
}

local music_widget = wibox.widget {
    icon_widget,
    text_widget,
    layout = wibox.layout.fixed.horizontal
}

local function get_icon(mouse_hover)
    if mouse_hover then
        return '<span foreground="'..beautiful.fg_normal_hover..'">'..icon..'</span>'
    else
        return icon
    end
end

local function get_text(mouse_hover)
    if mouse_hover then
        return '<span foreground="'..beautiful.fg_normal_hover..'">Musique - 00:00</span>'
    else
        return "Musique - 00:00"
    end
end

local old_cursor, old_wibox
music_widget:connect_signal("mouse::enter", function()
    notification:show(true)

    -- mouse_hover color highlight
    icon_widget:get_children_by_id('icon')[1]:set_markup_silently(get_icon(true))
    text_widget:get_children_by_id('text')[1]:set_markup_silently(get_text(true))

    local w = mouse.current_wibox
    old_cursor, old_wibox = w.cursor, w
    w.cursor = "hand1"
end)
music_widget:connect_signal("mouse::leave", function()
    notification:hide()

    -- no mouse_hover color highlight
    icon_widget:get_children_by_id('icon')[1]:set_markup_silently(get_icon())
    text_widget:get_children_by_id('text')[1]:set_markup_silently(get_text())

    if old_wibox then
        old_wibox.cursor = old_cursor
        old_wibox = nil
    end
end)

music_widget:connect_signal("button::press", function(_, _, _, button)
    if button == 1 then
        rofi.music_menu()
    end
end)

music_widget.keys = gears.table.join(
    awful.key({ variables.modkey }, "m", rofi.music_menu,
    {description = "show the music menu", group = "launcher"}),
    awful.key({ "Control" }, "KP_Divide",
    function()
        spawn.easy_async("mpc toggle", function() end)
    end,
    {description = "music player pause", group = "multimedia"}),
    awful.key({ "Control" }, "KP_Right",
    function()
        spawn.easy_async("mpc next", function() end)
    end,
    {description = "music player next song", group = "multimedia"}),
    awful.key({ "Control" }, "KP_Left",
    function()
        spawn.easy_async("mpc prev", function() end)
    end,
    {description = "music player previous song", group = "multimedia"}),
    awful.key({ "Control" }, "KP_Begin",
    function()
        spawn.easy_async("mpc stop", function() end)
    end,
    {description = "music player stop", group = "multimedia"})
)

return music_widget
