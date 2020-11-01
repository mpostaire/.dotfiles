local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi
local helpers = require("util.helpers")
local color = require("themes.util.color")

local icons = {
    prev = "",
    next = ""
}

local fg_normal_hover = color.lighten_by(beautiful.fg_normal, 0.5)

local function get_day_names()
    local day_names = {}
    for i = 6, 12 do
        day_names[i - 5] = string.sub(os.date("%a", os.time({month = 2, day=i, year = 2012})), 0, -3)
    end
    return day_names
end

local function generate_day_names_row(cal)
    local day_names = get_day_names()
    for _,v in ipairs(day_names) do
        cal:add(wibox.widget {
            markup = '<span weight="bold" foreground="'..color.white_alt..'">'..v..'</span>',
            align = "center",
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

return function(args)
    if not args then args = {} end
    local left_widget = args.left_widget or nil

    local prev_widget = wibox.widget {
        markup = icons.prev,
        font = helpers.change_font_size(beautiful.icon_font, 14),
        align = 'center',
        widget = wibox.widget.textbox
    }
    local next_widget = wibox.widget {
        markup = icons.next,
        font = helpers.change_font_size(beautiful.icon_font, 14),
        align = 'center',
        widget = wibox.widget.textbox
    }

    local calendar_grid_widget = wibox.widget {
        homogeneous = true,
        spacing = dpi(12),
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
            widget.markup = '<span foreground="'..color.green..'">'..os.date("%a %d %b %Y")..'</span>'
        else
            widget.markup = '<span foreground="'..color.green..'">'..os.date("%B", os.time({month=month, day=1, year=2012}))..' '..year..'</span>'
        end
    end

    local function generate_day_widgets(cal)
        local day_widgets = {}
        for i = 1, 42 do
            table.insert(day_widgets, wibox.widget {
                align = 'center',
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
                    v.markup = '<span foreground="'..color.blue..'">'..num..'</span>'
                else
                    v.markup = '<span foreground="'..color.black_alt..'">'..num..'</span>'
                end
            elseif k - first_day < num_days then
                local num = k - first_day + 1
                if date.month == month and date.year == year and num == date.day then
                    v.markup = '<span weight="bold" foreground="'..color.blue..'">'..num..'</span>'
                elseif k % 7 == 0 or k % 7 == 6 then
                    v.markup = '<span foreground="'..color.yellow_alt..'">'..num..'</span>'
                else
                    v.markup = num
                end
            else
                local num = k - num_days - first_day + 1
                if date.month == month + 1 and date.year == year and num == date.day then
                    v.markup = '<span foreground="'..color.blue..'">'..num..'</span>'
                else
                    v.markup = '<span foreground="'..color.black_alt..'">'..num..'</span>'
                end
            end
        end
    end

    local month_widget = generate_header_widget(calendar_grid_widget)
    generate_day_names_row(calendar_grid_widget)
    local day_widgets = generate_day_widgets(calendar_grid_widget)
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

    prev_widget:buttons({
        awful.button({}, 1, calendar_prev_month)
    })
    next_widget:buttons({
        awful.button({}, 1, calendar_next_month)
    })
    calendar_grid_widget:buttons({
        awful.button({}, 5, calendar_prev_month),
        awful.button({}, 4, calendar_next_month)
    })

    local old_cursor, old_wibox
    next_widget:connect_signal("mouse::enter", function()
        next_widget:set_markup_silently('<span foreground="'..fg_normal_hover..'">'..icons.next..'</span>')

        local w = _G.mouse.current_wibox
        old_cursor, old_wibox = w.cursor, w
        w.cursor = "hand2"
    end)
    next_widget:connect_signal("mouse::leave", function()
        next_widget:set_markup_silently(icons.next)

        if old_wibox then
            old_wibox.cursor = old_cursor
            old_wibox = nil
        end
    end)
    prev_widget:connect_signal("mouse::enter", function()
        prev_widget:set_markup_silently('<span foreground="'..fg_normal_hover..'">'..icons.prev..'</span>')

        local w = _G.mouse.current_wibox
        old_cursor, old_wibox = w.cursor, w
        w.cursor = "hand2"
    end)
    prev_widget:connect_signal("mouse::leave", function()
        prev_widget:set_markup_silently(icons.prev)

        if old_wibox then
            old_wibox.cursor = old_cursor
            old_wibox = nil
        end
    end)
    local green_hover = color.lighten_by(color.green, 0.5)
    month_widget:connect_signal("mouse::enter", function()
        month_widget:set_markup_silently('<span foreground="'..green_hover..'">'..month_widget.text..'</span>')

        local w = _G.mouse.current_wibox
        old_cursor, old_wibox = w.cursor, w
        w.cursor = "hand2"
    end)
    month_widget:connect_signal("mouse::leave", function()
        month_widget:set_markup_silently('<span foreground="'..color.green..'">'..month_widget.text..'</span>')

        if old_wibox then
            old_wibox.cursor = old_cursor
            old_wibox = nil
        end
    end)

    local function init_current_month()
        local date = os.date("*t")
        month, year = date.month, date.year
        generate_header(month_widget, month, year)
        generate_days(day_widgets, month, year)
    end

    month_widget:buttons({
        awful.button({}, 1, function()
            init_current_month()
            month_widget:set_markup_silently('<span foreground="'..green_hover..'">'..month_widget.text..'</span>')
        end)
    })

    local calendar_widget = calendar_grid_widget
    if left_widget then
        local separator = wibox.widget {
            color = color.black_alt,
            span_ratio = 0.9,
            orientation = "vertical",
            widget = wibox.widget.separator
        }
        left_widget.forced_width = dpi(360)
        calendar_widget = wibox.widget {
            left_widget,
            calendar_grid_widget,
            spacing = dpi(35),
            spacing_widget = separator,
            layout = wibox.layout.fixed.horizontal
        }
    end

    calendar_widget.show_callback = init_current_month

    init_current_month()

    calendar_widget.type = "control_widget"

    return calendar_widget
end
