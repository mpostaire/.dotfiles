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
    widget.visible = false

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
    end

    local low_battery_notification_sent = false
    local critical_battery_notification_sent = false
    battery.on_properties_changed(function()
        if not battery.enabled then return end
        widget.visible = battery.enabled

        widget:update(get_icon(), get_text())

        if battery.state == "discharging" then
            if battery.level == "critical" and not critical_battery_notification_sent then
                naughty.notification {
                    title = "Batterie critique",
                    message = "Branchez l'alimentation",
                }
                critical_battery_notification_sent = true
            elseif battery.level == "low" and not low_battery_notification_sent then
                naughty.notification {
                    title = "Batterie basse",
                    message = "Branchez l'alimentation",
                }
                low_battery_notification_sent = true
            else
                naughty.notification {
                    title = "Batterie en décharge",
                    message = helpers.s_to_hms(battery.time_to_empty).." restantes avant décharge complète"
                }
                critical_battery_notification_sent = false
                low_battery_notification_sent = false
            end
        elseif battery.state == "fully-charged" then
            naughty.notification {
                title = "Batterie chargée",
                message = "Vous pouvez débrancher l'alimentation"
            }
            critical_battery_notification_sent = false
            low_battery_notification_sent = false
        else
            naughty.notification {
                title = "Batterie en charge",
                message = helpers.s_to_hms(battery.time_to_full).." restantes avant charge complète"
            }
            critical_battery_notification_sent = false
            low_battery_notification_sent = false
        end
    end)

    return widget
end
