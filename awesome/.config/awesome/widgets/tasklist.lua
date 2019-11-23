local awful = require("awful")
local gears = require("gears")
local dpi = require("beautiful.xresources").apply_dpi
local wibox = require("wibox")
local clientmenu = require("popups.clientmenu")
local capi = {client = client}

-- launched programs widget mouse handling
local tasklist_buttons = gears.table.join(
    awful.button({ }, 1, function (c)
        if c == capi.client.focus then
            c.minimized = true
        else
            c:emit_signal(
                "request::activate",
                "tasklist",
                {raise = true}
            )
        end
    end),
    awful.button({ }, 3, function(c)
        clientmenu.launch(c)
    end),
    awful.button({ }, 4, function ()
        awful.client.focus.byidx(1)
    end),
    awful.button({ }, 5, function ()
        awful.client.focus.byidx(-1)
    end)
)

-- Place a widget for each screen
awful.screen.connect_for_each_screen(function(s)
    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
        widget_template = {
            {
                nil,
                {
                    {
                        {
                            id = 'clienticon',
                            forced_height = dpi(22),
                            forced_width = dpi(22),
                            widget = awful.widget.clienticon,
                        },
                        valign = 'center',
                        widget = wibox.container.place
                    },
                    {
                        id = 'text_role',
                        widget = wibox.widget.textbox,
                    },
                    spacing = dpi(4),
                    layout = wibox.layout.fixed.horizontal
                },
                nil,
                expand = "outside",
                layout = wibox.layout.align.horizontal
            },
            id = 'background_role',
            widget = wibox.container.background,
            create_callback = function(self, c, index, objects) --luacheck: no unused
                self:get_children_by_id('clienticon')[1].client = c
            end
        }
    }
end)
