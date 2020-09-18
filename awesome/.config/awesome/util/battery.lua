local lgi = require("lgi")

local success, upower = pcall(lgi.require, 'UPowerGlib')
if not success then return { enabled = false } end

local battery = {}

local on_properties_changed_callbacks = {}

local device = upower.Client():get_display_device()

battery.enabled = device and device.is_present or false

local function get_state(state)
    if state == "pending-charge" then
        state = "charging"
    elseif state == "empty" or state == "pending-discharge" then
        state = "discharging"
    end
    return state
end

local function get_level(level)
    if level == "none" then
        if device.percentage > 80 then
            level = "full"
        elseif device.percentage > 60 then
            level = "high"
        elseif device.percentage > 40 then
            level = "normal"
        elseif device.percentage > 20 then
            level = "low"
        else
            level = "critical"
        end
    end
    return level
end

battery.percentage = device.percentage
battery.state = get_state(device.state_to_string(device.state))
battery.time_to_full = device.time_to_full
battery.time_to_empty = device.time_to_empty
battery.level = get_level(device.level_to_string(device.battery_level))

function device:on_notify()
    local state = get_state(device.state_to_string(device.state))
    local level = get_level(device.level_to_string(device.battery_level))
    battery.time_to_full = device.time_to_full
    battery.time_to_empty = device.time_to_empty

    if device.percentage ~= battery.percentage then
        battery.percentage = device.percentage
    elseif state ~= battery.state then
        battery.state = state
    elseif device.is_present ~= battery.enabled then
        battery.enabled = device.is_present
    elseif level ~= battery.level then
        battery.level = level
    end

    for _,v in pairs(on_properties_changed_callbacks) do v() end
end

function battery.on_properties_changed(func)
    table.insert(on_properties_changed_callbacks, func)
end

return battery
