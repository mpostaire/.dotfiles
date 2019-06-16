local wibox = require("wibox")
local beautiful = require("beautiful")
local rofi = require("util.rofi")
local awful = require("awful")
local gears = require("gears")
local variables = require("configuration.variables")

local icon = ""

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
        widget = wibox.widget.textclock("%H:%M")
    },
    widget = wibox.container.margin(_, 0, beautiful.wibar_widgets_padding, 0, 0)
}

local clock_widget = wibox.widget {
    icon_widget,
    text_widget,
    layout = wibox.layout.fixed.horizontal
}

local old_cursor, old_wibox
clock_widget:connect_signal("mouse::enter", function()
    local w = mouse.current_wibox
    old_cursor, old_wibox = w.cursor, w
    w.cursor = "hand1"
end)
clock_widget:connect_signal("mouse::leave", function()
    if old_wibox then
        old_wibox.cursor = old_cursor
        old_wibox = nil
    end
end)

clock_widget:connect_signal("button::press", function(_, _, _, button)
    if button == 1 then
        rofi.calendar_menu()
    end
end)

clock_widget.keys = gears.table.join(
    awful.key({ variables.modkey }, "c", rofi.calendar_menu,
    {description = "show the calendar menu", group = "launcher"})
)

return clock_widget
