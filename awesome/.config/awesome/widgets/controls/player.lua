local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")
local gfs = require("gears.filesystem")
local naughty = require("naughty")
local mpris = require("util.mpris")
local helpers = require("util.helpers")

-- TODO multiple players support

local icons = {
    albumart = gfs.get_configuration_dir().."themes/icons/mpris_player_default.png",
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
    local albumart_widget = wibox.widget {
        id = 'albumart',
        image = icons.albumart,
        widget = wibox.widget.imagebox
    }

    local widget = wibox.widget {
        {
            {
                {
                    albumart_widget,
                    width = 64,
                    height = 64,
                    strategy = "max",
                    widget = wibox.container.constraint
                },
                forced_width = 64,
                forced_height = 64,
                widget = wibox.container.place
            },
            right = 16,
            widget = wibox.container.margin
        },
        {
            title_widget,
            artist_widget,
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

    local handled_player, old_trackid, old_albumart, notification
    local function update_widget()
        local metadata
        if not handled_player then
            metadata = nil
        else
            metadata = mpris.players[handled_player].Metadata
        end

        if not metadata or next(metadata) == nil then
            playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.play)
            
            title_widget.text = "Titre"
            artist_widget.text = "Artiste"
        else            
            if mpris.players[handled_player].PlaybackStatus == "Playing" then
                playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.pause)
            elseif mpris.players[handled_player].PlaybackStatus == "Paused" then
                playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.play)
            else
                playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.play)
    
                title_widget.text = "Titre"
                artist_widget.text = "Artiste"
            end

            local trackid = metadata["mpris:trackid"]
            if trackid == old_trackid then return end
            old_trackid = trackid

            local title = metadata["xesam:title"] or "Titre inconnu"
            local artist = metadata["xesam:artist"] or "Artiste inconnu"
            if type(artist) == 'table' then
                artist = metadata["xesam:artist"][1]
            end
            local filepath = helpers.uri_to_unix_path(metadata["xesam:url"])
            local albumart = helpers.uri_to_unix_path(metadata["mpris:artUrl"]) or icons.albumart

            title_widget.text = title
            artist_widget.text = artist
            albumart_widget.image = albumart
            
            -- TODO progress bar in player (just below of album art and same width)

            if widget.parent and widget.parent.control_popup and not widget.parent.control_popup.visible then
                if notification and not notification.is_expired then
                    notification.message = title.." by "..artist
                    notification.icon = albumart
                else
                    notification = naughty.notification {
                        icon = albumart,
                        title = "Now Playing",
                        message = title.." by "..artist
                    }
                end
            end
        end
    end

    mpris.on_player_added(function(player)
        if not handled_player then
            handled_player = player
            update_widget()
            mpris.on_properties_changed(handled_player, update_widget)
        end
    end)
    mpris.on_player_removed(function(player)
        if handled_player == player then
            handled_player = next(mpris.players)
            update_widget()
            mpris.on_properties_changed(handled_player, update_widget)
        end
    end)

    playpause_widget:buttons({
        awful.button({}, 1, function()
            mpris.play_pause(handled_player)
            if mpris.players[handled_player].PlaybackStatus == "Playing" then
                playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.pause)
            else
                playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.play)
            end
        end)
    })

    prev_widget:buttons({
        helpers.long_press_click({}, 1, function()
            mpris.previous(handled_player)
        end,
        function()
            mpris.seek(handled_player, -1e7) -- TODO 10 secs now but in % of song duration after ?
        end, 1, 0.1) -- tweak timeout value ?
    })

    next_widget:buttons({
        helpers.long_press_click({}, 1, function()
            mpris.next(handled_player)
        end,
        function()
            mpris.seek(handled_player, 1e7) -- TODO 10 secs now but in % of song duration after ?
        end, 1, 0.1) -- tweak timeout value ?
    })

    -- FIXME: long keyboard press is laggy (when key released there is still some events to process use keygrabber ?)
    local next_long_keypress, prev_long_keypress = 0, 0
    local keys = {
        awful.key({ "Control" }, "KP_Divide", function() mpris.play_pause(handled_player) end,
        {description = "music player pause", group = "multimedia"}),
        awful.key({ "Control" }, "KP_Right",
        function()
            next_long_keypress = next_long_keypress + 1
            if next_long_keypress > 1 then
                mpris.seek(handled_player, 1e7) -- TODO 10 secs now but in % of song duration after ?
            end
        end,
        function()
            if next_long_keypress <= 1 then
                mpris.next(handled_player)
            end
            next_long_keypress = 0
        end,
        {description = "music player go forward/next", group = "multimedia"}),
        awful.key({ "Control" }, "KP_Left",
        function()
            prev_long_keypress = prev_long_keypress + 1
            if prev_long_keypress > 1 then
                mpris.seek(handled_player, -1e7) -- TODO 10 secs now but in % of song duration after ?
            end
        end,
        function()
            if prev_long_keypress <= 1 then
                mpris.previous(handled_player)
            end
            prev_long_keypress = 0
        end,
        {description = "music player go backward/previous", group = "multimedia"})
    }

    awful.keyboard.append_global_keybindings(keys)

    widget.type = "control_widget"

    return widget
end
