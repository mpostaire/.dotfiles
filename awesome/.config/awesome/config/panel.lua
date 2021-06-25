local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")
local widgets = require("widgets")
-- local appmenu = require("util.appmenu")

screen.connect_signal("request::desktop_decoration", function(s)
    -- Create the wibox
    s.mywibox = awful.wibar({position = "top", screen = s})

    -- Add widgets to the wibox
    s.mywibox:setup {
        {
            layout = wibox.layout.align.horizontal,
            { -- Left widgets
                layout = wibox.layout.fixed.horizontal,
                widgets.launcher(),
                widgets.taglist(s),
                wibox.container.margin(_, 4)
            },
            -- appmenu(),
            widgets.tasklist(s), -- Middle widget
            { -- Right widgets
                layout = wibox.layout.fixed.horizontal,
                wibox.container.margin(_, 4),
                widgets.systray(true),
                -- widgets.archupdates(true), -- it stresses me so it's disabled for now :)
                widgets.network(),
                widgets.timedate("%H:%M"),
                widgets.player(),
                widgets.brightness(false),
                widgets.volume(false),
                widgets.battery(),
                widgets.power(),
                wibox.container.margin(_, 4),
                widgets.layoutbox(s)
            },
        },
        bottom = beautiful.border_width,
        color = beautiful.border_normal,
        widget = wibox.container.margin
    }
end)
