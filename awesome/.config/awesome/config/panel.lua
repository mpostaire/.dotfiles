local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")
local widgets = require("widgets")

awful.screen.connect_for_each_screen(function(s)
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
                wibox.widget.systray(),
                -- widgets.archupdates(true), -- it stresses me so it's disabled for now :)
                widgets.network(),
                widgets.timedate("%H:%M"),
                widgets.group({
                    widgets.brightness(false),
                    widgets.volume(false),
                    "separator",
                    widgets.player(),
                    "separator",
                    widgets.battery(),
                    widgets.power()
                }),
                wibox.container.margin(_, 4),
                s.mylayoutbox
            },
        },
        bottom = beautiful.border_width,
        color = beautiful.border_normal,
        widget = wibox.container.margin
    }
end)
