local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")
local gears = require("gears")
local variables = require("configuration.variables")

-- tags buttons widget mouse handling
local taglist_buttons = gears.table.join(
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ variables.modkey }, 1, function(t)
        if client.focus then
            client.focus:move_to_tag(t)
        end
    end),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ variables.modkey }, 3, function(t)
        if client.focus then
            client.focus:toggle_tag(t)
        end
    end),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)


local function make_taglist_icons(widget, tag, index, tags)
    local outer_circle = widget:get_children_by_id('outer_circle')[1]
    local inner_circle = widget:get_children_by_id('inner_circle')[1]

    if tag.selected then -- if tag selected
        outer_circle.bg = beautiful.taglist_fg_focus
        inner_circle.bg = beautiful.taglist_fg_focus
    elseif #tag:clients() == 0 then -- if tag empty
        outer_circle.bg = beautiful.taglist_fg_empty
        inner_circle.bg = beautiful.taglist_bg_empty
    elseif tag.urgent then -- if tag urgent
        outer_circle.bg = beautiful.taglist_fg_urgent
        inner_circle.bg = beautiful.taglist_fg_urgent
    else -- if tag occupied
        outer_circle.bg = beautiful.taglist_fg_occupied
        inner_circle.bg = beautiful.taglist_fg_occupied
    end
end

-- Place a widget for each screen
awful.screen.connect_for_each_screen(function(s)
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = taglist_buttons,
        widget_template = {
            {
                {
                    {
                        {
                            margins = 4,
                            widget  = wibox.container.margin,
                        },
                        id     = 'inner_circle',
                        shape  = gears.shape.circle,
                        widget = wibox.container.background,
                    },
                    margins = 1,
                    widget  = wibox.container.margin,
                },
                id     = 'outer_circle',
                shape  = gears.shape.circle,
                widget = wibox.container.background,
            },
            left  = beautiful.wibar_widgets_padding,
            right = beautiful.wibar_widgets_padding,
            widget = wibox.container.margin,
            create_callback = function(self, tag, index, tags)
                local old_cursor, old_wibox
                self:connect_signal("mouse::enter", function()
                    local w = mouse.current_wibox
                    old_cursor, old_wibox = w.cursor, w
                    w.cursor = "hand1"
                end)

                self:connect_signal("mouse::leave", function()
                    if old_wibox then
                        old_wibox.cursor = old_cursor
                        old_wibox = nil
                    end
                end)

                make_taglist_icons(self, tag, index, tags)
            end,
            update_callback = make_taglist_icons,
        },
    }
end)
