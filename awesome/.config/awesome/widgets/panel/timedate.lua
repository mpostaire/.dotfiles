local wibox = require("wibox")
local awful = require("awful")
local gears = require("gears")
local base_panel_widget = require("widgets.panel.base")
local variables = require("config.variables")
local calendar = require("popups.calendar")
local capi = {root = root}

local icon = ""

local timedate_widget = setmetatable({}, {__index = base_panel_widget})
timedate_widget.__index = timedate_widget

function timedate_widget:new(format)
    local widget = base_panel_widget:new(icon, wibox.widget.textclock(format))
    setmetatable(widget, timedate_widget)

    widget:enable_mouse_hover_effects(true, true)

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

return timedate_widget
