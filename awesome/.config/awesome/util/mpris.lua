local dbus = require("dbus_proxy")

local mpris = {}

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

local function get_mpris_proxy()
    local mpris_name = get_mpris_name()
    if not mpris_name then return end

    local proxy = dbus.Proxy:new(
        {
            bus = dbus.Bus.SESSION,
            name = mpris_name,
            interface = "org.mpris.MediaPlayer2.Player",
            path = "/org/mpris/MediaPlayer2"
        }
    )

    proxy:on_properties_changed(function (p, changed, invalidated)
        assert(p == proxy)
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

    return proxy
end

local proxy = get_mpris_proxy()

-- handle mpris connection/disconnection
manager_proxy:connect_signal(function(p)
    assert(p == manager_proxy)
    if not proxy or not mpris.metadata then
        -- get_mpris_name() is called inside get_mpris_proxy(): no need to check if it is a mpris name
        proxy = get_mpris_proxy()
        if proxy then
            for _,v in pairs(on_properties_changed_callbacks) do
                v()
            end
        end
    end
end,
"NameOwnerChanged", nil)

function mpris.next()
    if proxy then
        proxy:Next()
    end
end

function mpris.pause()
    if proxy then
        proxy:Pause()
    end
end

function mpris.play()
    if proxy then
        proxy:Play()
    end
end

function mpris.play_pause()
    if proxy then
        proxy:PlayPause()
    end
end

function mpris.previous()
    if proxy then
        proxy:Previous()
    end
end

function mpris.seek(offset)
    if proxy then
        proxy:Seek(offset)
    end
end

function mpris.set_position()
    if proxy then
        proxy:SetPosition()
    end
end

function mpris.stop()
    if proxy then
        proxy:Stop()
    end
end

function mpris.on_properties_changed(func)
    table.insert(on_properties_changed_callbacks, func)
end

return mpris
