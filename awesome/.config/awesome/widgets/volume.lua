local naughty = require("naughty")
local wibox = require("wibox")
local beautiful = require("beautiful")
local spawn = require("awful.spawn")

local icons = {
    "",
    ""
}
local status, percentage = "", ""
local cmds = {
    toggle = "~/.scripts/volume.sh -s toggle",
    inc = "~/.scripts/volume.sh -i 5",
    dec = "~/.scripts/volume.sh -d 5",
    get = "~/.scripts/volume.sh -g"
}

local function get_message()
    local bar = "[                    ]"

    local s = math.floor(percentage / 5)
    bar = bar:gsub(" ", "=", s)

    if status == "on" then
        return bar
    else
        return '<span foreground="' ..beautiful.white_alt.. '">' ..bar.. '</span>'
    end
end

local function get_title()
    if status == "on" then
        return "Volume: " ..percentage.. "%"
    else
        return "Volume coupé"
    end
end

local notification
local function show_message()
    notification = naughty.notify {
        text =  get_message(),
        title = get_title(),
        timeout = 0
    }
end

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

local function update()
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
        if notification then
            naughty.replace_text(notification, get_title(), get_message())
        end
    end)
end

-- update once so the widget displays information before being updated at least once
update()

local listener = spawn.with_line_callback({'stdbuf', '-oL', 'alsactl', 'monitor'}, {stdout = update})
awesome.connect_signal("exit", function()
    awesome.kill(listener, awesome.unix_signal.SIGTERM)
end)

local text_container = wibox.container.margin(text_widget, 0, beautiful.wibar_widgets_padding, 0, 0)

local volume_widget = wibox.widget {
    icon_widget,
    text_container,
    layout = wibox.layout.fixed.horizontal
}

local old_cursor, old_wibox
volume_widget:connect_signal("mouse::enter", function()
    local w = mouse.current_wibox
    old_cursor, old_wibox = w.cursor, w
    w.cursor = "hand1"

    show_message()
end)
volume_widget:connect_signal("mouse::leave", function()
    if old_wibox then
        old_wibox.cursor = old_cursor
        old_wibox = nil
    end

    naughty.destroy(notification)
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

return volume_widget
