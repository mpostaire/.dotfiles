local ruled = require("ruled")
local naughty = require("naughty")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local color = require("themes.util.color")
local dpi = beautiful.xresources.apply_dpi

-- TODO expand notification on mouse::enter (see all text) while hovering disable timeout, close notification on mouse::leave
--      (when notif appears below cursor do not close on mouse::leave and do not expand: wait for
--      mouse to leave once and then run this logic)

ruled.notification.connect_signal('request::rules', function()
    -- All notifications will match this rule.
    ruled.notification.append_rule {
        rule       = { },
        properties = {
            screen = awful.screen.preferred,
            implicit_timeout = 5,
            hover_timeout = 0 -- TODO doesn't work
        }
    }

    -- Add a red background for urgent notifications.
    ruled.notification.append_rule {
        rule       = { urgency = 'critical' },
        properties = { bg = '#ff0000', fg = '#ffffff', timeout = 0 }
    }
end)

naughty.connect_signal("request::display", function(n)
    -- TODO make actions more like buttons visually (figure if it's possible to do mouse hover highlighting)

    local actions_separator = wibox.widget {
        color = color.black_alt,
        span_ratio = 0.9,
        widget = wibox.widget.separator
    }

    local actions = wibox.widget {
        notification = n,
        base_layout = wibox.widget {
            spacing_widget = actions_separator,
            spacing = dpi(15),
            layout = wibox.layout.flex.horizontal
        },
        widget_template = {
            {
                {
                    {
                        id = 'text_role',
                        widget = wibox.widget.textbox
                    },
                    left = dpi(6),
                    right = dpi(6),
                    widget = wibox.container.margin
                },
                widget = wibox.container.place
            },
            widget = wibox.container.background
        },
        style = {
            underline_normal = false,
            underline_selected = true
        },
        widget = naughty.list.actions
    }

    local visible_actions = n.actions and #n.actions > 0
    local actions_separator_spacing = 0
    if visible_actions then
        actions_separator_spacing = dpi(15)
    end
    
    local notification_box = naughty.layout.box {
        notification = n,
        widget_template = {
            {
                {
                    {
                        {
                            {
                                naughty.widget.icon,
                                visible = n.icon or false,
                                right = beautiful.notification_margin,
                                widget = wibox.container.margin
                            },
                            {
                                {
                                    {
                                        markup = "<b>"..n.title.."</b>",
                                        font = beautiful.notification_font,
                                        widget = wibox.widget.textbox
                                    },
                                    naughty.widget.message,
                                    spacing = dpi(4),
                                    layout = wibox.layout.fixed.vertical
                                },
                                widget = wibox.container.place
                            },
                            layout = wibox.layout.fixed.horizontal,
                        },
                        {
                            actions,
                            visible = visible_actions,
                            widget = wibox.container.background
                        },
                        spacing_widget = actions_separator,
                        spacing = actions_separator_spacing,
                        layout = wibox.layout.fixed.vertical,
                    },
                    margins = beautiful.notification_margin,
                    widget = wibox.container.margin,
                },
                id = "background_role",
                widget = naughty.container.background,
            },
            strategy = "max",
            forced_width = beautiful.notification_max_width or dpi(512),
            height = beautiful.notification_max_height or dpi(128),
            widget = wibox.container.constraint,
        }
    }
    
    notification_box:connect_signal("mouse::enter", function()
        notification_box.widget.height = n.screen.geometry.height - notification_box.y - (beautiful.notification_spacing or dpi(2))
    end)

    notification_box:connect_signal("mouse::leave", function()
        if n.urgency ~= "critical" then
            n:destroy(2, false)
            n.is_expired = true
        end
    end)
end)