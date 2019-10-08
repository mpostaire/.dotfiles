local beautiful = require("beautiful")
local gears = require("gears")
local awful = require("awful")
local popup_notification = require("util.popup_notification")
local base_panel_widget = require("widgets.panel.base")
local battery = require("util.battery")

local icons = {
    "",
    "",
    "",
    "",
    ""
}

-- local notification = popup_notification:new()
-- notification.popup.widget:get_children_by_id("icon")[1].font = "DejaVuSansMono Nerd Font 16"

local battery_widget = base_panel_widget:new(_, _, {icon_font = "DejaVuSansMono Nerd Font 10"})
battery_widget:enable_mouse_hover_effects(true, true)

local function get_icon()
    local icon = icons[5]
    if battery.percentage >= 0 and battery.percentage < 20 then
        icon = icons[1]
    elseif battery.percentage >= 20 and battery.percentage < 40 then
        icon = icons[2]
    elseif battery.percentage >= 40 and battery.percentage < 60 then
        icon = icons[3]
    elseif battery.percentage >= 60 and battery.percentage < 80 then
        icon = icons[4]
    elseif battery.percentage >= 80 and battery.percentage <= 100 then
        icon = icons[5]
    end

    if battery.state == "charging" then
        battery_widget:set_icon_color(beautiful.yellow)
    elseif battery.state == "discharging" and battery.percentage <= 15 then
        battery_widget:set_icon_color(beautiful.red)
    else
        battery_widget:set_icon_color(beautiful.fg_normal)
    end

    return icon
end

local function get_text()
    return math.floor(battery.percentage).. "%"
end

local function update_widget()
    local icon = get_icon()
    battery_widget:update(icon, get_text())

    -- notification:set_markup(get_title(), get_message())
    -- notification:set_icon(icon)
end

-- we update once so the widget is not empty at creation
update_widget()

battery.on_properties_changed(function()
    update_widget()
end)

-- battery_widget:buttons(gears.table.join(
--     awful.button({}, 1, function() notification:toggle() end)
-- ))

return battery_widget

-- MOVE notification code elsewhere
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
