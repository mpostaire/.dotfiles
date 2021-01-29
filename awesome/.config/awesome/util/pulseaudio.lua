local awful = require("awful")
local dbus = require("dbus_proxy")
local helpers = require("util.helpers")
local lgi = require("lgi")
local GVariant = lgi.GLib.Variant
local Gio = lgi.Gio

-- TODO watch for devices changes and react accordingly
-- TODO support switching sinks

local pulseaudio = {}
pulseaudio.enabled = false -- assume false at startup

local on_properties_changed_callbacks, on_alsa_enabled_callbacks, on_alsa_disabled_callbacks = {}, {}, {}

local proxy

function pulseaudio.set_volume(value)
    if not proxy then return end
    if pulseaudio.muted then
        pulseaudio.toggle_volume()
    end

    -- TODO force to not go beyound 50% if headphones detected
    if value > 100 then
        value = 100
    elseif value < 0 then
        value = 0
    end

    pulseaudio.volume = value
    local true_volume = math.ceil((value / 100) * proxy.BaseVolume)
    proxy:Set("org.PulseAudio.Core1.Device", "Volume", GVariant("au", { true_volume, true_volume })) -- TODO this is temp and wrong way of doing it i should add support to all channels
end

function pulseaudio.inc_volume(value)
    pulseaudio.set_volume(pulseaudio.volume + value)
end

function pulseaudio.dec_volume(value)
    pulseaudio.set_volume(pulseaudio.volume - value)
end

function pulseaudio.toggle_volume()
    if not proxy then return end
    proxy:Set("org.PulseAudio.Core1.Device", "Mute", GVariant("b", not pulseaudio.muted))
end

function pulseaudio.on_enabled(func)
    table.insert(on_alsa_enabled_callbacks, func)
    -- exec callbacks (if needed) when we subscribe to this event (useful when alsa available before awesomewm startup)
    if pulseaudio.enabled then func(k) end
end
function pulseaudio.on_disabled(func)
    table.insert(on_alsa_disabled_callbacks, func)
end
-- TODO rename this to on_changed ??
function pulseaudio.on_properties_changed(func)
    table.insert(on_properties_changed_callbacks, func)
end

local function get_proxy()
    local initial_proxy = dbus.Proxy:new {
        bus = dbus.Bus.SESSION,
        name = "org.PulseAudio1",
        interface = "org.PulseAudio.ServerLookup1",
        path = "/org/pulseaudio/server_lookup1"
    }
    
    local connection = Gio.DBusConnection.new_for_address_sync(
        initial_proxy.Address,
        Gio.DBusConnectionFlags.AUTHENTICATION_CLIENT
    )
    
    local core_proxy = dbus.Proxy:new {
        bus = connection,
        name = nil,
        interface = "org.PulseAudio.Core1",
        path = "/org/pulseaudio/core1"
    }

    -- Needed for these signals to work
    core_proxy:ListenForSignal("org.PulseAudio.Core1.Device.MuteUpdated", {})
    core_proxy:ListenForSignal("org.PulseAudio.Core1.Device.VolumeUpdated", {})
    
    -- TODO support multiple sinks/devices
    return dbus.Proxy:new {
        bus = connection,
        name = nil,
        interface = "org.PulseAudio.Core1.Device",
        path = core_proxy.Sinks[1]
    }
end

local function on_name_added(name)
    proxy = get_proxy()

    proxy:connect_signal(function(p, muted)
        assert(p == proxy)
        pulseaudio.muted = muted
        for _,v in pairs(on_properties_changed_callbacks) do v() end
    end, "MuteUpdated")
    proxy:connect_signal(function(p, volume)
        assert(p == proxy)
        pulseaudio.volume = math.ceil(volume[1] / proxy.BaseVolume * 100)
        for _,v in pairs(on_properties_changed_callbacks) do v() end
    end, "VolumeUpdated")

    pulseaudio.muted = proxy:Get("org.PulseAudio.Core1.Device", "Mute")
    -- TODO support multiple volume channels (ex: left right ?). Here we only get the first one... because it is needed for volume setter
    pulseaudio.volume = math.ceil(proxy:Get("org.PulseAudio.Core1.Device", "Volume")[1] / proxy.BaseVolume * 100)
    pulseaudio.enabled = true
    for _,v in pairs(on_alsa_enabled_callbacks) do v() end
end

local function on_name_lost(name)
    proxy = nil
    pulseaudio.muted, pulseaudio.volume = nil, nil
    pulseaudio.enabled = false
    for _,v in pairs(on_alsa_disabled_callbacks) do v() end
end

helpers.dbus_watch_name_or_prefix("org.PulseAudio1", on_name_added, on_name_lost)

awful.keyboard.append_global_keybindings {
    awful.key({}, "XF86AudioRaiseVolume", function()
        pulseaudio.inc_volume(5)
    end,
    {description = "volume up", group = "multimedia"}),
    awful.key({}, "XF86AudioMute", function()
        pulseaudio.toggle_volume()
    end,
    {description = "toggle mute volume", group = "multimedia"}),
    awful.key({}, "XF86AudioLowerVolume", function()
        pulseaudio.dec_volume(5)
    end,
    {description = "volume down", group = "multimedia"})
}

return pulseaudio
