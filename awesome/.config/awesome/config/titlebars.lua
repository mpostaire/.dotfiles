local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")
local clientmenu = require("popups.clientmenu")
local color = require("themes.color")
local helpers = require("util.helpers")
local capi = {client = client}

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
        bg = capi.client.focus == c and colors.bg_focus or colors.bg,
        widget = wibox.container.background
    }

    button:buttons(gears.table.join(
        awful.button({ }, 1, nil, function()
            cmd(c, button)
        end)
    ))

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
capi.client.connect_signal("request::titlebars", function(c)
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
        -- Title
        buttons = buttons,
        align  = "center",
        widget = awful.titlebar.widget.titlewidget(c)
    }

    local right_contents = {
        gen_text_button(c, icons[4], window_minimize, buttons_colors),
        gen_text_button(c, c.maximized and icons[3] or icons[2], window_maximize, buttons_colors),
        gen_text_button(c, icons[1], window_close, close_colors),
        layout = wibox.layout.fixed.horizontal
    }

    -- bug: resize does not shrink client title first but buttons and icons
    --      I'm not sure there is a fix fore that. there is a github issue but its
    --      current resolution seems to have the same problem
    -- fix? try using constraint layout with strategy property (check doc)
    awful.titlebar(c, {size = beautiful.wibar_height - beautiful.border_width}):setup {
        {
            { -- hacky way of making Title truly centered
                -- Left
                left_contents,
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
                -- Right
                right_contents,
                layout = wibox.layout.align.horizontal
            },
            -- expand = "outside", --- uncomment this for true center but it causes bug noted at line 59
            layout = wibox.layout.align.horizontal
        },
        bottom = beautiful.border_width,
        widget = wibox.container.margin
    }
end)
