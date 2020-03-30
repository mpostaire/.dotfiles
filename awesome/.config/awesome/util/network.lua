local dbus = require("dbus_proxy")

-- TODO: strength of current connection, list of all visible connections + their strength
--       functions to rescan, disable/enable networking, disable/enable wifi, connect to another connection

-- //TODO rewrite this with lgi.NM ? (check libnm lua documentation)

local network = {}

local on_properties_changed_callbacks = {}

local manager_proxy
local function init_proxy()
    manager_proxy = dbus.Proxy:new(
        {
            bus = dbus.Bus.SYSTEM,
            name = "org.freedesktop.NetworkManager",
            interface = "org.freedesktop.NetworkManager",
            path = "/org/freedesktop/NetworkManager"
        }
    )
end

if pcall(init_proxy) then
    network.enabled = true
else
    network.enabled = false
    return network
end

local connection_proxy, access_point_proxy

local function set_active_connection_properties()
    if not connection_proxy then
        network.state, network.ssid, network.strength = 'off', 'none', 0
        return
    end

    if string.match(connection_proxy.Type, "ethernet") then
        network.state = 'eth'
    elseif string.match(connection_proxy.Type, "wireless") then
        network.state = 'wifi'
    else
        network.state = 'off'
    end
    network.ssid = connection_proxy.Id
    network.strength = access_point_proxy.Strength
end

local function set_active_connection_proxy()
    local path = manager_proxy.PrimaryConnection
    if path == '/' then
        connection_proxy, access_point_proxy = nil, nil
        return
    end

    connection_proxy = dbus.Proxy:new(
        {
            bus = dbus.Bus.SYSTEM,
            name = "org.freedesktop.NetworkManager",
            interface = "org.freedesktop.NetworkManager.Connection.Active",
            path = path
        }
    )

    -- //FIXME this is wrong it can be a false one
    -- to get the true one get connection_proxy.Devices[1]
    -- then with this device get ActiveAccessPoint
    access_point_proxy = dbus.Proxy:new(
        {
            bus = dbus.Bus.SYSTEM,
            name = "org.freedesktop.NetworkManager",
            interface = "org.freedesktop.NetworkManager.AccessPoint",
            path = connection_proxy.SpecificObject
        }
    )

    access_point_proxy:on_properties_changed(function (p, changed, invalidated)
        assert(p == access_point_proxy)
        local call_callback = false
        for k,_ in pairs(changed) do
            if k == "Strength" then
                set_active_connection_properties()
                call_callback = true
            end
        end

        if call_callback then
            for _,v in pairs(on_properties_changed_callbacks) do
                v()
            end
        end
    end)
end

set_active_connection_proxy()
set_active_connection_properties()

manager_proxy:on_properties_changed(function (p, changed, invalidated)
    assert(p == manager_proxy)
    local call_callback = false
    for k,_ in pairs(changed) do
        if k == "PrimaryConnection" then
            set_active_connection_proxy()
            set_active_connection_properties()
            call_callback = true
        end
    end

    if call_callback then
        for _,v in pairs(on_properties_changed_callbacks) do
            v()
        end
    end
end)

function network.on_properties_changed(func)
    table.insert(on_properties_changed_callbacks, func)
end

return network
