local gears = require("gears")
local awful = require("awful")
local dbus = require("dbus_proxy")
local helpers = require("util.helpers")

local alsa = {}
alsa.enabled = false -- assume false at startup

local on_properties_changed_callbacks, on_alsa_enabled_callbacks, on_alsa_disabled_callbacks = {}, {}, {}

local proxy

function alsa.set_volume(value)
    if not proxy then return end
    if proxy.Muted then
        proxy:ToggleVolume()
    end
    proxy:SetVolume(value)
end

function alsa.inc_volume(value)
    if not proxy then return end
    if proxy.Muted then
        proxy:ToggleVolume()
    end
    proxy:IncVolume(value)
end

function alsa.dec_volume(value)
    if not proxy then return end
    if proxy.Muted then
        proxy:ToggleVolume()
    end
    proxy:DecVolume(value)
end

function alsa.toggle_volume()
    if not proxy then return end
    proxy:ToggleVolume()
end

function alsa.on_enabled(func)
    table.insert(on_alsa_enabled_callbacks, func)
    -- exec callbacks (if needed) when we subscribe to this event (useful when alsa available before awesomewm startup)
    if alsa.enabled then func(k) end
end
function alsa.on_disabled(func)
    table.insert(on_alsa_disabled_callbacks, func)
end
function alsa.on_properties_changed(func)
    table.insert(on_properties_changed_callbacks, func)
end

local function get_proxy()
    return dbus.Proxy:new(
        {
            bus = dbus.Bus.SESSION,
            name = "fr.mpostaire.awdctl",
            interface = "fr.mpostaire.awdctl.Volume",
            path = "/fr/mpostaire/awdctl/Volume"
        }
    )
end

local function on_name_added(name)
    proxy = get_proxy()
    proxy:on_properties_changed(function (p, changed, invalidated)
        assert(p == proxy)
        local call_callback = false
        for k,v in pairs(changed) do
            if k == "Percentage" then
                alsa.volume = v
                call_callback = true
            elseif k == "Muted" then
                alsa.muted = v
                call_callback = true
            end
        end

        if call_callback then
            for _,v in pairs(on_properties_changed_callbacks) do
                v()
            end
        end
    end)
    alsa.muted, alsa.volume = proxy.Muted, proxy.Percentage
    alsa.enabled = true
    for _,v in pairs(on_alsa_enabled_callbacks) do v() end
end

local function on_name_lost(name)
    proxy = nil
    alsa.muted, alsa.volume = nil, nil
    alsa.enabled = false
    for _,v in pairs(on_alsa_disabled_callbacks) do v() end
end

helpers.dbus_watch_name("fr.mpostaire.awdctl", on_name_added, on_name_lost)

local keys = gears.table.join(
    awful.key({}, "XF86AudioRaiseVolume", function()
        alsa.inc_volume(5)
    end,
    {description = "volume up", group = "multimedia"}),
    awful.key({}, "XF86AudioMute", function()
        alsa.toggle_volume()
    end,
    {description = "toggle mute volume", group = "multimedia"}),
    awful.key({}, "XF86AudioLowerVolume", function()
        alsa.dec_volume(5)
    end,
    {description = "volume down", group = "multimedia"})
)

_G.root.keys(gears.table.join(_G.root.keys(), keys))

return alsa
