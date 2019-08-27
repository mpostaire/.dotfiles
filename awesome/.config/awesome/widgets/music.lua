local wibox = require("wibox")
local beautiful = require("beautiful")
local awful = require("awful")
local variables= require("config.variables")
local gears = require("gears")
local popup_notification = require("util.popup_notification")
local p = require("dbus_proxy")
local naughty = require("naughty")

---------------------------------------------------------------------

local manager_proxy = p.Proxy:new(
    {
        bus = p.Bus.SESSION,
        name = "org.freedesktop.DBus",
        interface = "org.freedesktop.DBus",
        path = "/org/freedesktop/DBus"
    }
)

local dbus_names = manager_proxy:ListNames()

-- for now only get first mpris player
local function get_mpris_name()
    local start = "org.mpris.MediaPlayer2."
    for _, v in pairs(dbus_names) do
        if v:sub(1, #start) == start then return v end
    end
end

-- TODO: handle when another mpris player is detected
-- manager_proxy:on_properties_changed(function (p, changed, invalidated)
--     assert(p == proxy)
--     for k, v in pairs(changed) do
--         n.notify{text=tostring(k.."="..v)}
--     end
-- end)

local mpris_name = get_mpris_name()
-- case where nothing is found, display nothing or a placeholder
-- if not mpris_name then end

local proxy = p.Proxy:new(
    {
        bus = p.Bus.SESSION,
        name = mpris_name,
        interface = "org.mpris.MediaPlayer2.Player",
        path = "/org/mpris/MediaPlayer2"
    }
)

local function us_to_hms(useconds)
    local seconds = tonumber(useconds) / 1000000

    local h = math.floor((seconds % 86400) / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = gears.math.round(seconds % 60)
    if h <= 0 then
        return string.format("%02d:%02d", m, s)
    else
        return string.format("%02d:%02d:%02d", h, m, s)
    end
end

---------------------------------------------------------------------

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
local playpause_widget = wibox.widget {
    {
        id = 'icon',
        markup = icons.play,
        widget = wibox.widget.textbox
    },
    margins = 5,
    widget = wibox.container.margin
}
local prev_widget = wibox.widget {
    {
        id = 'icon',
        markup = icons.prev,
        widget = wibox.widget.textbox
    },
    margins = 5,
    widget = wibox.container.margin
}
local next_widget = wibox.widget {
    {
        id = 'icon',
        markup = icons.next,
        widget = wibox.widget.textbox
    },
    margins = 5,
    widget = wibox.container.margin
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

local popup = awful.popup {
    widget = {
        {
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
        },
        margins = beautiful.notification_margin,
        widget  = wibox.container.margin
    },
    border_color = beautiful.border_normal,
    border_width = beautiful.border_width,
    placement = awful.placement.top_left + awful.placement.no_overlap,
    -- minimum_width = 250,
    -- maximum_width = 250,
    visible = true,
    ontop = true
}

local notification = popup_notification:new()
notification:set_icon(icons.note)
notification:set_markup("<b>Musique</b>", "En construction")
notification.popup.placement = function(d, args)
    awful.placement.top_left(d, args)
    notification.popup.y = notification.popup.y + beautiful.wibar_height + beautiful.notification_offset
    notification.popup.x = notification.popup.x + beautiful.notification_offset
end

local icon_widget = wibox.widget {
    {
        markup = icons.note,
        id = "icon",
        font = "Material Icons 12",
        widget = wibox.widget.textbox
    },
    widget = wibox.container.margin(_, beautiful.wibar_widgets_padding, beautiful.widgets_inner_padding, 0, 0)
}

local text_widget = wibox.widget {
    {
        markup = "Musique",
        id = "text",
        widget = wibox.widget.textbox
    },
    widget = wibox.container.margin(_, 0, beautiful.wibar_widgets_padding, 0, 0)
}

local music_widget = wibox.widget {
    icon_widget,
    text_widget,
    layout = wibox.layout.fixed.horizontal
}

local function get_icon(mouse_hover)
    if mouse_hover then
        return '<span foreground="'..beautiful.fg_normal_hover..'">'..icons.note..'</span>'
    else
        return icons.note
    end
end

local function get_text(mouse_hover)
    local metadata = proxy.Metadata

    if mouse_hover then
        return '<span foreground="'..beautiful.fg_normal_hover..'">'..metadata["xesam:title"]..'</span>'
    else
        return metadata["xesam:title"]
    end
end

local function update_widget()
    icon_widget:get_children_by_id('icon')[1]:set_markup_silently(get_icon())
    text_widget:get_children_by_id('text')[1]:set_markup_silently(get_text())

    if proxy.PlaybackStatus == "Playing" then
        playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.pause)
    else
        playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.play)
    end

    local metadata = proxy.Metadata
    title_widget.text = metadata["xesam:title"]
    artist_widget.text = metadata["xesam:artist"]
    -- progressbar_widget.value = (proxy.Position / tonumber(metadata["mpris:length"])) * 100
end
update_widget()

proxy:on_properties_changed(function (p, changed, invalidated)
    assert(p == proxy)
    update_widget()
    naughty.notify{title="Musique", text=p.Metadata["xesam:title"]}
end)

local old_cursor, old_wibox
music_widget:connect_signal("mouse::enter", function()
    -- mouse_hover color highlight
    icon_widget:get_children_by_id('icon')[1]:set_markup_silently(get_icon(true))
    text_widget:get_children_by_id('text')[1]:set_markup_silently(get_text(true))

    local w = mouse.current_wibox
    old_cursor, old_wibox = w.cursor, w
    w.cursor = "hand1"
end)
music_widget:connect_signal("mouse::leave", function()
    -- no mouse_hover color highlight
    icon_widget:get_children_by_id('icon')[1]:set_markup_silently(get_icon())
    text_widget:get_children_by_id('text')[1]:set_markup_silently(get_text())

    if old_wibox then
        old_wibox.cursor = old_cursor
        old_wibox = nil
    end
end)

music_widget:buttons(gears.table.join(
    awful.button({}, 1, function() popup.visible = not popup.visible end)
))
playpause_widget:buttons(gears.table.join(
    awful.button({}, 1, function()
        proxy:PlayPause()
        if proxy.PlaybackStatus == "Playing" then
            playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.pause)
        else
            playpause_widget:get_children_by_id('icon')[1]:set_markup_silently(icons.play)
        end
    end)
))
prev_widget:buttons(gears.table.join(
    awful.button({}, 1, function() proxy:Previous() end)
))
next_widget:buttons(gears.table.join(
    awful.button({}, 1, function() proxy:Next() end)
))

local widget_keys = gears.table.join(
    awful.key({ variables.modkey }, "m", function() popup.visible = not popup.visible end,
    {description = "show the music menu", group = "launcher"}),
    awful.key({ "Control" }, "KP_Divide", function() proxy:PlayPause() end,
    {description = "music player pause", group = "multimedia"}),
    awful.key({ "Control" }, "KP_Right", function() proxy:Next() end,
    {description = "music player next song", group = "multimedia"}),
    awful.key({ "Control" }, "KP_Left", function() proxy:Previous() end,
    {description = "music player previous song", group = "multimedia"}),
    awful.key({ "Control" }, "KP_Begin", function() proxy:Stop() end,
    {description = "music player stop", group = "multimedia"})
)

root.keys(gears.table.join(root.keys(), widget_keys))

return music_widget
