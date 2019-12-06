local wibox = require("wibox")
local base_panel_widget = require("widgets.panel.base")
local calendar = require("widgets.controls.calendar")
local weather = require("widgets.controls.weather")

local icon = ""

return function(format)
    local widget = base_panel_widget:new{icon = icon, label = wibox.widget.textclock(format), control_widget = calendar{left_widget = weather{location = "Wavre,Belgique"}}}

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
