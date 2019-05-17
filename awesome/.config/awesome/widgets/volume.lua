-- sometimes (after supsend) this widget need awesome to restart to update.
-- TODO replace volume.sh by a lua script

local wibox = require("wibox")
local beautiful = require("beautiful")
local spawn = require("awful.spawn")
local popup_notification = require("util.popup_notification")

local icons = {
    "",
    ""
}
local status, percentage = "", 0
local cmds = {
    toggle = "~/.scripts/volume.sh -s toggle",
    inc = "~/.scripts/volume.sh -i 5",
    dec = "~/.scripts/volume.sh -d 5",
    get = "~/.scripts/volume.sh -g"
}

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

local function get_icon()
    if status == "on" then
        return icons[1]
    else
        return '<span foreground ="' ..beautiful.white_alt.. '">' ..icons[2].. '</span>'
    end
end

local function update(show_notification)
    spawn.easy_async_with_shell(cmds.get, function(stdout)
        local s = stdout:match("[^\r\n]+")
        percentage, status = s:match("(%d+)%%(%w+)")
        if status == "on" then
            icon_widget:get_children_by_id('icon')[1]:set_markup_silently(icons[1])
            text_widget:set_markup_silently(percentage.. "%")
        else
            icon_widget:get_children_by_id('icon')[1]:set_markup_silently('<span foreground ="' ..beautiful.white_alt.. '">' ..icons[2].. '</span>')
            text_widget:set_markup_silently('<span foreground="' ..beautiful.white_alt.. '">' ..percentage.. '%</span>')
        end
        notification:set_markup(get_title(), get_message())
        notification:set_icon(get_icon())
        if show_notification == nil or show_notification then
            notification:show()
        end
    end)
end

-- update once so the widget displays information before being updated at least once
update(false)

-- if we use signals there is no need of a listener
-- we keep it for the example, to see implementation with signals, see brightness widget
local listener = spawn.with_line_callback({'stdbuf', '-oL', 'alsactl', 'monitor'}, {stdout = update})
awesome.connect_signal("exit", function()
    awesome.kill(listener, awesome.unix_signal.SIGTERM)
end)

volume_widget:connect_signal("button::press", function(_, _, _, button)
    if button == 4 then
        spawn.easy_async_with_shell(cmds.inc, function() end)
    elseif button == 5 then
        spawn.easy_async_with_shell(cmds.dec, function() end)
    elseif button == 1 then
        spawn.easy_async_with_shell(cmds.toggle, function() end)
    end
end)

local old_cursor, old_wibox
volume_widget:connect_signal("mouse::enter", function()
    notification:show(true)

    local w = mouse.current_wibox
    old_cursor, old_wibox = w.cursor, w
    w.cursor = "hand1"
end)

volume_widget:connect_signal("mouse::leave", function()
    notification:hide()

    if old_wibox then
        old_wibox.cursor = old_cursor
        old_wibox = nil
    end
end)

return volume_widget
