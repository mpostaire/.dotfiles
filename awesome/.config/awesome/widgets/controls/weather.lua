local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")
local dpi = require("beautiful.xresources").apply_dpi
local helpers = require("util.helpers")
local variables = require("config.variables")
local capi = {mouse = mouse}

local icons = {
    day = {
        ["☀️"] = "",
        ["☁️"] = "",
        ["⛅️"] = "",
        ["🌫"] = "",
        ["🌨"] = "",
        ["❄️"] = "",
        ["🌦"] = "",
        ["🌧"] = "",
        ["⛈"] = "",
        ["🌩"] = "",
        ["✨"] = ""
    },
    -- // TODO night icons unused for now (not an easy way to do this without json)
    night = {
        ["☀️"] = "",
        ["☁️"] = "",
        ["⛅️"] = "",
        ["🌫"] = "",
        ["🌨"] = "",
        ["❄️"] = "",
        ["🌦"] = "",
        ["🌧"] = "",
        ["⛈"] = "",
        ["🌩"] = "",
        ["✨"] = ""
    },
    location = '<span foreground="'..beautiful.red_alt..'"> </span>'
}

return function(args)
    if not args then args = {} end
    local location = args.location or "Paris"

    local short_locale = string.sub(variables.locale, 1, 2)
    local cmd = 'curl "'..short_locale..'.wttr.in/'..location..'?format=%c;%C;%h;%t;%w;%l;%m;%p;%P"'

    local icon_widget = wibox.widget {
        font = helpers.change_font_size(beautiful.nerd_font, 30),
        widget = wibox.widget.textbox
    }

    local location_widget = wibox.widget {
        widget = wibox.widget.textbox
    }

    local temperature_widget = wibox.widget {
        font = helpers.change_font_size(beautiful.font, 18),
        widget = wibox.widget.textbox
    }

    local humidity_widget = wibox.widget {
        align = "right",
        widget = wibox.widget.textbox
    }

    local precipitations_widget = wibox.widget {
        align = "right",
        widget = wibox.widget.textbox
    }

    local wind_widget = wibox.widget {
        align = "right",
        widget = wibox.widget.textbox
    }

    local left_grid_layout = wibox.widget {
        homogeneous = false,
        layout = wibox.layout.grid.vertical,
    }
    left_grid_layout:add_widget_at(wibox.container.margin(icon_widget, _, dpi(10)), 1, 1, 3, 1)
    left_grid_layout:add_widget_at(wibox.container.margin(temperature_widget, _, dpi(10)), 1, 2, 2, 1)
    left_grid_layout:add_widget_at(wibox.container.margin(location_widget, _, dpi(10)), 3, 2)

    local right_grid_layout = wibox.widget {
        homogeneous = false,
        expand = false,
        layout = wibox.layout.grid.horizontal
    }
    right_grid_layout:add_widget_at(wibox.widget.textbox("Précip. : "), 1, 1)
    right_grid_layout:add_widget_at(wibox.widget.textbox("Humid.  : "), 2, 1)
    right_grid_layout:add_widget_at(wibox.widget.textbox("Vent    : "), 3, 1)
    right_grid_layout:add_widget_at(precipitations_widget, 1, 2)
    right_grid_layout:add_widget_at(humidity_widget, 2, 2)
    right_grid_layout:add_widget_at(wind_widget, 3, 2)

    local weather_widget = wibox.widget {
        {
            left_grid_layout,
            nil,
            {
                right_grid_layout,
                fg = beautiful.white_alt,
                widget = wibox.container.background
            },
            layout = wibox.layout.align.horizontal
        },
        right = dpi(10),
        widget = wibox.container.margin
    }

    local data = {}

    local function get_weather_icon()
        if data[1] and icons.day[data[1]] then return icons.day[data[1]] end
        return "Err"
    end

    -- every 2 hours
    local _, timer = awful.widget.watch(cmd, 7200, function(_, stdout)
        data = gears.string.split(stdout, ";")
        icon_widget.text = get_weather_icon()
        location_widget.markup = icons.location..data[6]
        humidity_widget.text = data[3]
        temperature_widget.text = data[4]
        wind_widget.text = data[5]
        precipitations_widget.text = data[8]
    end)
    timer:emit_signal("timeout")

    weather_widget.type = "control_widget"

    return weather_widget
end

-- weather_widget:buttons(gears.table.join(
--     awful.button({}, 5, calendar_prev_month),
--     awful.button({}, 4, calendar_next_month)
-- ))
