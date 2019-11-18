local beautiful = require("beautiful")
local base_panel_widget = require("widgets.panel.base")
local battery = require("util.battery")

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
    local widget = base_panel_widget:new()

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
            widget:set_icon_color(beautiful.yellow)
        elseif battery.state == "discharging" and battery.percentage < 20 then
            widget:set_icon_color(beautiful.red)
        elseif battery.state == "full" then
            widget:set_icon_color(beautiful.green)
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

    battery.on_properties_changed(function()
        widget:update(get_icon(), get_text())
    end)

    return widget
end

-- MOVE notification code elsewhere

-- local notification = popup_notification:new()
-- notification.popup.widget:get_children_by_id("icon")[1].font = "DejaVuSansMono Nerd Font 16"

-- battery_widget:buttons(gears.table.join(
--     awful.button({}, 1, function() notification:toggle() end)
-- ))

-- local function get_title()
--     if battery.state == states.full then
--         return "<b>Batterie chargée</b>"
--     else
--         if battery.state == states.charging then
--             return "<b>Batterie en charge</b>"
--         elseif battery.state == states.discharging then
--             return "<b>Batterie en décharge</b>"
--         end
--     end
-- end

-- local function get_message()
--     if battery.state == states.full then
--         return "Vous pouvez débrancher du secteur"
--     else
--         local time
--         if battery.state == states.charging then
--             time = battery.TimeToFull
--         elseif battery.state == states.discharging then
--             time = battery.TimeToEmpty
--         end

--         local hours = math.floor(time / 3600)
--         local minutes = math.floor((time % 3600) / 60)
--         hours = tonumber(hours)
--         minutes = tonumber(minutes)

--         local message = ""
--         if hours == 0 then
--             if minutes == 1 then
--                 message = minutes.. " minute"
--             else
--                 message = minutes.. " minutes"
--             end
--         else
--             if hours == 1 then
--                 message = hours.. " heure"
--             else
--                 message = hours.. " heures"
--             end

--             if minutes == 1 then
--                 message = message.. " et " ..minutes.. " minute"
--             elseif minutes ~= 0 then
--                 message = message.. " et " ..minutes.. " minutes"
--             end
--         end

--         if battery.state == states.charging then
--             message = message.. " avant charge complète"
--         elseif battery.state == states.discharging then
--             if (hours == 1 and minutes == 0) or (hours == 0 and minutes == 1) then
--                 message = message.. " restante"
--             else
--                 message = message.. " restantes"
--             end
--         end
--         return message
--     end
-- end
