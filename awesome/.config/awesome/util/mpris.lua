local awful = require("awful")
local gears = require("gears")
local dbus = require("dbus_proxy")
local Gio = require('lgi').Gio

local mpris = {}

-- BUG: play() with rhythmbox only freezes awesome for 25 seconds! This is due to the notification being unable to find
-- covert art (rhythmbox file not found) a fix is to disable notifications in rhythmbox interface
-- BUG: vlc when next/prev is used, proxy.PlaybackStatus show 'Stopped' but should be 'Playing' (proxy is not updated)
-- BUG: when playlist is empty no player is visible.
--      when playlist just got empty player displays old metadata and disappear next update
--      when playlist is then filled the player don't show itself
-- MEMLEAK ~ 5 Kb/s but I don't know why

local manager_proxy = dbus.Proxy:new(
    {
        bus = dbus.Bus.SESSION,
        name = "org.freedesktop.DBus",
        interface = "org.freedesktop.DBus",
        path = "/org/freedesktop/DBus"
    }
)

local on_properties_changed_callbacks = {}

-- for now only get first mpris player
local function get_mpris_name()
    local dbus_names = manager_proxy:ListNames()
    local start = "org.mpris.MediaPlayer2."
    for _, v in pairs(dbus_names) do
        if v:sub(1, #start) == start then return v end
    end
end

-- BUG: open cmus + play music -> open vlc -> close vlc = we need to play/pause or next/prev to update song info (but openning vlc switches to correct state)

local mpris_proxy, old_name = nil, nil
local function get_mpris_proxy()

    local name = get_mpris_name()
    if not name then
        -- player closed
        mpris.metadata, mpris.playback_status = nil, nil
        for _,v in pairs(on_properties_changed_callbacks) do
            v()
        end
        old_name = nil
        return nil
    end
    if old_name and name == old_name then
        -- same player
        return mpris_proxy
    end
    old_name = name
    
    -- new player
    local proxy = dbus.Proxy:new(
        {
            bus = dbus.Bus.SESSION,
            name = name,
            interface = "org.mpris.MediaPlayer2.Player",
            path = "/org/mpris/MediaPlayer2"
        }
    )

    proxy:on_properties_changed(function (p, changed, invalidated)
        assert(p == mpris_proxy)
        mpris.metadata = p.Metadata
        mpris.playback_status = p.PlaybackStatus
        for _,v in pairs(on_properties_changed_callbacks) do
            v()
        end

        if not mpris.metadata then
            proxy = nil
        end
    end)

    mpris.metadata, mpris.playback_status = proxy.Metadata, proxy.PlaybackStatus

    for _,v in pairs(on_properties_changed_callbacks) do
        v()
    end

    return proxy
end

-- handle mpris connection/disconnection (for now supports only one mpris player at a time)
mpris_proxy = get_mpris_proxy()
function name_owner_changed_callback(conn, sender, object_path, interface_name, signal_name, user_data)
    mpris_proxy = get_mpris_proxy()
end
dbus.Bus.SESSION:signal_subscribe('org.freedesktop.DBus', 'org.freedesktop.DBus',
                                    'NameOwnerChanged', nil, nil, Gio.DBusSignalFlags.NONE, name_owner_changed_callback)

function mpris.next()
    if mpris_proxy then
        mpris_proxy:Next()
    end
end

function mpris.pause()
    if mpris_proxy then
        mpris_proxy:Pause()
    end
end

function mpris.play()
    if mpris_proxy then
        mpris_proxy:Play()
    end
end

function mpris.play_pause()
    if mpris_proxy then
        mpris_proxy:PlayPause()
    end
end

function mpris.previous()
    if mpris_proxy then
        mpris_proxy:Previous()
    end
end

function mpris.seek(offset)
    if mpris_proxy then
        mpris_proxy:Seek(offset)
    end
end

function mpris.set_position()
    if mpris_proxy then
        mpris_proxy:SetPosition()
    end
end

function mpris.stop()
    if mpris_proxy then
        mpris_proxy:Stop()
    end
end

function mpris.on_properties_changed(func)
    table.insert(on_properties_changed_callbacks, func)
end

local keys = gears.table.join(
    awful.key({ "Control" }, "KP_Divide", function() mpris.play_pause() end,
    {description = "music player pause", group = "multimedia"}),
    awful.key({ "Control" }, "KP_Right", function() mpris.next() end,
    {description = "music player next song", group = "multimedia"}),
    awful.key({ "Control" }, "KP_Left", function() mpris.previous() end,
    {description = "music player previous song", group = "multimedia"}),
    awful.key({ "Control" }, "KP_Begin", function() mpris.stop() end,
    {description = "music player stop", group = "multimedia"})
)

_G.root.keys(gears.table.join(_G.root.keys(), keys))

return mpris
