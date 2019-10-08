local dbus = require("dbus_proxy")

local alsa = {}

local proxy = dbus.Proxy:new(
    {
        bus = dbus.Bus.SESSION,
        name = "fr.mpostaire.awdctl",
        interface = "fr.mpostaire.awdctl.Volume",
        path = "/fr/mpostaire/awdctl/Volume"
    }
)

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

return alsa
