-- this is an incomplete basic network widget
-- bug: after resuming from a suspend, if ssid is changed, it will not be detected and last one will show
--      this may be a symptom of a larger problem
-- quick fix: restart awesome (Super + r)

local wibox = require("wibox")
local beautiful = require("beautiful")
local popup_notification = require("util.popup_notification")
local rofi = require("util.rofi")
local awful = require("awful")
local gears = require("gears")
local variables = require("configuration.variables")

local p = require("dbus_proxy")

local icons = {
    "",
    ""
}

local notification = popup_notification:new()

local icon_widget = wibox.widget {
    {
        id = "icon",
        font = "Material Icons 12",
        widget = wibox.widget.textbox
    },
    widget = wibox.container.margin(_, beautiful.wibar_widgets_padding, beautiful.widgets_inner_padding, 0, 0)
}

local text_widget = wibox.widget {
    {
        id = "text",
        widget = wibox.widget.textbox
    },
    widget = wibox.container.margin(_, 0, beautiful.wibar_widgets_padding, 0, 0)
}

local network_widget = wibox.widget {
    icon_widget,
    text_widget,
    layout = wibox.layout.fixed.horizontal
}

local manager_proxy = p.Proxy:new(
    {
        bus = p.Bus.SYSTEM,
        name = "org.freedesktop.NetworkManager",
        interface = "org.freedesktop.NetworkManager",
        path = "/org/freedesktop/NetworkManager"
    }
)

local connection_path = manager_proxy.ActiveConnections[1]
local connection_proxy
if connection_path then
    connection_proxy = p.Proxy:new(
    {
        bus = p.Bus.SYSTEM,
        name = "org.freedesktop.NetworkManager",
        interface = "org.freedesktop.NetworkManager.Connection.Active",
        path = connection_path
    }
)
end

local function get_icon()
    if manager_proxy.ActiveConnections[1] then
        return icons[1]
    else
        return icons[2]
    end
end

local function get_title()
    return "<b>Réseau</b>"
end

local function get_message()
    return "En construction"
end

local function update_widget()
    local icon = get_icon()
    icon_widget:get_children_by_id('icon')[1]:set_markup_silently(icon)
    if manager_proxy.ActiveConnections[1] then
        text_widget.visible = true
        text_widget:get_children_by_id('text')[1]:set_markup_silently(connection_proxy.Id)
    else
        text_widget.visible = false
    end

    notification:set_markup(get_title(), get_message())
    notification:set_icon(icon)
end

-- we update once so the widget is not empty at creation
update_widget()

network_widget:connect_signal("button::press", function(_, _, _, button)
    if button == 1 then
        rofi.network_menu()
    end
end)

local old_cursor, old_wibox
network_widget:connect_signal("mouse::enter", function()
    notification:show(true)

    local w = mouse.current_wibox
    old_cursor, old_wibox = w.cursor, w
    w.cursor = "hand1"
end)
network_widget:connect_signal("mouse::leave", function()
    notification:hide()

    if old_wibox then
        old_wibox.cursor = old_cursor
        old_wibox = nil
    end
end)

manager_proxy:on_properties_changed(function (p, changed, invalidated)
    assert(p == manager_proxy)
    for k, v in pairs(changed) do
        if k == "ActiveConnections" then
            if manager_proxy.ActiveConnections[1] then
                connection_proxy.path = manager_proxy.ActiveConnections[1]
            end
            update_widget()
        end
    end
end)

network_widget.keys = gears.table.join(
    awful.key({ variables.modkey }, "w", rofi.network_menu,
                {description = "show the network menu", group = "launcher"})
)

return network_widget
