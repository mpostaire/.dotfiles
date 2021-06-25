local dbus = require("dbus_proxy")
local gstring = require("gears.string")
local helpers = require("util.helpers")
local lgi = require("lgi")
local GLib = lgi.GLib
local Gio = lgi.Gio
local GObject = lgi.GObject
local GVariant = GLib.Variant

local wibox = require("wibox")

-- hot corner--side prototype
local s = mouse.screen
-- wibox {
--     x = s.geometry.x,
--     y = s.geometry.y,
--     visible = true,
--     screen = s,
--     ontop = true,
--     -- opacity = 0.0,
--     height = s.geometry.height,
--     width = 1,
--     bg = "#00FF00",
--     type = 'utility'
-- }

-- Specification: https://github.com/gnustep/libs-dbuskit/blob/master/Bundles/DBusMenu/com.canonical.dbusmenu.xml

local dbusmenu_iface = "com.canonical.dbusmenu"
local registrar_iface = "com.canonical.AppMenu.Registrar"
local registrar_path = "/com/canonical/AppMenu/Registrar"

-- TODO optimize this so it should be able to update elements without a complete rebuild
local function build_menu(proxy, id)
    local menu = {}

    proxy:AboutToShow(id)
    proxy:Event(id, "opened", GVariant("s", ""), 0)
    -- TODO sometimes this line (in vscode only ??) throws an attempt to index a nil value
    --      if this returns nil and an error, it means id is not a menu that exist anymore (use getlayout to get a new one ??)
    local layout = proxy:GetLayout(id, 1, {})[2][3]

    for _, item in ipairs(layout) do
        local id = item[1]
        local properties = item[2]
        local submenu = item[3]
        
        -- default properties to be overwritten if necessary
        local default_item = {
            "", -- label
            function() -- cmd
                proxy:Event(id, "clicked", GVariant("s", ""), 0)
            end,
            nil, -- icon
            false, -- disabled
            false, -- invisible
            false, -- separator
            -1, -- toggle-state
            theme = {}
        }

        for prop, value in pairs(properties) do
            if prop == "type" and value == "separator" then
                default_item[6] = true
            elseif prop == "label" and value ~= "" then
                default_item[1] = value
            elseif prop == "children-display" and value == "submenu" and submenu then
                default_item[2] = {
                    generator = function() -- TODO rename function ?????
                        return build_menu(proxy, id)
                    end,
                    hide_callback = function()
                        proxy:Event(id, "closed", GVariant("s", ""), 0)
                    end
                }
            elseif prop == "icon-name" and value ~= "" then
                default_item[3] = helpers.get_icon(value, _, 32)
            elseif prop == "icon-data" and value and not default_item[3] then
                -- for k,v in ipairs(value) do
                --     print(v)
                -- end
                -- TODO for this line to work I have to use value:get_data_as_bytes() (where value must be a variant)
                --      but it is not possible with dbus_proxy because it automatically strips the variants.
                -- default_item[3] = lgi.cairo.ImageSurface.create_for_data(value:get_data_as_bytes(), lgi.cairo.Format.ARGB32, 16, 16, 0)
            elseif prop == "enabled" then
                default_item[4] = not value
            elseif prop == "visible" then
                default_item[5] = not value
            elseif prop == "toggle-state" then
                default_item[7] = value
            elseif prop == "toggle-type" and value ~= "" then
                default_item.theme.checked = value == "radio" and "●" or nil
            end
        end

        menu[#menu + 1] = default_item
    end

    return menu
end

local appmenu = {}

local registered_windows = {}

local function method(connection, sender, path, interface, method, params, method_invocation)
    if method == "RegisterWindow" then
        -- params.value[1] == windowId
        -- params.value[2] == path
        registered_windows[params.value[1]] = {
            service = sender,
            path = params.value[2]
        }
        
        connection:emit_signal(
            nil,
            registrar_path,
            registrar_iface,
            "WindowRegistered",
            GVariant("(uso)", {
                params.value[1],
                sender,
                params.value[2]
            })
        )
        method_invocation:return_value(nil)
    elseif method == "UnregisterWindow" then
        -- params.value[1] == windowId
        registered_windows[params.value[1]].proxy = nil -- useless line ??? check of lua gc works
        registered_windows[params.value[1]] = nil
        
        connection:emit_signal(
            nil,
            registrar_path,
            registrar_iface,
            "WindowUnregistered",
            GVariant("u", params.value[1])
        )
        method_invocation:return_value(nil)
    elseif method == "GetMenuForWindow" then
        -- params.value[1] == windowId
        local ret = registered_windows[params.value[1]]
        if ret then
            method_invocation:return_value(GVariant("(so)", { ret.service, ret.path }))
        else
            method_invocation:return_dbus_error("org.awesomewm.UnregisteredWindowParameter", "Window Id parameter is not registered")
        end
    elseif method == "GetMenus" then
        local ret = {}
        for k, v in pairs(registered_windows) do
            table.insert(ret, { k, v.service, v.path })
        end
        method_invocation:return_value(GVariant("(a(uso))", { ret }))
    else
        -- TODO throw error in awesome (with notification) with method name
        method_invocation:return_dbus_error("org.awesomewm.InvalidMethod", "Wrong method")
    end
end

local function on_bus_acquired(connection, name, user_data)
	local function arg(name, signature)
		return Gio.DBusArgInfo { name = name, signature = signature }
    end
    
	local interface_info = Gio.DBusInterfaceInfo {
        name = registrar_iface,
        methods = {
            Gio.DBusMethodInfo {
                name = "RegisterWindow",
                in_args = {
                    arg("windowId", "u"),
                    arg("menuObjectPath", "o")
                }
            },
            Gio.DBusMethodInfo {
                name = "UnregisterWindow",
                in_args = {
                    arg("windowId", "u")
                }
            },
            Gio.DBusMethodInfo {
                name = "GetMenuForWindow",
                in_args = {
                    arg("windowId", "u")
                },
                out_args = {
                    arg("service", "s"),
                    arg("path", "o")
                }
            },
            Gio.DBusMethodInfo {
                name = "GetMenus",
                out_args = {
                    arg("menus", "a(uso)")
                }
            }
        },
		signals = {
			Gio.DBusSignalInfo {
				name = "WindowRegistered",
				args = {
					arg("windowId", "u"),
					arg("service", "s"),
					arg("path", "o")
				}
            },
            Gio.DBusSignalInfo {
				name = "WindowUnregistered",
				args = {
					arg("windowId", "u")
				}
            }
		}
    }
    
    connection:register_object(
        registrar_path,
        interface_info,
        GObject.Closure(method),
        nil, -- get_property
        nil -- set_property
    )
end

Gio.bus_own_name(
   Gio.BusType.SESSION,
   registrar_iface,
   Gio.BusNameOwnerFlags.REPLACE,
   GObject.Closure(on_bus_acquired), -- bus acquired
   nil, -- name acquired
   nil -- name lost,
)

-- TODO this is not finished (it does not supports correctly a declarative constructor with arguments)
local beautiful = require("beautiful")
local dpi = require("beautiful").xresources.apply_dpi
local function interactive_background(args)
    if not args then args = {} end
    args.fg = args.fg or beautiful.fg_normal
    args.bg = args.bg or beautiful.bg_normal
    args.fg_hover = args.fg_hover or beautiful.bg_normal
    args.bg_hover = args.bg_hover or beautiful.fg_normal

    local widget = wibox.widget {
        hover = function(self)
            self.fg = args.fg_hover
            self.bg = args.bg_hover
        end,
        unhover = function(self)
            self.fg = args.fg
            self.bg = args.bg
        end,
        widget = wibox.container.background
    }
    
    local old_cursor, old_wibox, mouse_inside
    widget:connect_signal("mouse::enter", function()
        -- Hm, no idea how to get the wibox from this signal's arguments...
        local w = _G.mouse.current_wibox
        old_cursor, old_wibox = w.cursor, w
        w.cursor = args.cursor or "hand2"

        widget.mouse_inside = true

        widget:hover()
    end)
    widget:connect_signal("mouse::leave", function()
        if old_wibox then
            old_wibox.cursor = old_cursor
            old_wibox = nil
        end

        widget.mouse_inside = false

        if not widget.lock then
            widget:unhover()
        end
    end)

    return widget
end

-- TODO case when window closes while menu open
-- TODO react to layout change when menu is opened

local menu_popup = require("popups.menu")
local awful = require("awful")

return function()
    local appmenu_geo, widget_geo, mouse_inside
    local appmenu_widget = wibox.widget {
        buttons = awful.button({}, 1, function(arg)
            appmenu_geo = { x = arg.x, y = arg.y - 1, width = arg.width, height = arg.height }
        end),
        layout = wibox.layout.fixed.horizontal()
    }
    appmenu_widget:connect_signal("mouse::leave", function()
        if current_menu then
            current_menu.wibox.start_mousegrabber()
        end
    end)
    local title_widget = wibox.widget.textbox()
    local widget = wibox.widget {
        title_widget,
        appmenu_widget,
        buttons = awful.button({}, 1, function(arg)
            widget_geo = { x = arg.x, y = arg.y - 1, width = arg.width, height = arg.height }
        end),
        layout = wibox.layout.fixed.horizontal
    }

    -- TODO gtk apps support
    local function get_appmenu(client)
        local menu = registered_windows[client.window]
        if not menu then return end
        if not menu.proxy then
            menu.proxy = dbus.Proxy:new {
                bus = dbus.Bus.SESSION,
                name = menu.service,
                interface = dbusmenu_iface,
                path = menu.path
            }
            menu.proxy:connect_signal(
                function(p, rev, id)
                    assert(p == menu.proxy)
                    menu.menu = nil -- TODO refactor this menu.menu thing
                    -- make each menu have its id and rebuild it if necessary BUT do not rebuild submenus
                    -- (only the case if the id to rebuild is the root: 0)
                end,
                "LayoutUpdated"
            )
            -- menu.proxy:connect_signal(
            --     function(p, x, y)
            --         assert(p == menu.proxy)
            --         print("ItemsPropertiesUpdated emitted with params: ", x, y, client.name)
            --     end,
            --     "ItemsPropertiesUpdated"
            -- )
        end

        -- TODO make the popup_menu updateable by selection of menu id set with the id the proxy sends us
        menu.menu = build_menu(menu.proxy, 0)
        for k,v in ipairs(menu.menu) do
            key = ''
            local temp = wibox.widget {
                {
                    {
                        markup = string.gsub(
                            gstring.xml_escape(v[1]), "(_+)(%w?)",
                            function (l, ll)
                                local len = #l
                                if key == '' and len % 2 == 1 then
                                    key = string.lower(ll)
                                    return "<u>" .. ll .. "</u>"
                                else
                                    -- use math.floor(a / b) here because luajit doesn't support the // operator
                                    return l:sub(0, math.floor(len / 2)) .. ll
                                end
                            end
                        ),
                        widget = wibox.widget.textbox
                    },
                    margins = dpi(8),
                    widget = wibox.container.margin
                },
                buttons = awful.button({}, 1, function(arg)
                    if current_menu then
                        current_menu:hide()
                        return
                    end

                    arg.widget.lock = true

                    local items = v[2].generator()
                    items.close_callback = function()
                        arg.widget.lock = false
                        if not arg.widget.mouse_inside then
                            arg.widget:unhover()
                        end
                        current_menu = nil

                        local m = mouse.coords()
                        if not (m.x > widget_geo.x and
                            m.x < widget_geo.x + widget_geo.width and
                            m.y > widget_geo.y and
                            m.y < widget_geo.y + widget_geo.height) then
                            title_widget.visible = true
                            appmenu_widget.visible = false
                        end
                    end
                    items.mouse_free_area = appmenu_geo
                    current_menu = menu_popup(items) -- TODO cache this no need to generate a new one each time
                    current_menu:show { coords = { x = arg.x, y = arg.y } }
                end),
                widget = interactive_background
            }
            temp:connect_signal("mouse::enter", function(widget, geometry)
                if not current_menu then return end

                current_menu:hide()

                widget.lock = true

                local items = v[2].generator()
                items.close_callback = function()
                    widget.lock = false
                    if not widget.mouse_inside then
                        widget:unhover()
                    end
                    current_menu = nil

                    local m = mouse.coords()
                    if not (m.x > widget_geo.x and
                        m.x < widget_geo.x + widget_geo.width and
                        m.y > widget_geo.y and
                        m.y < widget_geo.y + widget_geo.height) then
                        title_widget.visible = true
                        appmenu_widget.visible = false
                    end
                end
                items.mouse_free_area = appmenu_geo
                current_menu = menu_popup(items) -- TODO cache this no need to generate a new one each time
                current_menu:show { coords = { x = geometry.x, y = geometry.y } }
            end)
            appmenu_widget:add(temp)
        end
    end

    local function set_title(c)
        if not c.name then return end
        title_widget.markup = "<b>"..c.name.."</b>"
    end
    
    client.connect_signal("focus", function(c)
        set_title(c)
        c:connect_signal("property::name", set_title)

        if mouse_inside then
            appmenu_widget:reset()
            get_appmenu(c, appmenu_widget)
        end
    end)

    client.connect_signal("unfocus", function(c)
        title_widget.markup = ""
        c:disconnect_signal("property::name", set_title)
    end)

    widget:connect_signal("mouse::enter", function()
        title_widget.visible = false
        appmenu_widget.visible = true
        mouse_inside = true

        if not current_menu and client.focus and #appmenu_widget.children == 0 then
            get_appmenu(client.focus, appmenu_widget)
        end
    end)

    widget:connect_signal("mouse::leave", function()
        if current_menu then return end

        title_widget.visible = true
        appmenu_widget.visible = false
        mouse_inside = false

        if #appmenu_widget.children > 0 then
            appmenu_widget:reset()
        end
    end)

    return widget
end
