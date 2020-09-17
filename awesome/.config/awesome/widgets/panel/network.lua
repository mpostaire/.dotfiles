-- this is an incomplete basic network widget
-- ethernet support not tested

local beautiful = require("beautiful")
local awful = require("awful")
local gears = require("gears")
local color = require("themes.util.color")
local variables = require("config.variables")
local network = require("util.network")
local base_widget_panel = require("widgets.panel.base")
local network_control_widget = require("widgets.controls.network")

local icons = {
    wifi = {
        [0] = "", -- (this icon is for connection loading) //TODO: see networkmanager api, get active connection device. State property is the state of the connection
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
    if not network.enabled then return nil end

    local widget = base_widget_panel{control_widget = network_control_widget()}

    local function get_icon()
        if network.state == 'wifi' then
            widget:set_icon_color(beautiful.fg_normal)
            if not network.strength then
                return icons[network.state][0] -- temp check if this is correct (I did this as a quick fix whithout a thougt about it)
            elseif network.strength < 20 then
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
            widget:set_icon_color(color.white_alt)
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

    -- local widget_keys = gears.table.join(
    --     awful.key({ variables.modkey }, "w", rofi.network_menu,
    --                 {description = "show the network menu", group = "launcher"})
    -- )

    -- _G.root.keys(gears.table.join(_G.root.keys(), widget_keys))

    return widget
end
