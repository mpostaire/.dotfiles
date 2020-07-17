local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local mpris = require("util.mpris")
local helpers = require("util.helpers")

local icons = {
    note = "",
    play = "",
    pause = "",
    prev = "",
    next = ""
}

return function()
    local font_height = beautiful.get_font_height(beautiful.font)
    local artist_widget = wibox.widget {
        text = "Artiste",
        forced_width = 175,
        forced_height = font_height,
        widget = wibox.widget.textbox
    }
    local title_widget = wibox.widget {
        text = "Title",
        forced_width = 175,
        forced_height = font_height,
        widget = wibox.widget.textbox
    }
    local prev_widget = wibox.widget {
        {
            {
                id = 'icon',
                align  = 'center',
                markup = icons.prev,
                font = beautiful.icon_font,
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
                font = beautiful.icon_font,
                forced_height = 22,
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
                font = beautiful.icon_font,
                widget = wibox.widget.textbox
            },
            margins = 5,
            widget = wibox.container.margin
        },
        widget = wibox.container.background
    }

    local widget = wibox.widget {
        {
            markup = icons.note.."   ",
            font = helpers.change_font_size(beautiful.icon_font, 20),
            widget = wibox.widget.textbox
        },
        {
            artist_widget,
            title_widget,
            {
                prev_widget,
                playpause_widget,
                next_widget,
                layout = wibox.layout.flex.horizontal
            },
            spacing = 2,
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

    local function update_widget()
        local metadata = mpris.metadata
        if not metadata then
            widget.visible = false
            return
        end

        widget.visible = true

        local artist = metadata["xesam:artist"]
        if type(artist) == 'table' then
            artist = metadata["xesam:artist"][1]
        end

        if mpris.playback_status == "Playing" then
            playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.pause)

            title_widget.text = metadata["xesam:title"]
            artist_widget.text = artist
        elseif  mpris.playback_status == "Paused" then
            playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.play)

            title_widget.text = metadata["xesam:title"]
            artist_widget.text = artist
        else
            playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.play)

            title_widget.text = "Titre inconnu"
            artist_widget.text = "Artiste inconnu"
        end
    end
    update_widget()

    mpris.on_properties_changed(update_widget)

    playpause_widget:buttons(gears.table.join(
        awful.button({}, 1, function()
            mpris.play_pause()
            if mpris.playback_status == "Playing" then
                playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.pause)
            else
                playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.play)
            end
        end)
    ))
    prev_widget:buttons(gears.table.join(
        awful.button({}, 1, function() mpris.previous() end)
    ))
    next_widget:buttons(gears.table.join(
        awful.button({}, 1, function() mpris.next() end)
    ))

    widget.type = "control_widget"

    return widget
end
