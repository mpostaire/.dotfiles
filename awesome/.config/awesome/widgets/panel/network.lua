-- this is an incomplete basic network widget
-- ethernet support not tested, ethernet icon is a placeholder
-- TODO: current 'off' icon should be not connected icon and off should show no icon or another one

local beautiful = require("beautiful")
local rofi = require("util.rofi")
local awful = require("awful")
local gears = require("gears")
local variables = require("config.variables")
local network = require("util.network")
local base_widget_panel = require("widgets.panel.base")
local capi = {root = root}

local icons = {
    wifi = {
        [0] = "", --TODO: see networkmanager api, get active connection device. State property is the state of the connection
        "",
        "",
        "",
        "",
        ""
    },
    off = "",
    eth = ""
}

return function()
    local widget = base_widget_panel:new()

    local function get_icon()
        if network.state == 'wifi' then
            widget:set_icon_color(beautiful.fg_normal)
            if network.strength < 20 then
                return icons[network.state][1]
            elseif network.strength < 40 then
                return icons[network.state][2]
            elseif network.strength < 60 then
                return icons[network.state][3]
            elseif network.strength < 80 then
                return icons[network.state][4]
            else
                return icons[network.state][5]
            end
        elseif(network.state == 'eth') then
            widget:set_icon_color(beautiful.fg_normal)
            return icons[network.state]
        else
            widget:set_icon_color(beautiful.white_alt)
            return icons[network.state]
        end
    end

    local function get_text()
        if network.state == 'off' then
            return "off"
        else
            return network.ssid
        end
    end

    network.on_properties_changed(function()
        widget:update(get_icon(), get_text())
    end)

    -- we update once so the widget is not empty at creation
    widget:update(get_icon(), get_text())

    widget:connect_signal("button::press", function(_, _, _, button)
        if button == 1 then
            rofi.network_menu()
        end
    end)

    local widget_keys = gears.table.join(
        awful.key({ variables.modkey }, "w", rofi.network_menu,
                    {description = "show the network menu", group = "launcher"})
    )

    capi.root.keys(gears.table.join(capi.root.keys(), widget_keys))

    return widget
end
