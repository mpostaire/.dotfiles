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
        text = icon,
        font = "Material Icons 12",
        widget = wibox.widget.textbox
    },
    widget = wibox.container.margin(_, beautiful.wibar_widgets_padding, beautiful.widgets_inner_padding, 0, 0)
}

local text_widget = wibox.widget {
    {
        text = "Musique - 00:00",
        widget = wibox.widget.textbox
    },
    widget = wibox.container.margin(_, 0, beautiful.wibar_widgets_padding, 0, 0)
}

local music_widget = wibox.widget {
    icon_widget,
    text_widget,
    layout = wibox.layout.fixed.horizontal
}

local old_cursor, old_wibox
music_widget:connect_signal("mouse::enter", function()
    notification:show(true)

    local w = mouse.current_wibox
    old_cursor, old_wibox = w.cursor, w
    w.cursor = "hand1"
end)
music_widget:connect_signal("mouse::leave", function()
    notification:hide()

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
