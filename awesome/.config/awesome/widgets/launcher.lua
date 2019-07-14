local wibox = require("wibox")
local beautiful = require("beautiful")
local rofi = require("util.rofi")
local awful = require("awful")
local gears = require("gears")

local launcher_widget = wibox.widget {
    {
        {
            {
                image = beautiful.awesome_icon_wibar,
                widget = wibox.widget.imagebox
            },
            margins = 6,
            widget = wibox.container.margin
        },
        bg = beautiful.red,
        widget = wibox.container.background
    },
    right = beautiful.wibar_widgets_padding,
    widget = wibox.container.margin
}

launcher_widget:buttons(gears.table.join(
    awful.button({}, 1, function() rofi.launcher_menu("drun") end),
    awful.button({}, 3, function() rofi.launcher_menu("window") end)
))

local old_cursor, old_wibox
launcher_widget:connect_signal("mouse::enter", function()
    local w = mouse.current_wibox
    old_cursor, old_wibox = w.cursor, w
    w.cursor = "hand1"
end)
launcher_widget:connect_signal("mouse::leave", function()
    if old_wibox then
        old_wibox.cursor = old_cursor
        old_wibox = nil
    end
end)

return launcher_widget
