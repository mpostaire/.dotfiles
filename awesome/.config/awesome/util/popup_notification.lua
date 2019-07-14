-- a popup basic imitation of a naughty notification
-- TODO: hide when click outside (using mousegrabber as in client_menu or test mouse::enter in
--       a transparent wibox that cover the screen but just behind the popup)

local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")

local popup_notification = {}
popup_notification.__index = popup_notification

local function make_popup()
    local popup = awful.popup {
        widget = {
            {
                {

                    {
                        {
                            id = 'icon',
                            font = "Material Icons 22",
                            widget = wibox.widget.textbox,
                        },
                        right = beautiful.notification_margin,
                        widget = wibox.container.margin
                    },
                    {
                        {
                            id = 'title',
                            widget = wibox.widget.textbox
                        },
                        {
                            id = 'message',
                            widget = wibox.widget.textbox
                        },
                        layout = wibox.layout.fixed.vertical,
                    },
                    layout = wibox.layout.fixed.horizontal
                },
                margins = beautiful.notification_margin,
                widget  = wibox.container.margin
            },
            color = beautiful.border_normal,
            margins = beautiful.border_width,
            widget  = wibox.container.margin
        },
        preferred_anchors = 'middle',
        visible = false,
        ontop = true
    }

    popup.placement = function(d, args)
        awful.placement.top_right(d, args)
        popup.y = popup.y + beautiful.wibar_height + beautiful.notification_offset
        popup.x = popup.x - beautiful.notification_offset
    end

    return popup
end

function popup_notification:new()
    local pop_notif = {}
    setmetatable(pop_notif, popup_notification)
    pop_notif.popup = make_popup()
    pop_notif.timer = gears.timer {
        timeout   = 1,
        callback  = function()
            pop_notif.popup.visible = false
            pop_notif.timer:stop()
        end
    }
    return pop_notif
end

function popup_notification:set_markup(title, content)
    self.popup.widget:get_children_by_id("title")[1]:set_markup_silently(title)
    self.popup.widget:get_children_by_id("message")[1]:set_markup_silently(content)
end

-- for now this is a text icon
function popup_notification:set_icon(icon)
    self.popup.widget:get_children_by_id("icon")[1]:set_markup_silently(icon)
end

-- timeout is true if popup is to be dismissed automatically
function popup_notification:toggle(timeout)
    if self.popup.visible then
        self:hide()
    else
        self:show(timeout)
    end
end

-- timeout is true if popup is to be dismissed automatically
function popup_notification:show(timeout)
    if self.popup.visible then
        if timeout then
            self.timer:again()
        else
            self.timer:stop()
        end
    else
        self.popup.visible = true
        if timeout then
            self.timer:start()
        else
            self.timer:stop()
        end
    end
end

function popup_notification:hide()
    self.popup.visible = false
end

return popup_notification
