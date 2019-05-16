local awful = require("awful")
local naughty = require("naughty")
local wibox = require("wibox")
local beautiful = require("beautiful")

local icons = {
    "",
    "",
    "",
    "",
    ""
}
local name, status, percentage, time = "", "", "", ""
local cmd = "acpi -b"

local icon_widget = wibox.widget {
    {
        id = "icon",
        font = "DejaVuSansMono Nerd Font 10",
        widget = wibox.widget.textbox
    },
    widget = wibox.container.margin(_, beautiful.wibar_widgets_padding, beautiful.widgets_inner_padding, 0, 0)
}

local text_widget = awful.widget.watch(cmd, 30,
    function(widget, stdout)
        local s = stdout:match("[^\r\n]+")
        name, status, percentage, time = s:match('(.+): (%a+), (%d?%d?%d)%%,? ?([0-9:]*)')

        widget:set_text(tostring(percentage).. "%")

        local icon
        percentage = tonumber(percentage)
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
            icon_widget:get_children_by_id('icon')[1].markup = '<span foreground="' ..beautiful.yellow.. '">' ..icon.. '</span>'
        else
            icon_widget:get_children_by_id('icon')[1].markup = icon
        end
    end
)

local text_container = wibox.container.margin(text_widget, 0, beautiful.wibar_widgets_padding, 0, 0)

local battery_widget = wibox.widget {
    icon_widget,
    text_container,
    layout = wibox.layout.fixed.horizontal
}

local notification
local function show_message()
    awful.spawn.easy_async_with_shell(cmd,
        function(stdout)
            naughty.destroy(notification)

            local s = stdout:match("[^\r\n]+")
            local name, status, percentage, time = s:match('(.+): (%a+), (%d?%d?%d)%%,? ?([0-9:]*)')

            if time == "" then
                status = "Batterie chargée"
                time = "Vous pouvez débrancher du secteur"
            else
                local hours, minutes = time:match('(%d+):(%d+)')
                hours = tonumber(hours)
                minutes = tonumber(minutes)
                if hours == 0 then
                    if minutes == 1 then
                        time = minutes.. " minute"
                    else
                        time = minutes.. " minutes"
                    end
                else
                    if hours == 1 then
                        time = hours.. " heure"
                    else
                        time = hours.. " heures"
                    end

                    if minutes == 1 then
                        time = time.. " et " ..minutes.. " minute"
                    elseif minutes ~= 0 then
                        time = time.. " et " ..minutes.. " minutes"
                    end
                end

                if status == "Charging" then
                    status = "Batterie en charge"
                    time = time.. " avant charge complète"
                elseif status == "Discharging" then
                    status = "Batterie en décharge"
                    if (hours == 1 and minutes == 0) or (hours == 0 and minutes == 1) then
                        time = time.. " restante"
                    else
                        time = time.. " restantes"
                    end
                end
            end

            notification = naughty.notify {
                text =  time,
                title = status,
                timeout = 0
            }
        end
    )
end

battery_widget:connect_signal("mouse::enter", show_message)
battery_widget:connect_signal("mouse::leave", function() naughty.destroy(notification) end)

return battery_widget