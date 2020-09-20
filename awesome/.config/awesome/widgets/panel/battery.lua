local beautiful = require("beautiful")
local color = require("themes.util.color")
local naughty = require("naughty")
local base_panel_widget = require("widgets.panel.base")
local battery = require("util.battery")
local helpers = require("util.helpers")

local icons = {
    charging = {
        critical = "",
        low = "",
        normal = "",
        high = "",
        full = ""
    },
    discharging = {
        critical = "",
        low = "",
        normal = "",
        high = "",
        full = ""
    }
}
icons["fully-charged"] = icons.charging

return function()  
    local widget = base_panel_widget()

    local function get_icon()
        local icon = icons[battery.state][battery.level]

        if battery.state == "fully-charged" then
            widget:set_icon_color(color.green)
        elseif battery.state == "charging" then
            widget:set_icon_color(color.yellow)
        elseif battery.state == "discharging" and battery.level == "critical" then
            widget:set_icon_color(color.red)
        else
            widget:set_icon_color(beautiful.fg_normal)
        end

        return icon
    end

    local function get_text()
        return math.floor(battery.percentage).. "%"
    end

    -- we update once so the widget is not empty at creation
    if battery.enabled then
        widget:update(get_icon(), get_text())
        widget.visible = true
    else
        widget.visible = false
    end

    battery.on_percentage_changed(function()
        widget:update_label(get_text())
    end)

    battery.on_state_changed(function()
        widget:update_icon(get_icon())

        if battery.state == "discharging" then
            naughty.notification {
                title = "Batterie en décharge",
                message = helpers.s_to_hms(battery.time_to_empty).." restantes avant décharge complète"
            }
        elseif battery.state == "charging" then
            naughty.notification {
                title = "Batterie en charge",
                message = helpers.s_to_hms(battery.time_to_full).." restantes avant charge complète"
            }
        elseif battery.state == "fully-charged" then
            naughty.notification {
                title = "Batterie chargée",
                message = "Vous pouvez débrancher l'alimentation"
            }
        end
    end)
    
    battery.on_level_changed(function()
        widget:update_icon(get_icon())

        if battery.state ~= "discharging" then return end

        if battery.level == "low" then
            naughty.notification {
                title = "Batterie basse",
                message = "Branchez l'alimentation",
            }
        elseif battery.level == "critical" then       
            naughty.notification {
                title = "Batterie critique",
                message = "Branchez l'alimentation",
            }
        end
    end)

    battery.on_enabled_changed(function()
        widget.visible = battery.enabled
    end)

    return widget
end
