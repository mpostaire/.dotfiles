local wibox = require("wibox")
local beautiful = require("beautiful")
local popup_notification = require("util.popup_notification")

local p = require("dbus_proxy")

local icons = {
    "",
    "",
    "",
    "",
    ""
}

local notification = popup_notification:new()
notification.popup.widget:get_children_by_id("icon")[1].font = "DejaVuSansMono Nerd Font 16"

-- TODO: handle cases where battery state is not 1, 2 or 4
local states = {
    unknown = 0,
    charging = 1,
    discharging = 2,
    empty = 3,
    full = 4,
    pending_charge = 5,
    pending_discharge = 6
}

local icon_widget = wibox.widget {
    {
        id = "icon",
        font = "DejaVuSansMono Nerd Font 10",
        widget = wibox.widget.textbox
    },
    widget = wibox.container.margin(_, beautiful.wibar_widgets_padding, beautiful.widgets_inner_padding, 0, 0)
}

local text_widget = wibox.widget {
    {
        id = "text",
        widget = wibox.widget.textbox
    },
    widget = wibox.container.margin(_, 0, beautiful.wibar_widgets_padding, 0, 0)
}

local battery_widget = wibox.widget {
    icon_widget,
    text_widget,
    layout = wibox.layout.fixed.horizontal
}

-- For now get only the first battery device
local function get_first_battery_path()
    local proxy = p.Proxy:new(
        {
            bus = p.Bus.SYSTEM,
            name = "org.freedesktop.UPower",
            interface = "org.freedesktop.UPower",
            path = "/org/freedesktop/UPower"
        }
    )

    local devices = proxy:EnumerateDevices()
    for _, v in ipairs(devices) do
        if v:match(".+battery") then
            return v
        end
    end
end

local battery_path = get_first_battery_path()

if not battery_path then
    battery_widget.visible = false
    return battery_widget
end

local proxy = p.Proxy:new(
    {
        bus = p.Bus.SYSTEM,
        name = "org.freedesktop.UPower",
        interface = "org.freedesktop.UPower.Device",
        path = battery_path
    }
)

local function get_icon()
    local icon = icons[5]
    if proxy.Percentage >= 0 and proxy.Percentage < 20 then
        icon = icons[1]
    elseif proxy.Percentage >= 20 and proxy.Percentage < 40 then
        icon = icons[2]
    elseif proxy.Percentage >= 40 and proxy.Percentage < 60 then
        icon = icons[3]
    elseif proxy.Percentage >= 60 and proxy.Percentage < 80 then
        icon = icons[4]
    elseif proxy.Percentage >= 80 and proxy.Percentage <= 100 then
        icon = icons[5]
    end

    if proxy.State == states.charging then
        icon = '<span foreground="' ..beautiful.yellow.. '">' ..icon.. '</span>'
    elseif proxy.State == states.discharging and proxy.Percentage <= 15 then
        icon = '<span foreground="' ..beautiful.red.. '">' ..icon.. '</span>'
    end

    return icon
end

local function get_title()
    if proxy.State == states.full then
        return "<b>Batterie chargée</b>"
    else
        if proxy.State == states.charging then
            return "<b>Batterie en charge</b>"
        elseif proxy.State == states.discharging then
            return "<b>Batterie en décharge</b>"
        end
    end
end

local function get_message()
    if proxy.State == states.full then
        return "Vous pouvez débrancher du secteur"
    else
        local time
        if proxy.State == states.charging then
            time = proxy.TimeToFull
        elseif proxy.State == states.discharging then
            time = proxy.TimeToEmpty
        end

        local hours = math.floor(time / 3600)
        local minutes = math.floor((time % 3600) / 60)
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

        if proxy.State == states.charging then
            message = message.. " avant charge complète"
        elseif proxy.State == states.discharging then
            if (hours == 1 and minutes == 0) or (hours == 0 and minutes == 1) then
                message = message.. " restante"
            else
                message = message.. " restantes"
            end
        end
        return message
    end
end

local function update_widget()
    local icon = get_icon()
    icon_widget:get_children_by_id('icon')[1]:set_markup_silently(icon)
    text_widget:get_children_by_id('text')[1]:set_markup_silently(math.floor(proxy.Percentage).. "%")

    notification:set_markup(get_title(), get_message())
    notification:set_icon(icon)
end

-- we update once so the widget is not empty at creation
update_widget()

battery_widget:connect_signal("mouse::enter", function() notification:show(true) end)
battery_widget:connect_signal("mouse::leave", function() notification:hide() end)

proxy:on_properties_changed(function (p, changed, invalidated)
    assert(p == proxy)
    for k, v in pairs(changed) do
        if k == "Percentage" or "State" or "TimeToFull" or "TimeToEmpty" then
            update_widget()
        end
    end
end)

return battery_widget
