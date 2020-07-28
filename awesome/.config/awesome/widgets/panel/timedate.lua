local wibox = require("wibox")
local beautiful = require("beautiful")
local color = require("themes.util.color")
local base_panel_widget = require("widgets.panel.base")
local calendar = require("widgets.controls.calendar")
local weather = require("widgets.controls.weather")
local notifcenter = require("widgets.controls.notifcenter")

local icon = ""

return function(format)
    local separator = wibox.widget {
        color = color.black_alt,
        span_ratio = 0.9,
        orientation = "horizontal",
        widget = wibox.widget.separator
    }

    local weather_widget = weather()
    
    local left_widget
    if weather_widget.visible == false then
        left_widget = wibox.widget {
            notifcenter(),
            fill_space = true,
            layout = wibox.layout.fixed.vertical
        }
    else
        left_widget = wibox.widget {
            weather_widget,
            notifcenter(),
            spacing = 35,
            spacing_widget = separator,
            fill_space = true,
            layout = wibox.layout.fixed.vertical
        }
    end

    local textclock = wibox.widget.textclock(format)
    
    local widget = base_panel_widget {
        icon = icon,
        label = textclock,
        control_widget = calendar {
            left_widget = left_widget
        }
    }

    _G.awesome.connect_signal("unlock", function() textclock:force_update() end)

    -- widget:buttons(gears.table.join(
    --     awful.button({}, 1, calendar.toggle_calendar)
    -- ))

    -- local widget_keys = gears.table.join(
    --     awful.key({ variables.modkey }, "c", calendar.toggle_calendar,
    --     {description = "show the calendar menu", group = "launcher"})
    -- )

    -- _G.root.keys(gears.table.join(_G.root.keys(), widget_keys))

    return widget
end
