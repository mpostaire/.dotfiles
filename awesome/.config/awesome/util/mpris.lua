local awful = require("awful")
local gears = require("gears")
local dbus = require("dbus_proxy")
local Gio = require('lgi').Gio

local mpris = {players = {}, player_count = 0}

-- TODO: check if bugs below are still there because I rewrote this module
-- BUG: play() with rhythmbox freezes awesome for 25 seconds! This is due to the notification being unable to find
-- covert art (rhythmbox file not found) a fix is to disable notifications in rhythmbox interface
-- MEMLEAK ~ 5 Kb/s but I don't know why

local manager_proxy = dbus.Proxy:new {
    bus = dbus.Bus.SESSION,
    name = "org.freedesktop.DBus",
    interface = "org.freedesktop.DBus",
    path = "/org/freedesktop/DBus"
}

local on_player_added_callbacks, on_player_removed_callbacks = {}, {}

local function get_mpris_proxy(name)
    return dbus.Proxy:new {
        bus = dbus.Bus.SESSION,
        name = name,
        interface = "org.mpris.MediaPlayer2.Player",
        path = "/org/mpris/MediaPlayer2"
    }
end

local dbus_names = manager_proxy:ListNames()
local mpris_name_prefix = "org.mpris.MediaPlayer2."
for _, name in pairs(dbus_names) do
    if name:sub(1, #mpris_name_prefix) == mpris_name_prefix then
        mpris.players[name] = get_mpris_proxy(name)
        mpris.player_count = mpris.player_count + 1
        for _,v in pairs(on_player_added_callbacks) do v(name) end
    end
end

local function name_owner_changed_callback(conn, sender, object_path, interface_name, signal_name, user_data)
    local name = user_data[1]
    local new_owner = user_data[2]
    local old_owner = user_data[3]

    if name:sub(1, #mpris_name_prefix) == mpris_name_prefix then
        if old_owner == "" then -- removed player
            mpris.players[name] = nil
            mpris.player_count = mpris.player_count - 1
            for _,v in pairs(on_player_removed_callbacks) do v(name) end
        elseif new_owner == "" then -- added player
            mpris.players[name] = get_mpris_proxy(name)
            mpris.player_count = mpris.player_count + 1
            for _,v in pairs(on_player_added_callbacks) do v(name) end
        end
    end
end
dbus.Bus.SESSION:signal_subscribe('org.freedesktop.DBus', 'org.freedesktop.DBus',
                                    'NameOwnerChanged', nil, nil, Gio.DBusSignalFlags.NONE, name_owner_changed_callback)

function mpris.next(player)
    if not player then player = next(mpris.players) end
    if player and mpris.players[player] then
        mpris.players[player]:Next()
    end
end

function mpris.previous(player)
    if not player then player = next(mpris.players) end
    if player and mpris.players[player] then
        mpris.players[player]:Previous()
    end
end

function mpris.pause(player)
    if not player then player = next(mpris.players) end
    if player and mpris.players[player] then
        mpris.players[player]:Pause()
    end
end

function mpris.play(player)
    if not player then player = next(mpris.players) end
    if player and mpris.players[player] then
        mpris.players[player]:Play()
    end
end

function mpris.play_pause(player)
    if not player then player = next(mpris.players) end
    if player and mpris.players[player] then
        mpris.players[player]:PlayPause()
    end
end

function mpris.seek(player, offset)
    if not player then player = next(mpris.players) end
    if player and mpris.players[player] then
        mpris.players[player]:Seek(offset)
    end
end

function mpris.set_position(player, position)
    if not player then player = next(mpris.players) end
    if player and mpris.players[player] then
        mpris.players[player]:SetPosition(position)
    end
end

function mpris.stop(player)
    if not player then player = next(mpris.players) end
    if player and mpris.players[player] then
        mpris.players[player]:Stop()
    end
end

function mpris.open_uri(player, path)
    if not player then player = next(mpris.players) end
    if player and mpris.players[player] then
        mpris.players[player]:OpenUri(path)
    end
end

function mpris.on_player_added(func)
    table.insert(on_player_added_callbacks, func)
    -- exec callbacks (if needed) when we subscribe to this event (useful when players launched before awesomewm startup)
    for k,_ in pairs(mpris.players) do func(k) end
end
function mpris.on_player_removed(func)
    table.insert(on_player_removed_callbacks, func)
end
function mpris.on_properties_changed(player, func)
    if not player or not mpris.players[player] then return end
    mpris.players[player]:on_properties_changed(function(p, changed, invalidated)
        assert(p == mpris.players[player])
        func(changed, invalidated)
    end)
end

return mpris
