local wibox = require("wibox")
local beautiful = require("beautiful")
local base_panel_widget = require("widgets.panel.base")
local calendar = require("widgets.controls.calendar")
local weather = require("widgets.controls.weather")
local notifcenter = require("widgets.controls.notifcenter")

local icon = ""

return function(format)
    local separator = wibox.widget {
        color = beautiful.black_alt,
        span_ratio = 0.9,
        orientation = "horizontal",
        widget = wibox.widget.separator
    }

    local left_widget = wibox.widget {
        weather(),
        notifcenter(),
        spacing = 35,
        spacing_widget = separator,
        fill_space = true,
        layout = wibox.layout.fixed.vertical
    }

    local widget = base_panel_widget {
        icon = icon,
        label = wibox.widget.textclock(format),
        control_widget = calendar {
            left_widget = left_widget
        }
    }

    -- widget:buttons(gears.table.join(
    --     awful.button({}, 1, calendar.toggle_calendar)
    -- ))

    -- local widget_keys = gears.table.join(
    --     awful.key({ variables.modkey }, "c", calendar.toggle_calendar,
    --     {description = "show the calendar menu", group = "launcher"})
    -- )

    -- capi.root.keys(gears.table.join(capi.root.keys(), widget_keys))

    return widget
end
