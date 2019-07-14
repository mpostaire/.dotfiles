-- TODO replace brightness.sh by a lua script

local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local spawn = require("awful.spawn")
local gears = require("gears")
local popup_notification = require("util.popup_notification")

local icon = ""
local percentage = 0
local cmds = {
    inc = "~/.scripts/brightness.sh -i 5",
    dec = "~/.scripts/brightness.sh -d 5",
    get = "~/.scripts/brightness.sh -g",
    set25 = "~/.scripts/brightness.sh -s 25",
    set50 = "~/.scripts/brightness.sh -s 50",
    set75 = "~/.scripts/brightness.sh -s 75"
}

local mouse_hover = false

local notification = popup_notification:new()
notification:set_icon(icon)

local icon_widget = wibox.widget {
    {
        markup = icon,
        id = "icon",
        font = "Material Icons 12",
        widget = wibox.widget.textbox
    },
    widget = wibox.container.margin(_, beautiful.wibar_widgets_padding, beautiful.widgets_inner_padding, 0, 0)
}

local function get_message()
    local bar = "[                    ]"

    local s = math.floor(percentage / 5)

    bar = bar:gsub(" ", "=", s)
    return bar
end

local function get_text()
    if mouse_hover then
        return '<span foreground="'..beautiful.fg_normal_hover..'">'..tostring(percentage)..'%</span>'
    else
        return '<span foreground ="' ..beautiful.fg_normal.. '">' ..tostring(percentage).. '%</span>'
    end
end

local function get_title()
    return "<b>Luminosité: " ..percentage.. "%</b>"
end

local text_widget, text_widget_timer = awful.widget.watch(awful.util.shell.. ' -c "' ..cmds.get.. '"', 30,
    function(widget, stdout)
        local s = stdout:match("[^\r\n]+")
        percentage = s:match("(%d+)")
        widget:set_markup_silently(get_text())
        notification:set_markup(get_title(), get_message())
    end
)

local text_container = wibox.container.margin(text_widget, 0, beautiful.wibar_widgets_padding, 0, 0)

local brightness_widget = wibox.widget {
    icon_widget,
    text_container,
    layout = wibox.layout.fixed.horizontal
}

brightness_widget:buttons(gears.table.join(
    awful.button({}, 1, function() notification:toggle() end),
    awful.button({}, 4, function()
        spawn.easy_async_with_shell(cmds.inc, function()
            text_widget_timer:emit_signal("timeout")
            notification:show(true)
        end)
    end),
    awful.button({}, 5, function()
        spawn.easy_async_with_shell(cmds.dec, function()
            text_widget_timer:emit_signal("timeout")
            notification:show(true)
        end)
    end)
))

local old_cursor, old_wibox
brightness_widget:connect_signal("mouse::enter", function()
    -- mouse_hover color highlight
    mouse_hover = true
    icon_widget:get_children_by_id('icon')[1]:set_markup_silently('<span foreground="'..beautiful.fg_normal_hover..'">'..icon..'</span>')
    text_widget:set_markup_silently(get_text())

    local w = mouse.current_wibox
    old_cursor, old_wibox = w.cursor, w
    w.cursor = "hand1"
end)

brightness_widget:connect_signal("mouse::leave", function()
    -- no mouse_hover color highlight
    mouse_hover = false
    icon_widget:get_children_by_id('icon')[1]:set_markup_silently(icon)
    text_widget:set_markup_silently(get_text())

    if old_wibox then
        old_wibox.cursor = old_cursor
        old_wibox = nil
    end
end)

brightness_widget.keys = gears.table.join(
    awful.key({}, "XF86MonBrightnessUp", function()
        spawn.easy_async_with_shell(cmds.inc, function()
            text_widget_timer:emit_signal("timeout")
            notification:show(true)
        end)
    end,
    {description = "brightness up", group = "multimedia"}),
    awful.key({}, "XF86MonBrightnessDown", function()
        spawn.easy_async_with_shell(cmds.dec, function()
            text_widget_timer:emit_signal("timeout")
            notification:show(true)
        end)
    end,
    {description = "brightness down", group = "multimedia"})
)

return brightness_widget
