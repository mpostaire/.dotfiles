local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")
local clientmenu = require("popups.clientmenu")
local color = require("util.color")
local capi = {client = client}

awful.titlebar.enable_tooltip = false

-- TODO make my own clientbutton widgets

-- Add a titlebar if titlebars_enabled is set to true in the rules.
capi.client.connect_signal("request::titlebars", function(c)
    -- TODO: make this not show a titlebar if client specifies it

    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            clientmenu.launch(c)
        end)
    )

    local outline = wibox.widget {
        color  = color.lighten_by(beautiful.titlebar_bg_normal, 0.15),
        forced_height = beautiful.border_width,
        widget = wibox.widget.separator
    }

    local left_contents = {
        buttons = awful.button({ }, 1, function()
            clientmenu.launch(c, true)
        end),
        widget = awful.titlebar.widget.iconwidget(c),
    }

    local middle_contents = {
        -- Title
        buttons = buttons,
        align  = "center",
        widget = awful.titlebar.widget.titlewidget(c)
    }

    local right_contents = {
        -- awful.titlebar.widget.floatingbutton (c),
        -- awful.titlebar.widget.stickybutton   (c),
        -- awful.titlebar.widget.ontopbutton    (c),
        awful.titlebar.widget.minimizebutton (c),
        awful.titlebar.widget.maximizedbutton(c),
        awful.titlebar.widget.closebutton    (c),
        layout = wibox.layout.fixed.horizontal
    }

    -- bug: resize does not shrink client title first but buttons and icons
    --      I'm not sure there is a fix fore that. there is a github issue but its
    --      current resolution seems to have the same problem

    awful.titlebar(c, {size = beautiful.titlebar_height}):setup {
        outline,
        {
            {
                { -- hacky way of making Title truly centered
                    { -- Left
                        left_contents,
                        left = beautiful.border_width,
                        right = beautiful.border_width,
                        widget = wibox.container.margin
                    },
                    {
                        buttons = buttons,
                        layout = wibox.layout.flex.horizontal
                    },
                    {
                        buttons = buttons,
                        layout = wibox.layout.flex.horizontal
                    },
                    layout = wibox.layout.align.horizontal
                },
                middle_contents, -- Middle
                { -- hacky way of making Title truly centered
                    {
                        buttons = buttons,
                        layout = wibox.layout.flex.horizontal
                    },
                    {
                        buttons = buttons,
                        layout = wibox.layout.flex.horizontal
                    },
                    { -- Right
                        right_contents,
                        left = beautiful.border_width,
                        right = beautiful.border_width,
                        widget = wibox.container.margin
                    },
                    layout = wibox.layout.align.horizontal
                },
                -- expand = "outside", --- uncomment this for true center but it causes bug noted at line 59
                layout = wibox.layout.align.horizontal
            },
            bottom = beautiful.border_width,
            widget = wibox.container.margin
        },
        layout = wibox.layout.fixed.vertical
    }
end)
