local awful = require("awful")
local gears = require("gears")
local dbus = require("dbus_proxy")
local capi = {root = root}

local brightness = {}

-- USE pcall() to catch error if dbus interface not found

local proxy = dbus.Proxy:new(
    {
        bus = dbus.Bus.SESSION,
        name = "fr.mpostaire.awdctl",
        interface = "fr.mpostaire.awdctl.Brightness",
        path = "/fr/mpostaire/awdctl/Brightness"
    }
)

local on_properties_changed_callbacks = {}

proxy:on_properties_changed(function (p, changed, invalidated)
    assert(p == proxy)
    local call_callback = false
    for k,v in pairs(changed) do
        if k == "Percentage" then
            brightness.brightness = v
            call_callback = true
        end
    end

    if call_callback then
        for _,v in pairs(on_properties_changed_callbacks) do
            v()
        end
    end
end)

brightness.brightness = proxy.Percentage

function brightness.set_brightness(value)
    proxy:SetBrightness(value)
end

function brightness.inc_brightness(value)
    proxy:IncBrightness(value)
end

function brightness.dec_brightness(value)
    proxy:DecBrightness(value)
end

function brightness.on_properties_changed(func)
    table.insert(on_properties_changed_callbacks, func)
end

local keys = gears.table.join(
    awful.key({}, "XF86MonBrightnessUp", function()
        brightness.inc_brightness(5)
    end,
    {description = "brightness up", group = "other"}),
    awful.key({}, "XF86MonBrightnessDown", function()
        brightness.dec_brightness(5)
    end,
    {description = "brightness down", group = "other"})
)

capi.root.keys(gears.table.join(capi.root.keys(), keys))

return brightness
