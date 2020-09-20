local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")
local widgets = require("widgets")

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
                s.mytaglist,
                wibox.container.margin(_, 4)
            },
            s.mytasklist, -- Middle widget
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
                s.mylayoutbox
            },
        },
        bottom = beautiful.border_width,
        color = beautiful.border_normal,
        widget = wibox.container.margin
    }
end)
