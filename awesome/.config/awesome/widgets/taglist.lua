local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")
local gears = require("gears")
local variables = require("config.variables")
local color = require("themes.color")

-- tags buttons widget mouse handling
local taglist_buttons = gears.table.join(
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ variables.modkey }, 1, function(t)
        if _G.client.focus then
            _G.client.focus:move_to_tag(t)
        end
    end),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ variables.modkey }, 3, function(t)
        if _G.client.focus then
            _G.client.focus:toggle_tag(t)
        end
    end),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

local icon_colors = {
    mouse_hovering = {
        selected = {
            outer_circle = color.lighten_by(beautiful.taglist_fg_focus, 0.25),
            inner_circle = color.lighten_by(beautiful.taglist_fg_focus, 0.25)
        },
        empty = {
            outer_circle = color.lighten_by(beautiful.taglist_fg_empty, 0.5),
            inner_circle = beautiful.taglist_bg_empty
        },
        urgent = {
            outer_circle = color.lighten_by(beautiful.taglist_fg_urgent, 0.5),
            inner_circle = color.lighten_by(beautiful.taglist_fg_urgent, 0.5)
        },
        occupied = {
            outer_circle = color.lighten_by(beautiful.taglist_fg_occupied, 0.5),
            inner_circle = color.lighten_by(beautiful.taglist_fg_occupied, 0.5)
        }
    },
    normal = {
        selected = {
            outer_circle = beautiful.taglist_fg_focus,
            inner_circle = beautiful.taglist_fg_focus
        },
        empty = {
            outer_circle = beautiful.taglist_fg_empty,
            inner_circle = beautiful.taglist_bg_empty
        },
        urgent = {
            outer_circle = beautiful.taglist_fg_urgent,
            inner_circle = beautiful.taglist_fg_urgent
        },
        occupied = {
            outer_circle = beautiful.taglist_fg_occupied,
            inner_circle = beautiful.taglist_fg_occupied
        }
    }
}

local function make_taglist_icons(widget, tag, index, tags)
    local outer_circle = widget:get_children_by_id('outer_circle')[1]
    local inner_circle = widget:get_children_by_id('inner_circle')[1]

    local key = widget.mouse_hovering and "mouse_hovering" or "normal"

    if tag.selected then -- if tag selected
        outer_circle.bg = icon_colors[key].selected.outer_circle
        inner_circle.bg = icon_colors[key].selected.inner_circle
    elseif #tag:clients() == 0 then -- if tag empty
        outer_circle.bg = icon_colors[key].empty.outer_circle
        inner_circle.bg = icon_colors[key].empty.inner_circle
    elseif tag.urgent then -- if tag urgent
        outer_circle.bg = icon_colors[key].urgent.outer_circle
        inner_circle.bg = icon_colors[key].urgent.inner_circle
    else -- if tag occupied
        outer_circle.bg = icon_colors[key].occupied.outer_circle
        inner_circle.bg = icon_colors[key].occupied.inner_circle
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
            left  = 8,
            right = 8,
            widget = wibox.container.margin,
            create_callback = function(self, tag, index, tags)
                local old_cursor, old_wibox
                self.mouse_hovering = false
                self:connect_signal("mouse::enter", function()
                    local w = _G.mouse.current_wibox
                    old_cursor, old_wibox = w.cursor, w
                    w.cursor = "hand2"
                    self.mouse_hovering = true
                    make_taglist_icons(self, tag, index, tags)
                end)

                self:connect_signal("mouse::leave", function()
                    if old_wibox then
                        old_wibox.cursor = old_cursor
                        old_wibox = nil
                    end
                    self.mouse_hovering = false
                    make_taglist_icons(self, tag, index, tags)
                end)

                make_taglist_icons(self, tag, index, tags)
            end,
            update_callback = make_taglist_icons,
        },
    }
end)
