local gears = require("gears")
local awful = require("awful")
local dbus = require("dbus_proxy")

local alsa = {}

local proxy
local function init_proxy()
    proxy = dbus.Proxy:new(
        {
            bus = dbus.Bus.SESSION,
            name = "fr.mpostaire.awdctl",
            interface = "fr.mpostaire.awdctl.Volume",
            path = "/fr/mpostaire/awdctl/Volume"
        }
    )
end

if pcall(init_proxy) then
    alsa.enabled = true
else
    alsa.enabled = false
    return alsa
end

local on_properties_changed_callbacks = {}

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

function alsa.set_volume(value)
    if proxy.Muted then
        proxy:ToggleVolume()
    end
    proxy:SetVolume(value)
end

function alsa.inc_volume(value)
    if proxy.Muted then
        proxy:ToggleVolume()
    end
    proxy:IncVolume(value)
end

function alsa.dec_volume(value)
    if proxy.Muted then
        proxy:ToggleVolume()
    end
    proxy:DecVolume(value)
end

function alsa.toggle_volume()
    proxy:ToggleVolume()
end

function alsa.on_properties_changed(func)
    table.insert(on_properties_changed_callbacks, func)
end

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
