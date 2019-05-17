-- a popup basic imitation of a naughty notification

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

-- no_timeout: timer is stopped and popup will not hide automatically
function popup_notification:new()
    local pop_notif = {}
    setmetatable(pop_notif, popup_notification)
    -- self._index = self
    pop_notif.popup = make_popup()
    pop_notif.timer = gears.timer {
        timeout   = 2,
        callback  = function()
            pop_notif.popup.visible = false
            pop_notif.timer:stop()
        end
    }
    pop_notif.no_timeout = false
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

-- if no arg, no_timeout stays the same as it was before
function popup_notification:show(no_timeout)
    if no_timeout == nil then
        -- self.no_timeout stays the same
    elseif not no_timeout then
        self.no_timeout = false
    else
        self.no_timeout = true
    end

    if not self.popup.visible then
        self.popup.visible = true
        if  self.no_timeout then
             self.timer:stop()
        else
            self.timer:start()
        end
    else
        if  self.no_timeout then
            self.timer:stop()
        else
            self.timer:again()
        end
    end
end

function popup_notification:hide()
    if self.popup.visible then
        self.popup.visible = false
    end
    self.no_timeout = false
end

return popup_notification
