local lgi = require("lgi")
local Gio = lgi.Gio
local GLib = lgi.GLib
local dbus = require("dbus_proxy")

local geoclue = {}

local on_location_found_callbacks = {}

local manager_proxy
local function init_manager_proxy()
    manager_proxy = dbus.Proxy:new(
        {
            bus = dbus.Bus.SYSTEM,
            name = "org.freedesktop.GeoClue2",
            interface = "org.freedesktop.GeoClue2.Manager",
            path = "/org/freedesktop/GeoClue2/Manager"
        }
    )
end

if pcall(init_manager_proxy) then
    geoclue.enabled = true
else
    geoclue.enabled = false
    return geoclue
end

local client_path = manager_proxy:GetClient()
local client = dbus.Proxy:new(
    {
        bus = dbus.Bus.SYSTEM,
        name = "org.freedesktop.GeoClue2",
        interface = "org.freedesktop.GeoClue2.Client",
        path = client_path
    }
)

-- set DesktopId as a string (s) set to awesomewm
-- dbus_proxy cannot set proxy properties (only cached ones so kinda useless)
-- so we set them manually
local s = GLib.Variant("s", "awesome")
Gio.DBusProxy.call_sync(
    client._proxy,
    "org.freedesktop.DBus.Properties.Set",
    GLib.Variant("(ssv)", {"org.freedesktop.GeoClue2.Client", "DesktopId", s}),
    Gio.DBusCallFlags.NONE,
    -1
)

client:Start()

client:on_properties_changed(function(p, changed)
    assert(p == client)
    for k,v in pairs(changed) do
        if k == "Location" then
            local location = dbus.Proxy:new(
                {
                    bus = dbus.Bus.SYSTEM,
                    name = "org.freedesktop.GeoClue2",
                    interface = "org.freedesktop.GeoClue2.Location",
                    path = v
                }
            )
            geoclue.latitude = location.Latitude
            geoclue.longitude = location.Longitude

            -- we stop because for now we only want position once (make this an option ?)
            client:Stop()

            for _,callback in pairs(on_location_found_callbacks) do
                callback()
            end
        end
    end
end)

local function dd_to_dms(dd)
    local deg = math.floor(dd)
    local min = math.floor((dd - deg) * 60)
    local sec = (dd - deg - min / 60) * 3600
    return deg, min, sec
end

function geoclue.coords_to_string(latitude, longitude)
    local location

    -- latitude
    local deg, min, _ = dd_to_dms(latitude)
    if deg < 0 then
        location = -deg.."°"..min.."'S "
    else
        location = deg.."°"..min.."'N "
    end

    -- latitude
    deg, min, _ = dd_to_dms(longitude)
    if deg < 0 then
        location = location..-deg.."°"..min.."'W"
    else
        location = location..deg.."°"..min.."'E"
    end
    return location
end

function geoclue.on_location_found(func)
    table.insert(on_location_found_callbacks, func)
end

return geoclue
