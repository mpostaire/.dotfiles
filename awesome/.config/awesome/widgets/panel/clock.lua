-- this widget is special so it doesn't use my base panel widget because its text_widget is a clock widget

local wibox = require("wibox")
local beautiful = require("beautiful")
local awful = require("awful")
local gears = require("gears")
local variables = require("config.variables")
local calendar = require("popups.calendar")
local capi = {root = root, mouse = mouse}

local icon = ""

local icon_widget = wibox.widget {
    {
        id = 'icon',
        markup = icon,
        font = "Material Icons 12",
        widget = wibox.widget.textbox
    },
    widget = wibox.container.margin(_, beautiful.wibar_widgets_padding, beautiful.widgets_inner_padding, 0, 0)
}

local text_widget = wibox.widget {
    {
        id = 'text',
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
    -- mouse_hover color highlight
    icon_widget:get_children_by_id('icon')[1]:set_markup_silently('<span foreground="'..beautiful.fg_normal_hover..'">'..icon..'</span>')
    text_widget:get_children_by_id('text')[1].format = '<span foreground="'..beautiful.fg_normal_hover..'">%H:%M</span>'

    local w = capi.mouse.current_wibox
    old_cursor, old_wibox = w.cursor, w
    w.cursor = "hand1"
end)
clock_widget:connect_signal("mouse::leave", function()
    -- no mouse_hover color highlight
    icon_widget:get_children_by_id('icon')[1]:set_markup_silently(icon)
    text_widget:get_children_by_id('text')[1].format = "%H:%M"

    if old_wibox then
        old_wibox.cursor = old_cursor
        old_wibox = nil
    end
end)

clock_widget:buttons(gears.table.join(
    awful.button({}, 1, calendar.toggle_calendar)
))

local widget_keys = gears.table.join(
    awful.key({ variables.modkey }, "c", calendar.toggle_calendar,
    {description = "show the calendar menu", group = "launcher"})
)

capi.root.keys(gears.table.join(capi.root.keys(), widget_keys))

return clock_widget
