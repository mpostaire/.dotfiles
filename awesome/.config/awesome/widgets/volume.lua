local wibox = require("wibox")
local beautiful = require("beautiful")
local spawn = require("awful.spawn")
local awful = require("awful")
local gears = require("gears")
local popup_notification = require("util.popup_notification")

local icons = {
    "",
    ""
}
local status, percentage = "", 0
local cmds = {
    toggle = "amixer -q sset 'Master' toggle",
    inc = "amixer -q sset 'Master' 5%+ unmute",
    dec = "amixer -q sset 'Master' 5%- unmute",
    get = "amixer sget Master"
}
local mouse_hover = false

local notification = popup_notification:new()

local icon_widget = wibox.widget {
    {
        markup = icons[1],
        id = "icon",
        font = "Material Icons 12",
        widget = wibox.widget.textbox
    },
    widget = wibox.container.margin(_, beautiful.wibar_widgets_padding, beautiful.widgets_inner_padding, 0, 0)
}

local text_widget = wibox.widget {
    widget = wibox.widget.textbox
}

local text_container = wibox.container.margin(text_widget, 0, beautiful.wibar_widgets_padding, 0, 0)

local volume_widget = wibox.widget {
    icon_widget,
    text_container,
    layout = wibox.layout.fixed.horizontal
}

local function get_message()
    local bar = "[                    ]"

    local s = math.floor(percentage / 5)

    if status == "on" then
        bar = bar:gsub(" ", "=", s)
        return bar
    else
        bar = bar:gsub(" ", "+", s)
        return '<span foreground="' ..beautiful.white_alt.. '">' ..bar.. '</span>'
    end
end

local function get_title()
    if status == "on" then
        return "<b>Volume: " ..percentage.. "%</b>"
    else
        return "<b>Volume coupé</b>"
    end
end

local function get_icon(hover)
    if status == "on" then
        if mouse_hover and not hover then
            return '<span foreground="'..beautiful.fg_normal_hover..'">'..icons[1]..'</span>'
        else
            return icons[1]
        end
    else
        if mouse_hover then
            return '<span foreground="'..beautiful.white_alt_hover..'">'..icons[2]..'</span>'
        else
            return '<span foreground ="' ..beautiful.white_alt.. '">' ..icons[2].. '</span>'
        end
    end
end

local function get_text()
    if status == "on" then
        if mouse_hover then
            return '<span foreground="'..beautiful.fg_normal_hover..'">'..tostring(percentage)..'%</span>'
        else
            return tostring(percentage).."%"
        end
    else
        if mouse_hover then
            return '<span foreground="'..beautiful.white_alt_hover..'">'..tostring(percentage)..'%</span>'
        else
            return '<span foreground ="' ..beautiful.white_alt.. '">' ..tostring(percentage).. '%</span>'
        end
    end
end

local function update(listener_stdout, show_notification)
    spawn.easy_async(cmds.get, function(stdout)
        local s = stdout:match("%d+%%[^\r\n]+")
        percentage = s:match("(%d+)%%")
        status = s:match("%[(%a+)%]$")

        icon_widget:get_children_by_id('icon')[1]:set_markup_silently(get_icon())
        text_widget:set_markup_silently(get_text())

        notification:set_markup(get_title(), get_message())
        notification:set_icon(get_icon(false))
        if show_notification == nil or show_notification then
            notification:show(true)
        end
    end)
end

-- update once so the widget displays information before being updated at least once
update("", false)

-- after suspend alsactl monitor is killed so we restart the listener at exit
local function start_listener()
    local listener = spawn.with_line_callback({'stdbuf', '-oL', 'alsactl', 'monitor'}, {
        stdout = update,
        exit = start_listener
    })
    awesome.connect_signal("exit", function()
        awesome.kill(listener, awesome.unix_signal.SIGTERM)
    end)
end
start_listener()

volume_widget:buttons(gears.table.join(
    awful.button({}, 1, function() notification:toggle() end),
    awful.button({}, 2, function() spawn.easy_async(cmds.toggle, function() end) end),
    awful.button({}, 4, function() spawn.easy_async(cmds.inc, function() end) end),
    awful.button({}, 5, function() spawn.easy_async(cmds.dec, function() end) end)
))

local old_cursor, old_wibox
volume_widget:connect_signal("mouse::enter", function()
    -- mouse_hover color highlight
    mouse_hover = true
    icon_widget:get_children_by_id('icon')[1]:set_markup_silently(get_icon())
    text_widget:set_markup_silently(get_text())

    local w = mouse.current_wibox
    old_cursor, old_wibox = w.cursor, w
    w.cursor = "hand1"
end)

volume_widget:connect_signal("mouse::leave", function()
    -- no mouse_hover color highlight
    mouse_hover = false
    icon_widget:get_children_by_id('icon')[1]:set_markup_silently(get_icon())
    text_widget:set_markup_silently(get_text())

    if old_wibox then
        old_wibox.cursor = old_cursor
        old_wibox = nil
    end
end)

local widget_keys = gears.table.join(
    awful.key({}, "XF86AudioRaiseVolume", function()
        spawn.easy_async(cmds.inc, function() end)
    end,
    {description = "volume up", group = "multimedia"}),
    awful.key({}, "XF86AudioMute", function()
        spawn.easy_async(cmds.toggle, function() end)
    end,
    {description = "toggle mute volume", group = "multimedia"}),
    awful.key({}, "XF86AudioLowerVolume", function()
        spawn.easy_async(cmds.dec, function() end)
    end,
    {description = "volume down", group = "multimedia"})
)

root.keys(gears.table.join(root.keys(), widget_keys))

return volume_widget
