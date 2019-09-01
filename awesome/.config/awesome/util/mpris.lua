local p = require("dbus_proxy")

local manager_proxy = p.Proxy:new(
    {
        bus = p.Bus.SESSION,
        name = "org.freedesktop.DBus",
        interface = "org.freedesktop.DBus",
        path = "/org/freedesktop/DBus"
    }
)

local dbus_names = manager_proxy:ListNames()

-- for now only get first mpris player
local function get_mpris_name()
    local start = "org.mpris.MediaPlayer2."
    for _, v in pairs(dbus_names) do
        if v:sub(1, #start) == start then return v end
    end
end

-- TODO: handle when another mpris player is detected
-- manager_proxy:on_properties_changed(function (p, changed, invalidated)
--     assert(p == proxy)
--     for k, v in pairs(changed) do
--         n.notify{text=tostring(k.."="..v)}
--     end
-- end)

local mpris_name = get_mpris_name()
-- case where nothing is found, display nothing or a placeholder
-- if not mpris_name then end

local proxy = p.Proxy:new(
    {
        bus = p.Bus.SESSION,
        name = mpris_name,
        interface = "org.mpris.MediaPlayer2.Player",
        path = "/org/mpris/MediaPlayer2"
    }
)

return proxy
