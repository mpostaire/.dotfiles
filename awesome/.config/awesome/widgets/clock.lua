local wibox = require("wibox")
local beautiful = require("beautiful")
local awful = require("awful")
local gears = require("gears")
local variables = require("config.variables")
local dpi = require("beautiful.xresources").apply_dpi

local icons = {
    clock = "",
    prev = "",
    next = ""
}

local icon_widget = wibox.widget {
    {
        id = 'icon',
        markup = icons.clock,
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

local prev_widget = wibox.widget {
    markup = icons.prev,
    font = 'Material Icons 16',
    align = 'right',
    widget = wibox.widget.textbox
}
local next_widget = wibox.widget {
    markup = icons.next,
    font = 'Material Icons 16',
    align = 'right',
    widget = wibox.widget.textbox
}

local calendar = wibox.widget {
    homogeneous = true,
    spacing = dpi(6),
    forced_num_cols = 7,
    layout = wibox.layout.grid.vertical,
}

local function generate_header_widget(cal)
    local month_widget = wibox.widget {
        align = "center",
        forced_width = 120,
        widget = wibox.widget.textbox
    }
    cal:add(prev_widget)
    cal:add_widget_at(month_widget, 1, 2, 1, 5)
    cal:add(next_widget)
    return month_widget
end

local function generate_header(widget, month, year)
    local date = os.date("*t")

    if month == date.month and year == date.year then
        widget.markup = '<span foreground="'..beautiful.green..'">'..os.date("%a %d %b %Y")..'</span>'
    else
        widget.markup = '<span foreground="'..beautiful.green..'">'..os.date("%B", os.time({month=month, day=1, year=2012}))..' '..year..'</span>'
    end
end

local function get_day_names()
    local day_names = {}
    for i = 6, 12 do
        day_names[i - 5] = string.sub(os.date("%a", os.time({month=2, day=i, year=2012})), 0, -3)
    end
    return day_names
end

local function generate_day_names_row(cal)
    local day_names = get_day_names()
    for _,v in ipairs(day_names) do
        cal:add(wibox.widget {
            markup = '<span weight="bold" foreground="'..beautiful.white_alt..'">'..v..'</span>',
            align = "right",
            widget = wibox.widget.textbox
        })
    end
end

local function is_leap_year(year)
    return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
end
-- returns the number of days in a given month and year
local function get_days_in_month(month, year)
    return month == 2 and is_leap_year(year) and 29 or ("\31\28\31\30\31\30\31\31\30\31\30\31"):byte(month)
end
local function get_first_day_in_month(month, year)
    local first_day = (os.date('*t', os.time{day = 1, month = month, year = year})['wday'] + 6) % 7
    if first_day == 0 then
        return 7
    else
        return first_day
    end
end

local function generate_day_widgets(cal)
    local day_widgets = {}
    for i = 1, 42 do
        table.insert(day_widgets, wibox.widget {
            align = 'right',
            widget = wibox.widget.textbox
        })
        cal:add(day_widgets[i])
    end
    return day_widgets
end

local function generate_days(widgets, month, year)
    local num_days = get_days_in_month(month, year)
    local first_day = get_first_day_in_month(month, year)
    local prev_month_num_days
    if month == 1 then
        prev_month_num_days = get_days_in_month(12, year - 1)
    else
        prev_month_num_days = get_days_in_month(month - 1, year)
    end
    local date = os.date("*t")

    for k,v in ipairs(widgets) do
        if k < first_day then
            local num = prev_month_num_days - (first_day - k) + 1
            if date.month == month - 1 and date.year == year and num == date.day then
                v.markup = '<span weight="bold" foreground="'..beautiful.blue..'">'..num..'</span>'
            else
                v.markup = '<span foreground="'..beautiful.black_alt..'">'..num..'</span>'
            end
        elseif k - first_day < num_days then
            local num = k - first_day + 1
            if date.month == month and date.year == year and num == date.day then
                v.markup = '<span weight="bold" foreground="'..beautiful.blue..'">'..num..'</span>'
            elseif k % 7 == 0 or k % 7 == 6 then
                v.markup = '<span foreground="'..beautiful.yellow_alt..'">'..num..'</span>'
            else
                v.markup = num
            end
        else
            local num = k - num_days - first_day + 1
            if date.month == month - 1 and date.year == year and num == date.day then
                v.markup = '<span weight="bold" foreground="'..beautiful.blue..'">'..num..'</span>'
            else
                v.markup = '<span foreground="'..beautiful.black_alt..'">'..num..'</span>'
            end
        end
    end
end

local month_widget = generate_header_widget(calendar)
generate_day_names_row(calendar)
local day_widgets = generate_day_widgets(calendar)
local month, year

local function calendar_prev_month()
    if month == 1 then
        month = 12
        year = year - 1
    else
        month = month - 1
    end
    generate_header(month_widget, month, year)
    generate_days(day_widgets, month, year)
end

local function calendar_next_month()
    if month == 12 then
        month = 1
        year = year + 1
    else
        month = month + 1
    end
    generate_header(month_widget, month, year)
    generate_days(day_widgets, month, year)
end

prev_widget:buttons(gears.table.join(
    awful.button({}, 1, calendar_prev_month)
))
next_widget:buttons(gears.table.join(
    awful.button({}, 1, calendar_next_month)
))
calendar:buttons(gears.table.join(
    awful.button({}, 5, calendar_prev_month),
    awful.button({}, 4, calendar_next_month)
))

local popup = awful.popup {
    widget = {
        {
            calendar,
            margins = beautiful.notification_margin,
            widget = wibox.container.margin
        },
        color = beautiful.border_normal,
        left = beautiful.border_width,
        bottom = beautiful.border_width,
        widget = wibox.container.margin
    },
    placement = function(d, args)
        awful.placement.top_right(d, args)
        d.y = d.y + beautiful.wibar_height - beautiful.border_width
    end,
    visible = false,
    ontop = true
}

local keygrabber

local function show_calendar()
    local date = os.date("*t")
    month, year = date.month, date.year
    generate_header(month_widget, month, year)
    generate_days(day_widgets, month, year)
    popup.visible = true
    awful.keygrabber.run(keygrabber)
end

local function hide_calendar()
    popup.visible = false
    awful.keygrabber.stop(keygrabber)
end

local function toggle_calendar()
    if popup.visible then
        hide_calendar()
    else
        show_calendar()
    end
end

keygrabber = function(mod, key, event)
    if event == "release" then return end

    if key == 'Up' or key == 'Right' then
        calendar_next_month()
    elseif key == 'Down' or key == 'Left' then
        calendar_prev_month()
    elseif key == 'Escape' then
        toggle_calendar()
    elseif mod[2] == variables.modkey and key == 'c' then
        toggle_calendar()
    end
end

local old_cursor, old_wibox
clock_widget:connect_signal("mouse::enter", function()
    -- mouse_hover color highlight
    icon_widget:get_children_by_id('icon')[1]:set_markup_silently('<span foreground="'..beautiful.fg_normal_hover..'">'..icons.clock..'</span>')
    text_widget:get_children_by_id('text')[1].format = '<span foreground="'..beautiful.fg_normal_hover..'">%H:%M</span>'

    local w = mouse.current_wibox
    old_cursor, old_wibox = w.cursor, w
    w.cursor = "hand1"
end)
clock_widget:connect_signal("mouse::leave", function()
    -- no mouse_hover color highlight
    icon_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.clock)
    text_widget:get_children_by_id('text')[1].format = "%H:%M"

    if old_wibox then
        old_wibox.cursor = old_cursor
        old_wibox = nil
    end
end)

next_widget:connect_signal("mouse::enter", function()
    next_widget:set_markup_silently('<span foreground="'..beautiful.fg_normal_hover..'">'..icons.next..'</span>')

    local w = mouse.current_wibox
    old_cursor, old_wibox = w.cursor, w
    w.cursor = "hand1"
end)
next_widget:connect_signal("mouse::leave", function()
    next_widget:set_markup_silently(icons.next)

    if old_wibox then
        old_wibox.cursor = old_cursor
        old_wibox = nil
    end
end)
prev_widget:connect_signal("mouse::enter", function()
    prev_widget:set_markup_silently('<span foreground="'..beautiful.fg_normal_hover..'">'..icons.prev..'</span>')

    local w = mouse.current_wibox
    old_cursor, old_wibox = w.cursor, w
    w.cursor = "hand1"
end)
prev_widget:connect_signal("mouse::leave", function()
    prev_widget:set_markup_silently(icons.prev)

    if old_wibox then
        old_wibox.cursor = old_cursor
        old_wibox = nil
    end
end)


clock_widget:buttons(gears.table.join(
    awful.button({}, 1, toggle_calendar)
))

local widget_keys = gears.table.join(
    awful.key({ variables.modkey }, "c", toggle_calendar,
    {description = "show the calendar menu", group = "launcher"})
)

root.keys(gears.table.join(root.keys(), widget_keys))

return clock_widget
