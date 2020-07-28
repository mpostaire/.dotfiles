local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")
local clientmenu = require("popups.clientmenu")
local color = require("themes.util.color")
local helpers = require("util.helpers")

awful.titlebar.enable_tooltip = false

-- TODO make my own clientbutton widgets

local icons = {
    "",
    "",
    "",
    ""
}

local icon_font = helpers.change_font_size(beautiful.icon_font, 14)

local buttons_colors = {
    bg = beautiful.titlebar_bg_normal,
    bg_focus = beautiful.titlebar_bg_focus,
    bg_hover = color.lighten_by(beautiful.titlebar_bg_focus, 0.25),
    bg_pressed = color.lighten_by(beautiful.titlebar_bg_focus, 0.35)
}
local close_colors = {
    bg = color.lighten_by(beautiful.titlebar_bg_normal, 0.15),
    bg_focus = color.darken_by(color.red, 0.25),
    bg_hover = color.darken_by(color.red, 0.15),
    bg_pressed = color.darken_by(color.red, 0.35)
}

-- Generates a client button created by a font glyph
local gen_text_button = function (c, symbol, cmd, colors)
    if not colors then colors = {} end

    local button = wibox.widget {
        {
            {
                align = "center",
                valign = "center",
                font = icon_font,
                markup = symbol,
                forced_height = 50,
                id = "icon",
                widget = wibox.widget.textbox
            },
            right = 10,
            left = 10,
            widget = wibox.container.margin
        },
        buttons = awful.button({ }, 1, nil, function()
            cmd(c, button)
        end),
        bg = _G.client.focus == c and colors.bg_focus or colors.bg,
        widget = wibox.container.background
    }

    button:connect_signal("mouse::enter", function()
        button.bg = colors.bg_hover
    end)
    button:connect_signal("mouse::leave", function()
        button.bg = colors.bg_focus
    end)
    button:connect_signal("button::press", function()
        button.bg = colors.bg_pressed
    end)
    button:connect_signal("button::release", function()
        button.bg = colors.bg_focus
    end)

    c:connect_signal("focus", function()
        button.bg = colors.bg_focus
    end)
    c:connect_signal("unfocus", function()
        button.bg = colors.bg
    end)

    return button
end

local function window_close(c)
    c:kill()
end
local function window_maximize(c, widget)
    c.maximized = not c.maximized
    c:raise()
    widget:get_children_by_id('icon')[1].markup = c.maximized and icons[3] or icons[2]
end
local function window_minimize(c)
    c.minimized = true
end

-- Add a titlebar if titlebars_enabled is set to true in the rules.
_G.client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})

            if helpers.double_click() then
                c.maximized = not c.maximized
                c:raise()
            else
                awful.mouse.client.move(c)
            end
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            clientmenu.launch(c)
        end)
    )

    local left_contents = {
        buttons = awful.button({ }, 1, function()
            clientmenu.launch(c, true)
        end),
        widget = awful.titlebar.widget.iconwidget(c),
    }

    local middle_contents = {
        align  = "center",
        widget = awful.titlebar.widget.titlewidget(c)
    }

    local right_contents = {
        gen_text_button(c, icons[4], window_minimize, buttons_colors),
        gen_text_button(c, c.maximized and icons[3] or icons[2], window_maximize, buttons_colors),
        gen_text_button(c, icons[1], window_close, close_colors),
        layout = wibox.layout.fixed.horizontal
    }

    awful.titlebar(c, {size = beautiful.wibar_height - beautiful.border_width}):setup {
        {
            middle_contents,
            {
                left_contents,
                {
                    buttons = buttons,
                    widget = wibox.container.background
                },
                right_contents,
                layout = wibox.layout.align.horizontal
            },
            layout = wibox.layout.stack
        },
        bottom = beautiful.border_width,
        widget = wibox.container.margin
    }
end)
