local dbus = require("dbus_proxy")
local lgi = require("lgi")
local helpers = require("util.helpers")
local Gio = lgi.Gio
local GObject = lgi.GObject
local GVariant = lgi.GLib.Variant

-- Specification: https://github.com/gnustep/libs-dbuskit/blob/master/Bundles/DBusMenu/com.canonical.dbusmenu.xml

-- MEMLEAK proxies created in add_sni() may not be garbage collected ?

-- TODO optimize this so it should be able to update elements without a complete rebuild
local function build_menu(layout, proxy)
    local id = layout[1]
    local properties = layout[2]
    local submenu = layout[3]

    local root = {
        "???", -- label
        function() -- cmd
            proxy:Event(id, "clicked", GVariant("i", 0), 0)
        end,
        nil, -- icon
        false, -- disabled
        true, -- visible
        false, -- separator
        -1, -- toggle-state
    } -- TODO set default properties here to be overwritten in loop below
    for prop, value in pairs(properties) do
        if prop == "type" and value == "separator" then
            root[6] = true
            break
        end

        if prop == "label" and value ~= "" then
            root[1] = value
        elseif prop == "children-display" and value == "submenu" and submenu then
            root[2] = {}
            for _, item in ipairs(submenu) do
                table.insert(root[2], build_menu(item, proxy))
            end
        elseif prop == "icon-name" and value ~= "" then
            -- print(value)
            root[3] = helpers.get_icon(value, _, 32)
        elseif prop == "enabled" then
            root[4] = not value
        elseif prop == "visible" then
            root[5] = value
        elseif prop == "toggle-state" then
            root[7] = value
        end
    end

    -- if we are at the upmost root, we return directly its submenus
    if id == 0 then return root[2] end
    return root
end


local systray = { snis = {} }

local on_sni_added_callbacks, on_sni_removed_callbacks = {}, {}

local menu_default_props = {
    type = "standard",
    label = "",
    enabled = true,
    visible = true,
    ["icon-name"] = "",
    ["icon-data"] = nil,
    shortcut = nil,
    ["toggle-type"] = "",
    ["toggle-state"] = -1,
    ["children-display"] = "",
    disposition = "normal"
}

local function dbus_proxy_get_prop(proxy, interface, property, callback)
    Gio.DBusProxy.call(
        proxy._proxy,
        "org.freedesktop.DBus.Properties.Get",
        GVariant("(ss)", {interface, property }),
        Gio.DBusCallFlags.NONE,
        -1,
        nil,
        function(source_object, res, user_data)
            local ret = Gio.DBusProxy.call_finish(proxy._proxy, res)
            callback(ret)
        end
    )
end

local function item_get_status(status)
    if status == "NeedsAttention" then return 2 end
    if status == "Active" then return 1 end
    if status == "Passive" then return 0 end
    return -1
end

local function item_get_icon(icon, attention_icon, icon_theme, status)
    if status == 1 then
        return helpers.get_icon(icon, icon_theme)
    elseif status == 2 then
        return helpers.get_icon(attention_icon, icon_theme)
    end
    return nil
end

local function remove_sni(id, watch_name_id, service, connection)
    systray.snis[id] = nil
    local keys = { }
    for k, _ in pairs(systray.snis) do
        table.insert(keys, k)
    end

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
    local on_icon_changed_callbacks, on_status_changed_callbacks, on_show_menu_callbacks = {}, {}, {}

    local item_proxy = dbus.Proxy:new {
        bus = dbus.Bus.SESSION,
        name = sni_bus_name,
        interface = "org.kde.StatusNotifierItem",
        path = sni_obj_path
    }

    local status = item_get_status(item_proxy.Status)
    local icon = item_proxy.IconName
    local attention_icon = item_proxy.AttentionIconName
    local icon_theme = item_proxy.IconThemePath

    item_proxy:connect_signal(
        function(p)
            assert(p == item_proxy)
            dbus_proxy_get_prop(item_proxy, "org.kde.StatusNotifierItem", "IconThemePath", function(ret)
                local value = ret.value[1].value
                if value ~= icon_theme then
                    icon_theme = value
                    if status >= 1 then
                        for _,v in pairs(on_icon_changed_callbacks) do v(item_get_icon(icon, attention_icon, icon_theme, status)) end
                    end
                end
            end)
        end,
        "NewIconThemePath"
    )

    item_proxy:connect_signal(
        function(p)
            assert(p == item_proxy)
            dbus_proxy_get_prop(item_proxy, "org.kde.StatusNotifierItem", "IconName", function(ret)
                local value = ret.value[1].value
                if value ~= icon then
                    icon = value
                    if status >= 1 then
                        for _,v in pairs(on_icon_changed_callbacks) do v(item_get_icon(icon, attention_icon, icon_theme, status)) end
                    end
                end
            end)
        end,
        "NewIcon"
    )

    item_proxy:connect_signal(
        function(p)
            assert(p == item_proxy)
            dbus_proxy_get_prop(item_proxy, "org.kde.StatusNotifierItem", "AttentionIconName", function(ret)
                local value = ret.value[1].value
                if value ~= attention_icon then
                    attention_icon = value
                    if status >= 1 then
                        for _,v in pairs(on_icon_changed_callbacks) do v(item_get_icon(icon, attention_icon, icon_theme, status)) end
                    end
                end
            end)
        end,
        "NewAttentionIcon"
    )

    item_proxy:connect_signal(
        function(p)
            assert(p == item_proxy)
            dbus_proxy_get_prop(item_proxy, "org.kde.StatusNotifierItem", "Status", function(ret)
                local value = item_get_status(ret.value[1].value)
                if value ~= status then
                    status = value
                    if status >= 1 then
                        for _,v in pairs(on_icon_changed_callbacks) do v(item_get_icon(icon, attention_icon, icon_theme, status)) end
                    end
                    for _,v in pairs(on_status_changed_callbacks) do v(status >= 1) end
                end
            end)
        end,
        "NewStatus"
    )

    -- TODO handle case where there is no menu
    local menu_proxy = dbus.Proxy:new {
        bus = dbus.Bus.SESSION,
        name = sni_bus_name,
        interface = "com.canonical.dbusmenu",
        path = item_proxy.Menu
    }

    -- TODO check TODOs inside the systray.snis[id].activate function
    -- local menu_layout = menu_proxy:GetLayout(0, -1, {})

    -- only prop of this proxy that may be useful (array of paths to use for icon lookup)
    -- local menu_icon_themes = menu_proxy.IconThemePath

    watch_name_id = Gio.bus_watch_name(
        Gio.BusType.SESSION,
        sni_bus_name,
        Gio.BusNameWatcherFlags.NONE,
        nil,
        GObject.Closure(function()
            remove_sni(id, watch_name_id, service, connection)
        end)
    )

    systray.snis[id] = {
        id = id,
        scroll = function(delta, orientation)
            item_proxy:Scroll(delta, orientation)
        end,
        secondary_activate = function(x, y)
            item_proxy:SecondaryActivate(x, y)
        end,
        on_new_icon = function(func)
            table.insert(on_icon_changed_callbacks, func)
            func(item_get_icon(icon, attention_icon, icon_theme, status))
        end,
        on_new_status = function(func)
            table.insert(on_status_changed_callbacks, func)
            func(status >= 1)
        end,
        on_show_menu = function(func)
            table.insert(on_show_menu_callbacks, func)
        end,
        activate = function(x, y)
            -- TODO this is not working check doc to better retreive layout updates (subscribe to signal etc.)
            --      cache layout and change it only after an update
            local need_update = menu_proxy:AboutToShow(0)
            -- if need_update then
            --     menu_layout = menu_proxy:GetLayout(0, -1, {})
            -- end

            -- TODO check upper TODO (for now we get the entire layout each time: this is very inneficient)
            -- local menu_items = build_menu(menu_layout[2], menu_proxy)
            local menu_items = build_menu(menu_proxy:GetLayout(0, -1, {})[2], menu_proxy)
            for _,v in pairs(on_show_menu_callbacks) do v(menu_items, x, y) end
        end
    }

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
