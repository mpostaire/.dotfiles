local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local popup_notification = require("util.popup_notification")

local icons = {
    "",
    "",
    "",
    "",
    ""
}
local name, status, percentage, time = "", "", "", ""
local cmd = "acpi -b"

local notification = popup_notification:new()
notification.popup.widget:get_children_by_id("icon")[1].font = "DejaVuSansMono Nerd Font 16"

local icon_widget = wibox.widget {
    {
        id = "icon",
        font = "DejaVuSansMono Nerd Font 10",
        widget = wibox.widget.textbox
    },
    widget = wibox.container.margin(_, beautiful.wibar_widgets_padding, beautiful.widgets_inner_padding, 0, 0)
}

local function get_icon()
    percentage = tonumber(percentage)

    local icon = icons[5]
    if percentage >= 0 and percentage < 20 then
        icon = icons[1]
    elseif percentage >= 20 and percentage < 40 then
        icon = icons[2]
    elseif percentage >= 40 and percentage < 60 then
        icon = icons[3]
    elseif percentage >= 60 and percentage < 80 then
        icon = icons[4]
    elseif percentage >= 80 and percentage <= 100 then
        icon = icons[5]
    end

    if status == "Charging" then
        icon = '<span foreground="' ..beautiful.yellow.. '">' ..icon.. '</span>'
    end

    return icon
end
local function get_title()
    if time == "" then
        return "<b>Batterie chargée</b>"
    else
        if status == "Charging" then
            return "<b>Batterie en charge</b>"
        elseif status == "Discharging" then
            return "<b>Batterie en décharge</b>"
        end
    end
end

local function get_message()
    if time == "" then
        return "Vous pouvez débrancher du secteur"
    else
        local hours, minutes = time:match('(%d+):(%d+)')
        hours = tonumber(hours)
        minutes = tonumber(minutes)

        local message = ""
        if hours == 0 then
            if minutes == 1 then
                message = minutes.. " minute"
            else
                message = minutes.. " minutes"
            end
        else
            if hours == 1 then
                message = hours.. " heure"
            else
                message = hours.. " heures"
            end

            if minutes == 1 then
                message = message.. " et " ..minutes.. " minute"
            elseif minutes ~= 0 then
                message = message.. " et " ..minutes.. " minutes"
            end
        end

        if status == "Charging" then
            message = message.. " avant charge complète"
        elseif status == "Discharging" then
            if (hours == 1 and minutes == 0) or (hours == 0 and minutes == 1) then
                message = message.. " restante"
            else
                message = message.. " restantes"
            end
        end
        return message
    end
end

local text_widget = awful.widget.watch(cmd, 5,
    function(widget, stdout)
        local s = stdout:match("[^\r\n]+")
        name, status, percentage, time = s:match('(.+): (%a+), (%d?%d?%d)%%,? ?([0-9:]*)')

        widget:set_text(tostring(percentage).. "%")

        local icon = get_icon()
        icon_widget:get_children_by_id('icon')[1].markup = icon

        notification:set_markup(get_title(), get_message())
        notification:set_icon(icon)
    end
)

local text_container = wibox.container.margin(text_widget, 0, beautiful.wibar_widgets_padding, 0, 0)

local battery_widget = wibox.widget {
    icon_widget,
    text_container,
    layout = wibox.layout.fixed.horizontal
}

battery_widget:connect_signal("mouse::enter", function() notification:show(true) end)
battery_widget:connect_signal("mouse::leave", function() notification:hide() end)

return battery_widget