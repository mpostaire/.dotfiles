local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local naughty = require("naughty")
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
        text = "Titre",
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
            markup = " "..icons.note.."   ",
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

    local handled_player
    local function update_widget()
        local metadata
        if not handled_player then
            metadata = nil
        else
            metadata = mpris.players[handled_player].Metadata
        end

        if not metadata then
            playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.play)
            
            title_widget.text = "Titre"
            artist_widget.text = "Artiste"
        else
            local title = metadata["xesam:title"] or "Titre inconnu"
            local artist = metadata["xesam:artist"] or "Artiste inconnu"
            if type(artist) == 'table' then
                artist = metadata["xesam:artist"][1]
            end
    
            if mpris.players[handled_player].PlaybackStatus == "Playing" then
                playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.pause)
    
                title_widget.text = title
                artist_widget.text = artist
            elseif  mpris.players[handled_player].PlaybackStatus == "Paused" then
                playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.play)
    
                title_widget.text = title
                artist_widget.text = artist
            else
                playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.play)
    
                title_widget.text = "Titre"
                artist_widget.text = "Artiste"
            end
        end
    end

    -- TODO replace prev notif if still showed
    -- TODO show only on new track
    -- naughty.notify{title="Now Playing", text="Song title", replace_id=notification}

    mpris.on_player_added(function(player)
        if not handled_player then
            handled_player = player
            update_widget()
            mpris.on_track_changed(handled_player, update_widget)
        end
        -- require("naughty").notify{text="added player "..player}
    end)
    mpris.on_player_removed(function(player)
        if handled_player == player then handled_player = nil end
        -- require("naughty").notify{text="removed player "..player}
    end)

    playpause_widget:buttons(gears.table.join(
        awful.button({}, 1, function()
            mpris.play_pause(handled_player)
            if mpris.players[handled_player].PlaybackStatus == "Playing" then
                playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.pause)
            else
                playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.play)
            end
        end)
    ))
    prev_widget:buttons(gears.table.join(
        awful.button({}, 1, function() mpris.previous(handled_player) end)
    ))
    next_widget:buttons(gears.table.join(
        awful.button({}, 1, function() mpris.next(handled_player) end)
    ))

    local keys = gears.table.join(
        awful.key({ "Control" }, "KP_Divide", function() mpris.play_pause(handled_player) end,
        {description = "music player pause", group = "multimedia"}),
        awful.key({ "Control" }, "KP_Right", function() mpris.next(handled_player) end,
        {description = "music player next song", group = "multimedia"}),
        awful.key({ "Control" }, "KP_Left", function() mpris.previous(handled_player) end,
        {description = "music player previous song", group = "multimedia"}),
        awful.key({ "Control" }, "KP_Begin", function() mpris.stop(handled_player) end,
        {description = "music player stop", group = "multimedia"})
    )

    _G.root.keys(gears.table.join(_G.root.keys(), keys))

    widget.type = "control_widget"

    return widget
end
