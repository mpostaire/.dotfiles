local awful = require("awful")
local beautiful = require("beautiful")
local menubar = require("menubar")
local wibox = require("wibox")
local gears = require("gears")
local hotkeys_popup = require("awful.hotkeys_popup")
require("awful.hotkeys_popup.keys")

local variables = require("configuration.variables")

local widgets = {}

-- {{{ Menu
-- Create a launcher widget and a main menu
widgets.myawesomemenu = {
    { "hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
    { "manual", variables.terminal .. " -e man awesome" },
    { "edit config", variables.editor_cmd .. " " .. awesome.conffile },
    { "restart", awesome.restart },
    { "quit", function() awesome.quit() end },
 }
 
widgets.mymainmenu = awful.menu({ items = { { "awesome", widgets.myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", variables.terminal }
                                  }
                        })

widgets.mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                    menu = widgets.mymainmenu })

-- Menubar configuration
menubar.utils.terminal = variables.terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
widgets.mykeyboardlayout = awful.widget.keyboardlayout()

-- Create a textclock widget
widgets.mytextclock = wibox.widget.textclock()

-- tags buttons widget mouse handling
widgets.taglist_buttons = gears.table.join(
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

-- launched programs widget mouse handling
widgets.tasklist_buttons = gears.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  c:emit_signal(
                                                      "request::activate",
                                                      "tasklist",
                                                      {raise = true}
                                                  )
                                              end
                                          end),
                     awful.button({ }, 3, function()
                                              awful.menu.client_list({ theme = { width = 250 } })
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

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
        buttons = widgets.taglist_buttons,
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
                create_callback = function(self, tag, index, tags) --luacheck: no unused args
                    make_taglist_icons(self, tag, index, tags)
                end,
                update_callback = function(self, tag, index, tags) --luacheck: no unused args
                    make_taglist_icons(self, tag, index, tags)
                end,
            },
    }

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
      screen  = s,
      filter  = awful.widget.tasklist.filter.currenttags,
      buttons = widgets.tasklist_buttons
    }

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
end)

return widgets