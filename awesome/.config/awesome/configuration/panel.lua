local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local wibox = require("wibox")

local widgets = require("widgets")

-- MOVE BELOW WALLPAPER BLOCK INTO ITS OWN FILE
-- WALLPAPER

-- {{{ Wibar
local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end
-- sets it for each screen
awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)
end)
-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)
-- WALLPAPER END

awful.screen.connect_for_each_screen(function(s)
    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s, height = beautiful.wibar_height, })

    -- Add widgets to the wibox
    s.mywibox:setup {
        {
            layout = wibox.layout.align.horizontal,
            { -- Left widgets
                layout = wibox.layout.fixed.horizontal,
                widgets.launcher,
                s.mytaglist,
                widgets.music,
                s.mypromptbox,
            },
            s.mytasklist, -- Middle widget
            { -- Right widgets
                layout = wibox.layout.fixed.horizontal,
                wibox.widget.systray(),
                -- widgets.archupdates, -- commented to hide it for now (when I translate wigets in OOP, this will be prettier)
                widgets.network,
                widgets.brightness,
                widgets.volume,
                widgets.battery,
                widgets.clock,
                s.mylayoutbox,
            },
        },
        bottom = beautiful.wibar_bottom_border_width,
        color = beautiful.wibar_border_color,
        widget = wibox.container.margin,
    }
end)
-- }}}
