local ruled = require("ruled")
local naughty = require("naughty")
local awful = require("awful")

-- TODO bold title

ruled.notification.connect_signal('request::rules', function()
    -- All notifications will match this rule.
    ruled.notification.append_rule {
        rule       = { },
        properties = {
            screen           = awful.screen.preferred,
            implicit_timeout = 5,
        }
    }

    -- Add a red background for urgent notifications.
    ruled.notification.append_rule {
        rule       = { urgency = 'critical' },
        properties = { bg = '#ff0000', fg = '#ffffff', timeout = 0 }
    }
end)

-- TODO make title always bold by default

-- {
--     {
--         {
--             {
--                 {
--                     naughty.widget.icon,
--                     {
--                         naughty.widget.title,
--                         naughty.widget.message,
--                         spacing = 4,
--                         layout  = wibox.layout.fixed.vertical,
--                     },
--                     fill_space = true,
--                     spacing    = 4,
--                     layout     = wibox.layout.fixed.horizontal,
--                 },
--                 naughty.list.actions,
--                 spacing = 10,
--                 layout  = wibox.layout.fixed.vertical,
--             },
--             margins = beautiful.notification_margin,
--             widget  = wibox.container.margin,
--         },
--         id     = "background_role",
--         widget = naughty.container.background,
--     },
--     strategy = "max",
--     width    = width(beautiful.notification_max_width
--         or beautiful.xresources.apply_dpi(500)),
--     widget   = wibox.container.constraint,
-- }

naughty.connect_signal("request::display", function(n)
    naughty.layout.box {
        notification = n,
        -- widget_template = {}
    }
end)
