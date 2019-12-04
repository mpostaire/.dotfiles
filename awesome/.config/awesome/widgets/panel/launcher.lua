local wibox = require("wibox")
local beautiful = require("beautiful")
local awful = require("awful")
local gears = require("gears")
local applauncher = require("popups.applauncher")
local capi = {mouse = mouse}

return function()
    local widget = wibox.widget {
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

    widget:buttons(gears.table.join(
        awful.button({}, 1, function() applauncher.run(true) end)
    ))

    local old_cursor, old_wibox
    widget:connect_signal("mouse::enter", function()
        local w = capi.mouse.current_wibox
        old_cursor, old_wibox = w.cursor, w
        w.cursor = "hand2"
    end)
    widget:connect_signal("mouse::leave", function()
        if old_wibox then
            old_wibox.cursor = old_cursor
            old_wibox = nil
        end
    end)

    return widget
end
