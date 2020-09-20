local dbus = require("dbus_proxy")
local lgi = require("lgi")
local Gio = lgi.Gio
local GObject = lgi.GObject
local GVariant = lgi.GLib.Variant

-- TODO make this async (using call() instead of call_async) and better handling even if this works
-- now it takes 1.3-2.0 % of cpu while animating the dropbox icon
local function get_icon(proxy, callback)
    Gio.DBusProxy.call(
        proxy,
        "org.freedesktop.DBus.Properties.Get",
        GVariant("(ss)", {"org.kde.StatusNotifierItem", "IconName"}),
        Gio.DBusCallFlags.NONE,
        -1,
        nil,
        callback
    )
end

local systray = { snis = {} }

local on_sni_added_callbacks, on_sni_removed_callbacks = {}, {}

local function remove_sni(id, watch_name_id, service, connection)
    local keys = { }
    for k, _ in pairs(systray.snis) do
        table.insert(keys, k)
    end
    systray.snis[id]._private.proxy = nil -- useless ? I don't really understand lua gc
    systray.snis[id] = nil

    Gio.bus_unwatch_name(watch_name_id)

    connection:emit_signal(
        nil,
        "/StatusNotifierWatcher",
        "org.kde.StatusNotifierWatcher",
        "StatusNotifierItemRegistered",
        GVariant("(s)", { service })
    )

    connection:emit_signal(
        nil,
        "/StatusNotifierWatcher",
        "org.freedesktop.DBus.Properties",
        "PropertiesChanged",
        GVariant("(sa{sv}as)", {
            "org.kde.StatusNotifierWatcher",
            { RegisteredStatusNotifierItems = GVariant("as", keys) },
            {}
        })
    )

    for _,v in pairs(on_sni_removed_callbacks) do v(id) end
end

local function add_sni(id, sni_bus_name, sni_obj_path, service, connection)
    systray.snis[id] = { id = id, _private = { on_icon_changed_callbacks = {} } }

    systray.snis[id]._private.proxy = dbus.Proxy:new(
        {
            bus = dbus.Bus.SESSION,
            name = sni_bus_name,
            interface = "org.kde.StatusNotifierItem",
            path = sni_obj_path
        }
    )

    systray.snis[id]._private.proxy:connect_signal(
        function (p, x, y)
            assert(p == systray.snis[id]._private.proxy)
            get_icon(systray.snis[id]._private.proxy._proxy, function(source_object, res, user_data)
                local ret = Gio.DBusProxy.call_finish(systray.snis[id]._private.proxy._proxy, res)
                for _,v in pairs(systray.snis[id]._private.on_icon_changed_callbacks) do v(ret.value[1].value) end
            end)            
        end,
        "NewIcon"
    )

    systray.snis[id].on_icon_changed = function(func)
        table.insert(systray.snis[id]._private.on_icon_changed_callbacks, func)
    end

    watch_name_id = Gio.bus_watch_name(
        Gio.BusType.SESSION,
        sni_bus_name,
        Gio.BusNameWatcherFlags.NONE,
        nil,
        GObject.Closure(function()
            remove_sni(id, watch_name_id, service, connection)
        end)
    )

    for _,v in pairs(on_sni_added_callbacks) do v(systray.snis[id]) end
end

local function method(connection, sender, path, interface, method, params, method_invocation)
    if method == "IsNotificationHostRegistered" then
        method_invocation:return_value(GVariant("(b)", { true }))
    elseif method == "ProtocolVersion" then
        method_invocation:return_value(GVariant("(s)", { "42" }))
    elseif method == "RegisterNotificationHost" then
        method_invocation:return_dbus_error("org.awesomewm.UnsupportedMethod", "Registering additional notification hosts is not supported.")
    elseif method == "RegisterStatusNotifierItem" then
        local service = params.value[1]
        local sni_bus_name, sni_obj_path
        
        if service:sub(1, 1) == "/" then
            sni_bus_name = sender
            sni_obj_path = service
        elseif Gio.dbus_is_name(service) then
            -- TODO (check gnome-shell-extension-appindicator's RegisterStatusNotifierItemAsync function on github)
            -- TODO throw error in awesome (with notification) with method name
            -- sni_bus_name = 
            -- sni_obj_path = "/StatusNotifierItem"
            method_invocation:return_dbus_error("org.awesomewm.UnsupportedParameter", "Using a dbus name as service is not yet supported.")
            return
        else
            method_invocation:return_dbus_error("org.awesomewm.InvalidParameter", "Use a dbus name or object path as parameter.")
            return
        end

        local id = sni_bus_name..sni_obj_path
        if systray.snis[id] then
            -- TODO delete and replace or reset old sni
        else
            add_sni(id, sni_bus_name, sni_obj_path, service, connection)

            connection:emit_signal(
                nil,
                "/StatusNotifierWatcher",
                "org.kde.StatusNotifierWatcher",
                "StatusNotifierItemRegistered",
                GVariant("(s)", { service })
            )

            local keys = { }
            for k, _ in pairs(systray.snis) do
                table.insert(keys, k)
            end
            connection:emit_signal(
                nil,
                "/StatusNotifierWatcher",
                "org.freedesktop.DBus.Properties",
                "PropertiesChanged",
                GVariant("(sa{sv}as)", {
                    "org.kde.StatusNotifierWatcher",
                    { RegisteredStatusNotifierItems = GVariant("as", keys) },
                    {}
                })
            )
        end

        method_invocation:return_value(nil)
    else
        -- TODO throw error in awesome (with notification) with method name
        method_invocation:return_dbus_error("org.awesomewm.InvalidMethod", "Wrong method")
    end
end

local function get_property(connection, sender, path, interface, property, value)
    if property == "RegisteredStatusNotifierItems" then
        local keys = { }
        for k, _ in pairs(systray.snis) do
            table.insert(keys, k)
        end
        return GVariant("as", keys)
    elseif property == "IsStatusNotifierHostRegistered" then
        return GVariant("b", true)
    elseif property == "ProtocolVersion" then
        return GVariant("i", 42)
    else
        -- TODO throw error in awesome (with notification) with property name
        method_invocation:return_dbus_error("org.awesomewm.InvalidProperty", "Wrong property")
    end
end

local function on_bus_acquired(connection, name, user_data)
	local function arg(name, signature)
		return Gio.DBusArgInfo { name = name, signature = signature }
    end
    
	local interface_info = Gio.DBusInterfaceInfo {
        name = "org.kde.StatusNotifierWatcher",
        methods = {
            Gio.DBusMethodInfo {
                name = "IsNotificationHostRegistered",
                out_args = {
                    arg("host_registered", "b")
                }
            },
            Gio.DBusMethodInfo {
                name = "ProtocolVersion",
                out_args = {
                    arg("version", "s")
                }
            },
            Gio.DBusMethodInfo {
                name = "RegisterNotificationHost",
                in_args = {
                    arg("service", "s")
                }
            },
            Gio.DBusMethodInfo {
                name = "RegisterStatusNotifierItem",
                in_args = {
                    arg("service", "s")
                }
            }
        },
        properties = {
            Gio.DBusPropertyInfo {
                name = "RegisteredStatusNotifierItems",
                signature = "as",
                flags = { "READABLE" }
            },
            Gio.DBusPropertyInfo {
                name = "IsStatusNotifierHostRegistered",
                signature = "b",
                flags = { "READABLE" }
            },
            Gio.DBusPropertyInfo {
                name = "ProtocolVersion",
                signature = "i",
                flags = { "READABLE" }
            }
        },
		signals = {
			Gio.DBusSignalInfo {
				name = "StatusNotifierItemRegistered",
				args = {
					arg("service", "s")
				}
            },
            Gio.DBusSignalInfo {
				name = "StatusNotifierItemUnregistered",
				args = {
					arg("service", "s")
				}
            },
            -- Gio.DBusSignalInfo { -- TODO unsupported
			-- 	name = "StatusNotifierHostRegistered"
			-- }
		}
    }
    
    connection:register_object(
        "/StatusNotifierWatcher",
        interface_info,
        GObject.Closure(method),
        GObject.Closure(get_property),
        nil -- set_property
    )
end

function systray.on_sni_added(func)
    table.insert(on_sni_added_callbacks, func)
end
function systray.on_sni_removed(func)
    table.insert(on_sni_removed_callbacks, func)
end

Gio.bus_own_name(
   Gio.BusType.SESSION,
   "org.kde.StatusNotifierWatcher",
   Gio.BusNameOwnerFlags.REPLACE,
   GObject.Closure(on_bus_acquired), -- bus acquired
   nil, -- name acquired
   nil -- name lost,
)

return systray
