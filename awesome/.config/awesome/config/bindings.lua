local gears = require("gears")
local awful = require("awful")
local spawn = require("awful.spawn")
local beautiful = require("beautiful")
local hotkeys_popup = require("awful.hotkeys_popup")
-- require("awful.hotkeys_popup.keys")
local variables = require("config.variables")
local clientmenu = require("popups.clientmenu")
local rootmenu = require("popups.rootmenu")
local applauncher = require("popups.applauncher")

local bindings = {}

-- {{{ Mouse bindings
awful.mouse.append_global_mousebindings({
    awful.button({ }, 3, rootmenu.launch),
    awful.button({ }, 4, awful.tag.viewprev),
    awful.button({ }, 5, awful.tag.viewnext),
})
-- }}}

-- {{{ Key bindings
awful.keyboard.append_global_keybindings({
    awful.key({ variables.modkey,           }, "s", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end,
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
            if _G.client.focus then _G.client.focus:raise() end
        end,
        {description = "focus left", group = "client"}
    ),
    awful.key({ variables.modkey,           }, "Right",
    function ()
        awful.client.focus.bydirection("right")
        if _G.client.focus then _G.client.focus:raise() end
    end,
    {description = "focus left", group = "client"}
    ),
    awful.key({ variables.modkey,           }, "Up",
    function ()
        awful.client.focus.bydirection("up")
        if _G.client.focus then _G.client.focus:raise() end
    end,
    {description = "focus left", group = "client"}
    ),
    awful.key({ variables.modkey,           }, "Down",
    function ()
        awful.client.focus.bydirection("down")
        if _G.client.focus then _G.client.focus:raise() end
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
    awful.key({ variables.modkey,           }, "Return", function() awful.spawn(variables.terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ variables.modkey,           }, "r", _G.awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ variables.modkey,           }, "g", function()
                                                        local tags = awful.screen.focused().tags
                                                        for _,v in pairs(tags) do
                                                            if v.gap == 0 then
                                                                v.gap = beautiful.useless_gap or 0
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
            spawn.with_shell("loginctl lock-session", function() end)
        end,
    {description = "raise lock screen", group = "launcher"}),
    awful.key({ "Control", "Mod1" }, "Delete", function()
        spawn.easy_async(variables.terminal.." -e htop", function() end)
    end,
    {description = "htop", group = "launcher"}),

    -- applauncher
    awful.key({ variables.modkey }, "space", function()
        applauncher.run(true, {
            height = _G.mouse.screen.geometry.height - beautiful.wibar_height + beautiful.border_width,
            width = 500, icon_spacing = 8, icon_size = 36, y = beautiful.wibar_height - beautiful.border_width
        })
    end,
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
    {description = "take a screenshot", group = "launcher"}),

    -- Tag selection
    awful.key {
        modifiers   = { variables.modkey },
        keygroup    = "numrow",
        description = "only view tag",
        group       = "tag",
        on_press    = function (index)
            local screen = awful.screen.focused()
            local tag = screen.tags[index]
            if tag then
                tag:view_only()
            end
        end,
    },
    awful.key {
        modifiers   = { variables.modkey, "Control" },
        keygroup    = "numrow",
        description = "toggle tag",
        group       = "tag",
        on_press    = function (index)
            local screen = awful.screen.focused()
            local tag = screen.tags[index]
            if tag then
                awful.tag.viewtoggle(tag)
            end
        end,
    },
    awful.key {
        modifiers = { variables.modkey, "Shift" },
        keygroup    = "numrow",
        description = "move focused client to tag",
        group       = "tag",
        on_press    = function (index)
            if client.focus then
                local tag = client.focus.screen.tags[index]
                if tag then
                    client.focus:move_to_tag(tag)
                end
            end
        end,
    },
    awful.key {
        modifiers   = { variables.modkey, "Control", "Shift" },
        keygroup    = "numrow",
        description = "toggle focused client on tag",
        group       = "tag",
        on_press    = function (index)
            if client.focus then
                local tag = client.focus.screen.tags[index]
                if tag then
                    client.focus:toggle_tag(tag)
                end
            end
        end,
    },

    -- Tag layout selection
    awful.key {
        modifiers   = {variables.modkey },
        keygroup    = "numpad",
        description = "select layout directly",
        group       = "layout",
        on_press    = function (index)
            local t = awful.screen.focused().selected_tag
            if t then
                t.layout = t.layouts[index] or t.layout
            end
        end,
    }
})

-- this is used in rules.lua
client.connect_signal("request::default_keybindings", function()
    awful.keyboard.append_client_keybindings({
        -- awful.key({ variables.modkey,           }, "f",
        --     function (c)
        --         c.fullscreen = not c.fullscreen
        --         c:raise()
        --     end,
        --     {description = "toggle fullscreen", group = "client"}),
        awful.key({ variables.modkey, "Control" }, "c", function(c) clientmenu.launch(c, true) end,
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
    })
end)

client.connect_signal("request::default_mousebindings", function()
    awful.mouse.append_client_mousebindings({
        awful.button({ }, 1, function (c)
            c:activate { context = "mouse_click" }
        end),
        awful.button({ variables.modkey }, 1, function (c)
            c:activate { context = "mouse_click", action = "mouse_move"  }
        end),
        awful.button({ variables.modkey }, 3, function (c)
            c:activate { context = "mouse_click", action = "mouse_resize"}
        end),
    })
end)

-- Set keys
_G.root.keys(globalkeys)
-- }}}

return bindings
