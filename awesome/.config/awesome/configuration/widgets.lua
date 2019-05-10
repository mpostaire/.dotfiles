local awful = require("awful")
local beautiful = require("beautiful")
local menubar = require("menubar")
local wibox = require("wibox")
local gears = require("gears")
local hotkeys_popup = require("awful.hotkeys_popup")
require("awful.hotkeys_popup.keys")

local variables = require("configuration.variables")

local widgets = {}

-- function test(s)
-- 	if s.focus then --if switch is nil, function f() will not complete anything else below Return
-- 		return "FF0000"
--     else
--         return "00FF00"
--     end
-- end

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

-- -- Create the taglist widget
-- s.mytaglist = awful.widget.taglist {
--   filter  = awful.widget.taglist.filter.all,
--   buttons = widgets.taglist_buttons
-- }

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

-- -- Create the tasklist widget
-- mytasklist = awful.widget.tasklist {
--   filter  = awful.widget.tasklist.filter.currenttags,
--   buttons = widgets.tasklist_buttons
-- }

-- Place a widget for each screen
awful.screen.connect_for_each_screen(function(s)
    -- Create a taglist widget
    -- s.mytaglist = awful.widget.taglist {
    --     screen  = s,
    --     filter  = awful.widget.taglist.filter.all,
    --     buttons = widgets.taglist_buttons,
    --     widget_template = {
    --         id     = 'text_role',
    --         widget = wibox.widget.textbox
    --     }
    -- }


    s.mytaglist = awful.widget.taglist {
      screen  = s,
      filter  = awful.widget.taglist.filter.all,
      buttons = widgets.taglist_buttons,
      widget_template = {
            {
                {
                    {
                        id     = 'text_role',
                        widget = wibox.widget.textbox,
                    },
                    margins = 5,
                    widget  = wibox.container.margin,
                },
                bg     = "#000000",
                shape  = gears.shape.circle,
                widget = wibox.container.background,
            },
            left  = 8,
            right = 8,
            widget = wibox.container.margin
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