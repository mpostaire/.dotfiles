-- This module supports only one battery. Unknown behaviour when more than one is used.
local dbus = require("dbus_proxy")

local battery = {}

-- // TODO: handle cases where battery state is not "charging", "discharging" or "full"
local states = {
    [0] = "unknown",
    "charging",
    "discharging",
    "empty",
    "full",
    "pending_charge",
    "pending_discharge"
}

local on_properties_changed_callbacks = {}

-- For now get only the first battery device
local function get_first_battery_path()
    local proxy = dbus.Proxy:new(
        {
            bus = dbus.Bus.SYSTEM,
            name = "org.freedesktop.UPower",
            interface = "org.freedesktop.UPower",
            path = "/org/freedesktop/UPower"
        }
    )

    local devices = proxy:EnumerateDevices()
    for _, v in ipairs(devices) do
        if v.Type == 2 then
            return v
        end
    end
end

local battery_path = get_first_battery_path()
if battery_path then
    battery.enabled = true
else
    battery.enabled = false
    return battery
end

local proxy = dbus.Proxy:new(
    {
        bus = dbus.Bus.SYSTEM,
        name = "org.freedesktop.UPower",
        interface = "org.freedesktop.UPower.Device",
        path = battery_path
    }
)

proxy:on_properties_changed(function (p, changed, invalidated)
    assert(p == proxy)
    local call_callback = false
    for k, v in pairs(changed) do
        if k == "Percentage" then
            battery.percentage = v
            call_callback = true
        elseif k == "State" then
            battery.state = states[v]
            call_callback = true
        elseif k == "TimeToFull" then
            battery.time_to_full = v
            call_callback = true
        elseif k == "TimeToEmpty" then
            battery.time_to_empty = v
            call_callback = true
        end
    end

    if call_callback then
        for _,v in pairs(on_properties_changed_callbacks) do
            v(changed)
        end
    end
end)

battery.percentage, battery.state = proxy.Percentage, states[proxy.State]
battery.time_to_full, battery.time_to_empty = proxy.TimeToFull, proxy.TimeToEmpty

function battery.on_properties_changed(func)
    table.insert(on_properties_changed_callbacks, func)
end

return battery
