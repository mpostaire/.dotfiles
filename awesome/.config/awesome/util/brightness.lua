local awful = require("awful")
local gears = require("gears")
local dbus = require("dbus_proxy")
local helpers = require("util.helpers")

local brightness = {}
brightness.enabled = false -- assume false at startup

local on_properties_changed_callbacks, on_brightness_enabled_callbacks, on_brightness_disabled_callbacks = {}, {}, {}

local proxy

function brightness.set_brightness(value)
    if not proxy then return end
    proxy:SetBrightness(value)
end

function brightness.inc_brightness(value)
    if not proxy then return end
    proxy:IncBrightness(value)
end

function brightness.dec_brightness(value)
    if not proxy then return end
    proxy:DecBrightness(value)
end

function brightness.on_enabled(func)
    table.insert(on_brightness_enabled_callbacks, func)
    -- exec callbacks (if needed) when we subscribe to this event (useful when brightness available before awesomewm startup)
    if brightness.enabled then func(k) end
end
function brightness.on_disabled(func)
    table.insert(on_brightness_disabled_callbacks, func)
end
function brightness.on_properties_changed(func)
    table.insert(on_properties_changed_callbacks, func)
end

local function get_proxy()
    return dbus.Proxy:new(
        {
            bus = dbus.Bus.SESSION,
            name = "fr.mpostaire.awdctl",
            interface = "fr.mpostaire.awdctl.Brightness",
            path = "/fr/mpostaire/awdctl/Brightness"
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
    brightness.enabled = true
    for _,v in pairs(on_brightness_enabled_callbacks) do v() end
end

local function on_name_lost(name)
    proxy = nil
    brightness.brightness = nil
    brightness.enabled = false
    for _,v in pairs(on_brightness_disabled_callbacks) do v() end
end

helpers.dbus_watch_name_or_prefix("fr.mpostaire.awdctl", on_name_added, on_name_lost)

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

_G.root.keys(gears.table.join(_G.root.keys(), keys))

return brightness
