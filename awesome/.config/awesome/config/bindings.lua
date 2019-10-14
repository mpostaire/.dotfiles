local gears = require("gears")
local awful = require("awful")
local spawn = require("awful.spawn")
local beautiful = require("beautiful")
local hotkeys_popup = require("awful.hotkeys_popup")
require("awful.hotkeys_popup.keys")
local variables = require("config.variables")
local rofi = require("util.rofi")
local client_menu = require("popups.client_menu")
local capi = {root = root, client = client, awesome = awesome, }

local bindings = {}

-- {{{ Mouse bindings
capi.root.buttons(gears.table.join(
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
local globalkeys = gears.table.join(
    awful.key({ variables.modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ variables.modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),
    awful.key({ variables.modkey, "Control" }, "Left", awful.tag.viewprev,
              {description = "view next", group = "tag"}),
    awful.key({ variables.modkey, "Control" }, "Right", awful.tag.viewnext,
              {description = "view prev", group = "tag"}),
    awful.key({ variables.modkey, "Control" }, "Down", awful.tag.viewprev,
              {description = "view next", group = "tag"}),
    awful.key({ variables.modkey, "Control" }, "Up", awful.tag.viewnext,
              {description = "view prev", group = "tag"}),

    awful.key({ variables.modkey,           }, "Left",
        function ()
            awful.client.focus.bydirection("left")
            if capi.client.focus then capi.client.focus:raise() end
        end,
        {description = "focus left", group = "client"}
    ),
    awful.key({ variables.modkey,           }, "Right",
    function ()
        awful.client.focus.bydirection("right")
        if capi.client.focus then capi.client.focus:raise() end
    end,
    {description = "focus left", group = "client"}
    ),
    awful.key({ variables.modkey,           }, "Up",
    function ()
        awful.client.focus.bydirection("up")
        if capi.client.focus then capi.client.focus:raise() end
    end,
    {description = "focus left", group = "client"}
    ),
    awful.key({ variables.modkey,           }, "Down",
    function ()
        awful.client.focus.bydirection("down")
        if capi.client.focus then capi.client.focus:raise() end
    end,
    {description = "focus left", group = "client"}
    ),

    -- Layout manipulation
    awful.key({ variables.modkey, "Shift"   }, "Left", function () awful.client.swap.bydirection("left")    end,
              {description = "swap with left client", group = "client"}),
    awful.key({ variables.modkey, "Shift"   }, "Right", function () awful.client.swap.bydirection("right")    end,
              {description = "swap with right client", group = "client"}),
    awful.key({ variables.modkey, "Shift"   }, "Up", function () awful.client.swap.bydirection("up")    end,
              {description = "swap with up client", group = "client"}),
    awful.key({ variables.modkey, "Shift"   }, "Down", function () awful.client.swap.bydirection("down")    end,
              {description = "swap with down client", group = "client"}),
    awful.key({ variables.modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ variables.modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ variables.modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    -- awful.key({ variables.modkey,           }, "Tab",
    --     function ()
    --         awful.client.focus.history.previous()
    --         if client.focus then
    --             client.focus:raise()
    --         end
    --     end,
    --     {description = "go back", group = "client"}),

    -- Standard program
    awful.key({ variables.modkey,           }, "Return", function () awful.spawn(variables.terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ variables.modkey,           }, "r", capi.awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ variables.modkey,           }, "g", function()
                                                        local tags = awful.screen.focused().tags
                                                        for _,v in pairs(tags) do
                                                            if v.gap == 0 then
                                                                v.gap = beautiful.useless_gap
                                                            else
                                                                v.gap = 0
                                                            end
                                                        end
                                                    end,
              {description = "toggle useless gaps", group = "awesome"}),

    -- awful.key({ variables.modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
    --           {description = "increase master width factor", group = "layout"}),
    -- awful.key({ variables.modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
    --           {description = "decrease master width factor", group = "layout"}),
    -- awful.key({ variables.modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
    --           {description = "increase the number of master clients", group = "layout"}),
    -- awful.key({ variables.modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
    --           {description = "decrease the number of master clients", group = "layout"}),
    -- awful.key({ variables.modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
    --           {description = "increase the number of columns", group = "layout"}),
    -- awful.key({ variables.modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
    --           {description = "decrease the number of columns", group = "layout"}),
    awful.key({ variables.modkey }, "Tab", function () awful.layout.inc(1) end,
              {description = "select next", group = "layout"}),
    awful.key({ variables.modkey, 'Shift' }, "Tab", function () awful.layout.inc(-1) end,
              {description = "select previous", group = "layout"}),

    awful.key({ variables.modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                    c:emit_signal(
                        "request::activate", "key.unminimize", {raise = true}
                    )
                  end
              end,
              {description = "restore minimized", group = "client"}),

    -- lock screen
    awful.key({ variables.modkey }, "l",
        function()
            spawn.with_shell("~/.scripts/lock.sh", function() end)
        end,
    {description = "raise lock screen", group = "launcher"}),
    awful.key({ "Control", "Mod1" }, "Delete", function()
        spawn.easy_async(variables.terminal.." -e htop", function() end)
    end,
    {description = "htop", group = "launcher"}),

    -- rofi power menu
    awful.key({ variables.modkey }, "p", rofi.power_menu,
                {description = "show the power menu", group = "launcher"}),
    -- rofi launcher menu
    awful.key({ variables.modkey }, "space", function() rofi.launcher_menu("drun") end,
                {description = "show the launcher menu", group = "launcher"}),

    -- laptop special keys
    awful.key({}, "XF86Calculator",
        function()
            spawn.easy_async("gnome-calculator", function() end)
        end,
    {description = "launch calculator", group = "launcher"}),
    awful.key({}, "XF86HomePage",
    function()
        spawn.easy_async("firefox", function() end)
    end,
    {description = "launch web browser", group = "launcher"}),

    awful.key({ "Shift" }, "Print",
    function()
        spawn.easy_async("xfce4-screenshooter -r", function() end)
    end,
    {description = "take a screenshot of a region", group = "launcher"}),
    awful.key({ "Control" }, "Print",
    function()
        spawn.easy_async("xfce4-screenshooter -w", function() end)
    end,
    {description = "take a screenshot of a window", group = "launcher"}),
    awful.key({}, "Print",
    function()
        spawn.easy_async("xfce4-screenshooter -f", function() end)
    end,
    {description = "take a screenshot", group = "launcher"})
)

-- this is used in rules.lua
bindings.clientkeys = gears.table.join(
    -- awful.key({ variables.modkey,           }, "f",
    --     function (c)
    --         c.fullscreen = not c.fullscreen
    --         c:raise()
    --     end,
    --     {description = "toggle fullscreen", group = "client"}),
    awful.key({ variables.modkey, "Control" }, "c", function(c) client_menu.show(c, true) end,
              {description = "open control menu", group = "client"}),
    awful.key({ variables.modkey }, "q",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ variables.modkey, "Shift"   }, "q", function(c)
                    if c.pid then
                        spawn.easy_async("kill -9 "..c.pid, function() end)
                    end
                end,
              {description = "kill", group = "client"}),
    awful.key({ variables.modkey }, "f",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ variables.modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ variables.modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ variables.modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"})
    -- awful.key({ variables.modkey,           }, "n",
    --     function (c)
    --         -- The client currently has the input focus, so it cannot be
    --         -- minimized, since minimized clients can't have the focus.
    --         c.minimized = true
    --     end ,
    --     {description = "minimize", group = "client"}),
    -- awful.key({ variables.modkey,           }, "m",
    --     function (c)
    --         c.maximized = not c.maximized
    --         c:raise()
    --     end ,
    --     {description = "(un)maximize", group = "client"})
    -- awful.key({ variables.modkey, "Control" }, "m",
    --     function (c)
    --         c.maximized_vertical = not c.maximized_vertical
    --         c:raise()
    --     end ,
    --     {description = "(un)maximize vertically", group = "client"}),
    -- awful.key({ variables.modkey, "Shift"   }, "m",
    --     function (c)
    --         c.maximized_horizontal = not c.maximized_horizontal
    --         c:raise()
    --     end ,
    --     {description = "(un)maximize horizontally", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ variables.modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ variables.modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ variables.modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if capi.client.focus then
                          local tag = capi.client.focus.screen.tags[i]
                          if tag then
                            capi.client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ variables.modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if capi.client.focus then
                          local tag = capi.client.focus.screen.tags[i]
                          if tag then
                            capi.client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

-- this is used in rules.lua
bindings.clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ variables.modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ variables.modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
capi.root.keys(globalkeys)
-- }}}

return bindings
