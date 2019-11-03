local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")
local client_menu = require("popups.client_menu")
local color = require("util.color")
local capi = {client = client}

awful.titlebar.enable_tooltip = false

-- TODO make my own clientbutton widgets

local titlebar_bg_focus = beautiful.titlebar_bg_focus
local titlebar_bg_normal = beautiful.titlebar_bg_normal

beautiful.titlebar_bg_focus = "#00000000"
beautiful.titlebar_bg_normal = "#00000000"

-- Add a titlebar if titlebars_enabled is set to true in the rules.
capi.client.connect_signal("request::titlebars", function(c)
    -- TODO: make this not show a titlebar if client specifies it

    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            -- client_menu.hide()
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            client_menu.show(c)
        end)
    )

    local titlebar_rounded_container = wibox.widget {
        shape = function(cr, width, height)
            gears.shape.partially_rounded_rect(cr, width, height, true, true, false, false, 5)
        end,
        bg = titlebar_bg_focus,
        widget = wibox.container.background
    }

    -- -- TODO find a way to make this crop
    -- local outline = wibox.widget {
    --     color  = color.lighten_by(titlebar_bg_focus, 0.5),
    --     forced_height = 1,
    --     span_ratio = 0.995, -- very ugly and don't work for every client size
    --     widget = wibox.widget.separator
    -- }

    awful.titlebar(c):setup {
        {
            -- outline,
            -- {
                { -- Left
                    awful.titlebar.widget.iconwidget(c),
                    buttons = buttons,
                    layout  = wibox.layout.fixed.horizontal
                },
                { -- Middle
                    { -- Title
                        align  = "center",
                        widget = awful.titlebar.widget.titlewidget(c)
                    },
                    buttons = buttons,
                    layout  = wibox.layout.flex.horizontal
                },
                { -- Right
                    -- awful.titlebar.widget.floatingbutton (c),
                    -- awful.titlebar.widget.stickybutton   (c),
                    -- awful.titlebar.widget.ontopbutton    (c),
                    awful.titlebar.widget.minimizebutton (c),
                    awful.titlebar.widget.maximizedbutton(c),
                    awful.titlebar.widget.closebutton    (c),
                    layout = wibox.layout.fixed.horizontal()
                },
                layout = wibox.layout.align.horizontal
            -- },
            -- layout = wibox.layout.fixed.vertical
        },
        widget = titlebar_rounded_container
    }

    if beautiful.titlebar_bg_focus and beautiful.titlebar_bg_normal then
        c:connect_signal("focus", function()
            titlebar_rounded_container.bg = titlebar_bg_focus
            -- outline.color = color.lighten_by(titlebar_bg_focus, 0.5)
        end)
        c:connect_signal("unfocus", function()
            titlebar_rounded_container.bg = titlebar_bg_normal
            -- outline.color = color.lighten_by(titlebar_bg_normal, 0.25)
        end)
    end

    for _,v in pairs({"left", "right", "bottom"}) do
        local border = wibox.widget {
            bg = titlebar_bg_focus,
            widget = wibox.container.background
        }

        -- TODO handle resize buttons
        -- local border_buttons = gears.table.join(
        --     awful.button({ }, 1, function()
        --         c:emit_signal("request::activate", "titlebar", {raise = true})
        --         c:relative_move(c.x, c.y, )
        --     end)
        -- )

        awful.titlebar(c, {position = v, size = beautiful.border_width}):setup {
            {
                -- buttons = border_buttons,
                layout = wibox.layout.align.vertical
            },
            widget = border
        }

        c:connect_signal("focus", function()
            border.bg = titlebar_bg_focus
        end)
        c:connect_signal("unfocus", function()
            border.bg = titlebar_bg_normal
        end)
    end
end)
