local beautiful = require("beautiful")
local color = require("themes.color")
local naughty = require("naughty")
local base_panel_widget = require("widgets.panel.base")
local battery = require("util.battery")
local helpers = require("util.helpers")

local icons = {
    charging = {
        "",
        "",
        "",
        "",
        ""
    },
    discharging = {
        "",
        "",
        "",
        "",
        ""
    },
    full = ""
}

return function()
    if not battery.enabled then return nil end
    
    local widget = base_panel_widget()

    local function get_icon()
        local icon
        if battery.state == "full" then
            icon = icons.full
        elseif battery.percentage >= 0 and battery.percentage < 20 then
            icon = icons[battery.state][1]
        elseif battery.percentage >= 20 and battery.percentage < 40 then
            icon = icons[battery.state][2]
        elseif battery.percentage >= 40 and battery.percentage < 60 then
            icon = icons[battery.state][3]
        elseif battery.percentage >= 60 and battery.percentage < 80 then
            icon = icons[battery.state][4]
        elseif battery.percentage >= 80 and battery.percentage <= 100 then
            icon = icons[battery.state][5]
        end

        if battery.state == "charging" then
            widget:set_icon_color(color.yellow)
        elseif battery.state == "discharging" and battery.percentage < 20 then
            widget:set_icon_color(color.red)
        elseif battery.state == "full" then
            widget:set_icon_color(color.green)
        else
            widget:set_icon_color(beautiful.fg_normal)
        end

        return icon
    end

    local function get_text()
        return math.floor(battery.percentage).. "%"
    end

    -- we update once so the widget is not empty at creation
    widget:update(get_icon(), get_text())

    local low_battery_notification_sent = false
    local critical_battery_notification_sent = false
    battery.on_properties_changed(function(changed)
        widget:update(get_icon(), get_text())

        for k,_ in pairs(changed) do
            if k == "State" then
                if battery.state == "discharging" then
                    naughty.notify {
                        title = "Batterie en décharge",
                        text = helpers.s_to_hms(battery.time_to_empty).." restantes avant décharge complète"
                    }
                elseif battery.state == "charging" then
                    naughty.notify {
                        title = "Batterie en charge",
                        text = helpers.s_to_hms(battery.time_to_full).." restantes avant charge complète"
                    }
                elseif battery.state == "full" then
                    naughty.notify {
                        title = "Batterie chargée",
                        text = "Vous pouvez débrancher l'alimentation"
                    }
                end
            elseif k == "Percentage" and battery.state == "discharging" then
                if battery.percentage < 10 and not critical_battery_notification_sent then
                    naughty.notify {
                        title = "Batterie critique",
                        text = "Branchez l'alimentation",
                    }
                    critical_battery_notification_sent = true
                elseif battery.percentage < 20 and not low_battery_notification_sent then
                    naughty.notify {
                        title = "Batterie basse",
                        text = "Branchez l'alimentation",
                    }
                    low_battery_notification_sent = true
                else
                    critical_battery_notification_sent = false
                    low_battery_notification_sent = false
                end
            end
        end
    end)

    return widget
end
