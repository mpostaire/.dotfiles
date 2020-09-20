local ruled = require("ruled")
local naughty = require("naughty")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local color = require("themes.util.color")
local dpi = beautiful.xresources.apply_dpi

ruled.notification.connect_signal('request::rules', function()
    -- All notifications will match this rule.
    ruled.notification.append_rule {
        rule       = { },
        properties = {
            screen = awful.screen.preferred,
            implicit_timeout = 5,
            hover_timeout = 0 -- FIXME doesn't work
        }
    }

    -- Add a red background for urgent notifications.
    ruled.notification.append_rule {
        rule       = { urgency = 'critical' },
        properties = { bg = color.red_alt, fg = '#FFFFFF', timeout = 0 }
    }
end)

naughty.connect_signal("request::display", function(n)
    -- TODO make actions more like buttons visually (figure if it's possible to do mouse hover highlighting)

    local actions_separator = wibox.widget {
        color = color.black_alt,
        span_ratio = 0.9,
        widget = wibox.widget.separator
    }

    local visible_actions = n.actions and #n.actions > 0
    local actions_height = visible_actions and dpi(20) or 0
    local actions = wibox.widget {
        notification = n,
        base_layout = wibox.widget {
            spacing_widget = actions_separator,
            spacing = dpi(15),
            forced_height = actions_height,
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
                    top = dpi(10),
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

    local actions_separator_spacing = 0
    if visible_actions then
        actions_separator_spacing = dpi(15)
    end

    local icon_widget = wibox.widget {
        image = n.icon,
        widget = wibox.widget.imagebox
    }
    n:connect_signal("property::icon", function()
        icon_widget.image = n.icon
    end)

    local contents = wibox.widget {
        {
            {
                {
                    {
                        icon_widget,
                        strategy = "max",
                        width = beautiful.notification_icon_size or dpi(64),
                        height = beautiful.notification_icon_size or dpi(64),
                        widget = wibox.container.constraint
                    },
                    widget = wibox.container.place,
                },
                visible = n.icon or false,
                right = beautiful.notification_margin,
                widget = wibox.container.margin
            },
            {
                {
                    align = "left",
                    markup = "<b>"..n.title.."</b>",
                    font = beautiful.notification_font,
                    widget = wibox.widget.textbox
                },
                {
                    align = "left",
                    widget = naughty.widget.message,
                },
                spacing = dpi(4),
                layout = wibox.layout.fixed.vertical
            },
            layout = wibox.layout.fixed.horizontal
        },
        strategy = "max",
        height = beautiful.notification_max_height or dpi(128),
        widget = wibox.container.constraint,
    }
    
    local notification_box = naughty.layout.box {
        notification = n,
        border_width = beautiful.notification_border_width,
        border_color = beautiful.notification_border_color,
        bg = n.bg,
        fg = n.fg,
        widget_template = {
            {
                {
                    contents,
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
            forced_width = beautiful.notification_max_width or dpi(512),
            widget = wibox.container.constraint,
        }
    }

    notification_box:connect_signal("mouse::enter", function()
        contents.height = n.screen.geometry.height - notification_box.y - (actions_height > 0 and actions_height + dpi(15) or 0)
                            - (beautiful.notification_spacing or dpi(4)) - 2 * (beautiful.notification_margin or 0)
    end)

    notification_box:connect_signal("mouse::leave", function()
        if n.urgency == "critical" then
            contents.height = beautiful.notification_max_height or dpi(128)
        else
            n:destroy(2, false)
            n.is_expired = true
        end
    end)
end)
