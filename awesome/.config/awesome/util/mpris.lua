local awful = require("awful")
local gears = require("gears")
local dbus = require("dbus_proxy")
local helpers = require("util.helpers")

local mpris = {players = {}, player_count = 0}

-- TODO check if bugs below are still there because I rewrote this module
-- BUG play() with rhythmbox freezes awesome for 25 seconds! This is due to the notification being unable to find
-- covert art (rhythmbox file not found) a fix is to disable notifications in rhythmbox interface
-- FIXME MEMLEAK ~ 5 Kb/s but I don't know why

local on_player_added_callbacks, on_player_removed_callbacks = {}, {}

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

local function get_mpris_proxy(name)
    return dbus.Proxy:new {
        bus = dbus.Bus.SESSION,
        name = name,
        interface = "org.mpris.MediaPlayer2.Player",
        path = "/org/mpris/MediaPlayer2"
    }
end

local function on_name_added(name)
    mpris.players[name] = get_mpris_proxy(name)
    mpris.player_count = mpris.player_count + 1
    for _,v in pairs(on_player_added_callbacks) do v(name) end
end

local function on_name_lost(name)
    mpris.players[name] = nil
    mpris.player_count = mpris.player_count - 1
    for _,v in pairs(on_player_removed_callbacks) do v(name) end
end

helpers.dbus_watch_name_or_prefix("org.mpris.MediaPlayer2.", on_name_added, on_name_lost, true)

return mpris
