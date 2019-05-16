local wibox = require("wibox")
local beautiful = require("beautiful")
local awful = require("awful")
local naughty = require("naughty")

local icon = ""
local updates, updates_aur = 0, 0
local cmd = [[
    bash -c "var=$(checkupdates 2>/dev/null | wc -l)
             var=$var+$(yay -Qum 2> /dev/null | wc -l)
             echo $var"
]]

local archupdates_widget

local icon_widget = wibox.widget {
    {
        markup = icon,
        id = 'icon',
        font = "Material Icons 12", -- test nerd font
        widget = wibox.widget.textbox
    },
    widget = wibox.container.margin(_, beautiful.wibar_widgets_padding, beautiful.widgets_inner_padding, 0, 0)
}

local text_widget, text_widget_timer = awful.widget.watch(
    cmd, 1800,
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

        if updates + updates_aur > 0 then
            archupdates_widget.visible = true
        else
            archupdates_widget.visible = false
        end

        widget:set_markup(text)
    end
)

local text_container = wibox.container.margin(text_widget, 0, beautiful.wibar_widgets_padding, 0, 0)

archupdates_widget = wibox.widget {
    icon_widget,
    text_container,
    visible = false,
    layout = wibox.layout.fixed.horizontal
}

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

local notification
local function show_message()
    naughty.destroy(notification)

    local content = get_message()

    notification = naughty.notify {
        text =  content,
        title = "Mises à jour",
        timeout = 0
    }
end

-- {{{ Uses popup instead of naughty. Better if more complicated stuff is to be showed
--     cause it can contain any widget we want

-- local popup = awful.popup {
--     widget = {
--         {
--             {
--                 {
--                     markup   = '<b>Mises à jour</b>',
--                     widget = wibox.widget.textbox
--                 },
--                 {
--                     id = 'description',
--                     widget = wibox.widget.textbox
--                 },
--                 layout = wibox.layout.fixed.vertical,
--             },
--             margins = beautiful.notification_margin,
--             widget  = wibox.container.margin
--             },
--         color = beautiful.border_normal,
--         top = 0,
--         bottom = beautiful.border_width,
--         left = beautiful.border_width,
--         right = beautiful.border_width,
--         widget  = wibox.container.margin
--     },
--     preferred_anchors = 'middle',
--     visible = false,
--     ontop = true,
--     offset = {x=0, y=-2}
-- }

-- local function get_position() return mouse.current_widget_geometry end

-- use this and remove mouse::enter/mouse::leave signals if popup is to be showed with a click instead of a hover
-- popup:bind_to_widget(archupdates_widget)

-- archupdates_widget:connect_signal("mouse::enter",
--     function()
--         popup:move_next_to(get_position())
--         popup.widget:get_children_by_id("description")[1].text = get_message()
--         popup.visible = true
--     end
-- )
-- archupdates_widget:connect_signal("mouse::leave",
--     function()
--         popup.visible = false
--     end
-- )

-- }}}

archupdates_widget:connect_signal("mouse::enter",show_message)
archupdates_widget:connect_signal("mouse::leave", function() naughty.destroy(notification) end)

archupdates_widget:connect_signal("button::press",
    function()
        -- popup.widget:get_children_by_id("description")[1].text = get_message()
        text_widget_timer:emit_signal("timeout")
    end
)

return archupdates_widget
