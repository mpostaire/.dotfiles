-- this is an incomplete basic network widget
-- ethernet support not tested, ethernet icon is a placeholder

local beautiful = require("beautiful")
local rofi = require("util.rofi")
local awful = require("awful")
local gears = require("gears")
local variables = require("config.variables")
local network = require("util.network")
local base_widget_panel = require("widgets.panel.base")
local capi = {root = root}

local icons = {
    wifi = "",
    off = "",
    eth = ""
}

local network_widget = base_widget_panel:new()
network_widget:enable_mouse_hover_effects()

local function get_icon()
    if network.state == 'wifi' or network.state == 'eth' then
        network_widget:set_icon_color(beautiful.fg_normal)
    else
        network_widget:set_icon_color(beautiful.white_alt)
    end
    return icons[network.state]
end

local function get_text()
    if network.state == 'off' then
        return "disconnected"
    else
        return network.ssid
    end
end

local function update_widget()
    local icon = get_icon()
    if network.state == 'wifi' or network.state == 'eth' then
        network_widget:update(icon, get_text())
    else
        network_widget:update(icon, get_text())
    end
end

network.on_properties_changed(update_widget)

-- we update once so the widget is not empty at creation
update_widget()

network_widget:connect_signal("button::press", function(_, _, _, button)
    if button == 1 then
        rofi.network_menu()
    end
end)

local widget_keys = gears.table.join(
    awful.key({ variables.modkey }, "w", rofi.network_menu,
                {description = "show the network menu", group = "launcher"})
)

capi.root.keys(gears.table.join(capi.root.keys(), widget_keys))

return network_widget
