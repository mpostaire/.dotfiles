local wibox = require("wibox")
local awful = require("awful")
local gears = require("gears")
local base_panel_widget = require("widgets.panel.base")
local variables = require("config.variables")
local calendar = require("popups.calendar")
local capi = {root = root}

local icon = ""

return function(format)
    local widget = base_panel_widget:new(icon, wibox.widget.textclock(format))

    widget:buttons(gears.table.join(
        awful.button({}, 1, calendar.toggle_calendar)
    ))

    local widget_keys = gears.table.join(
        awful.key({ variables.modkey }, "c", calendar.toggle_calendar,
        {description = "show the calendar menu", group = "launcher"})
    )

    capi.root.keys(gears.table.join(capi.root.keys(), widget_keys))

    return widget
end
