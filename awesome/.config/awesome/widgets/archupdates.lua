local wibox = require("wibox")
local beautiful = require("beautiful")
local awful = require("awful")
local popup_notification = require("util.popup_notification")

local icon = ""
local updates, updates_aur = 0, 0
local cmd = awful.util.shell.. [[
            -c "var=$(checkupdates 2>/dev/null | wc -l)
                var=$var+$(yay -Qum 2> /dev/null | wc -l)
                echo $var"
]]

local archupdates_widget
local notification = popup_notification:new()
notification:set_icon(icon)

local function get_message()
    local content, suffix
    if updates == 1 or (updates == 0 and updates_aur == 1) then
        suffix = "mise à jour en attente"
    else
        suffix = "mises à jour en attente"
    end

    if updates == 0 and updates_aur == 0 then
        content = "Le système est à jour"
    elseif updates == 0 then
        content = "Il y a " ..updates_aur.. " " ..suffix.. " venant du AUR"
    elseif updates_aur == 0 then
        content = "Il y a " ..updates.. " " ..suffix
    else
        content = "Il y a " ..updates.. " " ..suffix.. " et " ..updates_aur.. " venant du AUR"
    end

    return content
end

local function get_title()
    return "<b>Mises à jour</b>"
end


local icon_widget = wibox.widget {
    {
        markup = icon,
        id = 'icon',
        font = "Material Icons 12", -- test nerd font
        widget = wibox.widget.textbox
    },
    widget = wibox.container.margin(_, beautiful.wibar_widgets_padding, beautiful.widgets_inner_padding, 0, 0)
}

local first_notification
local text_widget, text_widget_timer = awful.widget.watch(
    cmd, 1800, -- 30 minutes
    function(widget, stdout)
        local s = stdout:match("[^\r\n]+")
        updates, updates_aur = s:match('(%d+)+(%d+)')

        updates = tonumber(updates)
        updates_aur = tonumber(updates_aur)

        local text
        if updates == 0 and updates_aur == 0 then
            text = ""
        elseif updates == 0 then
            text = '<span foreground="' ..beautiful.blue.. '">'..updates_aur..'</span>'
        elseif updates_aur == 0 then
            text = updates
        else
            text = updates.. '<span foreground="' ..beautiful.blue.. '">+'..updates_aur..'</span>'
        end

        if updates + updates_aur > 0 and archupdates_widget then
            archupdates_widget.visible = true
        elseif archupdates_widget then
            archupdates_widget.visible = false
        end

        notification:set_markup(get_title(), get_message())
        widget:set_markup(text)

        -- spawn notification on widget initialization only
        if first_notification then
            notification:show()
            first_notification = false
        end
    end
)

local text_container = wibox.container.margin(text_widget, 0, beautiful.wibar_widgets_padding, 0, 0)

archupdates_widget = wibox.widget {
    icon_widget,
    text_container,
    visible = false,
    layout = wibox.layout.fixed.horizontal
}

local old_cursor, old_wibox
archupdates_widget:connect_signal("mouse::enter", function()
    notification:show(true)

    local w = mouse.current_wibox
    old_cursor, old_wibox = w.cursor, w
    w.cursor = "hand1"
end)
archupdates_widget:connect_signal("mouse::leave", function()
    notification:hide()

    if old_wibox then
        old_wibox.cursor = old_cursor
        old_wibox = nil
    end
end)

archupdates_widget:connect_signal("button::press", function(_, _, _, button)
    if button == 1 then
        notification:set_markup(get_title(), "Recherche en cours...")
        text_widget_timer:emit_signal("timeout")
    end
end)

return archupdates_widget
