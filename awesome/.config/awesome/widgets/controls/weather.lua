local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gstring = require("gears.string")
local dpi = require("beautiful.xresources").apply_dpi
local helpers = require("util.helpers")
local variables = require("config.variables")
local network = require("util.network")

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
    local location = args.location or "Paris,France"

    local short_locale = string.sub(variables.locale, 1, 2)
    local cmd = 'curl "'..short_locale..'.wttr.in/'..location..'?format=%c;%C;%h;%t;%w;%l;%m;%p;%P"'

    local icon_widget = wibox.widget {
        text = "",
        font = helpers.change_font_size(beautiful.nerd_font, 26),
        widget = wibox.widget.textbox
    }

    local location_widget = wibox.widget {
        text = "Pas de données météo...",
        widget = wibox.widget.textbox
    }

    local temperature_widget = wibox.widget {
        text = "...°C",
        font = helpers.change_font_size(beautiful.font, 18),
        widget = wibox.widget.textbox
    }

    local humidity_widget = wibox.widget {
        text = "...",
        align = "right",
        widget = wibox.widget.textbox
    }

    local precipitations_widget = wibox.widget {
        text = "...",
        align = "right",
        widget = wibox.widget.textbox
    }

    local wind_widget = wibox.widget {
        text = "...",
        align = "right",
        widget = wibox.widget.textbox
    }

    local left_grid_layout = wibox.widget {
        homogeneous = false,
        layout = wibox.layout.grid.vertical,
    }
    left_grid_layout:add_widget_at(wibox.container.margin(icon_widget, 0, dpi(10)), 1, 1, 3, 1)
    left_grid_layout:add_widget_at(wibox.container.margin(temperature_widget, 0, dpi(10)), 1, 2, 2, 1)
    left_grid_layout:add_widget_at(wibox.container.margin(location_widget, 0, dpi(10)), 3, 2)

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

    -- every hour
    local _, timer = awful.widget.watch(cmd, 3600, function(_, stdout)
        data = gstring.split(stdout, ";")
        icon_widget.text = get_weather_icon()
        location_widget.markup = icons.location..gstring.split(data[6], ",")[1]
        humidity_widget.text = data[3]
        temperature_widget.text = data[4]
        wind_widget.text = data[5]
        precipitations_widget.text = data[8]
    end)

    network.on_properties_changed(function()
        -- // TODO when connection is back up from a state where it wasn't, update widget
        -- timer:emit_signal("timeout")
    end)

    weather_widget.type = "control_widget"

    return weather_widget
end