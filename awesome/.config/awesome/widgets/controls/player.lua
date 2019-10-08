local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local mpris = require("util.mpris")

local icons = {
    note = "",
    play = "",
    pause = "",
    prev = "",
    next = ""
}

local artist_widget = wibox.widget {
    text = "Artiste",
    forced_width = 175,
    forced_height = beautiful.font_height,
    widget = wibox.widget.textbox
}
local title_widget = wibox.widget {
    text = "Title",
    forced_width = 175,
    forced_height = beautiful.font_height,
    widget = wibox.widget.textbox
}
local prev_widget = wibox.widget {
    {
        {
            id = 'icon',
            align  = 'center',
            markup = icons.prev,
            widget = wibox.widget.textbox
        },
        margins = 5,
        widget = wibox.container.margin
    },
    widget = wibox.container.background
}
local playpause_widget = wibox.widget {
    {
        {
            id = 'icon',
            align  = 'center',
            markup = icons.play,
            widget = wibox.widget.textbox
        },
        margins = 5,
        widget = wibox.container.margin
    },
    widget = wibox.container.background
}
local next_widget = wibox.widget {
    {
        {
            id = 'icon',
            align  = 'center',
            markup = icons.next,
            widget = wibox.widget.textbox
        },
        margins = 5,
        widget = wibox.container.margin
    },
    widget = wibox.container.background
}
-- local progressbar_widget = wibox.widget {
--     bar_shape = gears.shape.rounded_rect,
--     bar_height = 2,
--     bar_color = gears.color.create_pattern({
--         type = "linear",
--         from = { -1, 0 },
--         to = { 0, 0 },
--         stops = { { 1, beautiful.fg_normal }, { 1, beautiful.bg_focus } }
--     }),
--     handle_color = beautiful.fg_normal,
--     handle_shape = gears.shape.circle,
--     handle_border_color = beautiful.border_color,
--     handle_border_width = 1,
--     value = 0,
--     forced_width = 150,
--     forced_height = 10,
--     widget = wibox.widget.slider,
-- }
-- progressbar_widget:connect_signal("property::value", function()
--     progressbar_widget.bar_color = gears.color.create_pattern({
--         type = "linear",
--         from = { -1, 0 },
--         to = { progressbar_widget.value * (progressbar_widget.forced_width / 100), 0 },
--         stops = { { 1, beautiful.fg_normal }, { 1, beautiful.bg_focus } }
--     })
-- end)

local player_widget = wibox.widget {
    {
        markup = icons.note.."   ",
        font = "Material Icons 20",
        widget = wibox.widget.textbox
    },
    {
        artist_widget,
        title_widget,
        -- progressbar_widget,
        {
            prev_widget,
            playpause_widget,
            next_widget,
            layout = wibox.layout.flex.horizontal
        },
        layout = wibox.layout.fixed.vertical,
    },
    layout = wibox.layout.fixed.horizontal
}

prev_widget:connect_signal("mouse::enter", function()
    prev_widget.bg = beautiful.fg_normal
    prev_widget.fg = beautiful.bg_normal
end)
prev_widget:connect_signal("mouse::leave", function()
    prev_widget.bg = beautiful.bg_normal
    prev_widget.fg = beautiful.fg_normal
end)

next_widget:connect_signal("mouse::enter", function()
    next_widget.bg = beautiful.fg_normal
    next_widget.fg = beautiful.bg_normal
end)
next_widget:connect_signal("mouse::leave", function()
    next_widget.bg = beautiful.bg_normal
    next_widget.fg = beautiful.fg_normal
end)

playpause_widget:connect_signal("mouse::enter", function()
    playpause_widget.bg = beautiful.fg_normal
    playpause_widget.fg = beautiful.bg_normal
end)
playpause_widget:connect_signal("mouse::leave", function()
    playpause_widget.bg = beautiful.bg_normal
    playpause_widget.fg = beautiful.fg_normal
end)

local function update()
    local metadata = mpris.Metadata

    if mpris.PlaybackStatus == "Playing" then
        playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.pause)

        title_widget.text = metadata["xesam:title"]
        artist_widget.text = metadata["xesam:artist"]
    elseif  mpris.PlaybackStatus == "Paused" then
        playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.play)

        title_widget.text = metadata["xesam:title"]
        artist_widget.text = metadata["xesam:artist"]
    else
        playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.play)

        title_widget.text = "Titre inconnu"
        artist_widget.text = "Artiste inconnu"
    end

    -- progressbar_widget.value = (mpris.Position / tonumber(metadata["mpris:length"])) * 100
end
update()

mpris:on_properties_changed(function (p, changed, invalidated)
    assert(p == mpris)
    update()
end)

playpause_widget:buttons(gears.table.join(
    awful.button({}, 1, function()
        mpris:PlayPause()
        if mpris.PlaybackStatus == "Playing" then
            playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.pause)
        else
            playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.play)
        end
    end)
))
prev_widget:buttons(gears.table.join(
    awful.button({}, 1, function() mpris:Previous() end)
))
next_widget:buttons(gears.table.join(
    awful.button({}, 1, function() mpris:Next() end)
))

player_widget.type = "control_widget" -- temporary

return player_widget
