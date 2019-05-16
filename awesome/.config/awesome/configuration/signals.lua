local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup
        and not c.size_hints.user_position
        and not c.size_hints.program_position then
            -- Prevent clients from being unreachable after screen count changes.
            awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}


-- {{{ No borders if tiled and is only one client, titlebar only in floating layout, clientdo not remember if was
--   maximized in floating layout when switching layout, no maximized state if tiled layout
-- /!\ A client in a tag's floating layout is not floating. Floating is a special mode that ignores the tag's layout.
--     In following comments floating and tiled client really mean its layout not the special mode.
-- Big ugly piece of code but I think I got every corner case covered. It could be simpler but more performance consuming.

local function handle_tiled(client)
    -- this if statement is new, if bugs related to maximized state, check there first
    -- if client.maximized then
    --     client.was_maximized = true
    -- end
    client.maximized = false
    awful.titlebar.hide(client)
    if #awful.screen.focused().tiled_clients == 1 and not beautiful.gap_single_client then
        client.border_width = beautiful.border_width_single_client
    else
        client.border_width = beautiful.border_width
    end
end

local function handle_floating(client)
    if client.maximized and awful.layout.getname() ~= "floating" then
        handle_tiled(client)
    else
        -- this if statement is new, if bugs related to maximized state, check there first
        -- if client.was_maximized then
        --     client.maximized = true
        --     client.was_maximized = false
        -- end
        awful.titlebar.show(client)
        client.border_width = beautiful.border_width
    end
end

local function handle_everything()
    local shown_clients = awful.screen.focused().clients

    for _,v in ipairs(shown_clients) do
        if v.floating or awful.layout.getname() == "floating" then
            handle_floating(v, #shown_clients)
        else
            handle_tiled(v, #shown_clients)
        end
    end
end

tag.connect_signal("property::layout", handle_everything)

tag.connect_signal("property::selected", handle_everything)

client.connect_signal("manage", function(c)
    -- c.was_maximized = false
    local shown_tiled_clients = awful.screen.focused().tiled_clients

    if c.floating or awful.layout.getname() == "floating" then
        -- show titlebar
        awful.titlebar.show(c)
        -- show borders
        c.border_width = beautiful.border_width -- maybe not needed
    else
        -- hide titlebar
        awful.titlebar.hide(c)
        -- show borders of tiled clients only if multiple clients
        if #shown_tiled_clients == 1 then
            c.border_width = beautiful.border_width_single_client
        elseif #shown_tiled_clients == 2 then -- the other client needs its borders
            shown_tiled_clients[1].border_width = beautiful.border_width
            shown_tiled_clients[2].border_width = beautiful.border_width
        else -- all previous clients already have their borders now
            c.border_width = beautiful.border_width -- maybe not needed
        end
    end
end)

client.connect_signal("unmanage", function(c)
    local shown_tiled_clients = awful.screen.focused().tiled_clients

    -- hide borders if last client and not floating
    if #shown_tiled_clients == 1 and (not shown_tiled_clients[1].floating and awful.layout.getname() ~= "floating") then
        shown_tiled_clients[1].border_width = beautiful.border_width_single_client
    end
end)

client.connect_signal("property::floating", function(c)
    -- following line may be not needed after signal property::maximized is reworked
    if c.maximized then return end -- fix conflict with signal property::maximized

    local shown_tiled_clients = awful.screen.focused().tiled_clients

    if c.floating or awful.layout.getname() == "floating" then
        -- show titlebar
        awful.titlebar.show(c)
        -- show borders
        c.border_width = beautiful.border_width
        -- hide borders of other client if only tiled remaining and layout not floating
        if #shown_tiled_clients == 1 and awful.layout.getname() ~= "floating" then
            shown_tiled_clients[1].border_width = beautiful.border_width_single_client
        end
    else
        awful.titlebar.hide(c)
        -- show borders of tiled clients only if multiple clients
        if #shown_tiled_clients == 1 then
            c.border_width = beautiful.border_width_single_client
        elseif #shown_tiled_clients == 2 then -- the other client needs its borders
            shown_tiled_clients[1].border_width = beautiful.border_width
            shown_tiled_clients[2].border_width = beautiful.border_width
        else -- all previous clients already have their borders now
            c.border_width = beautiful.border_width -- maybe not needed
        end
    end
end)

client.connect_signal("property::maximized", function(c)
    if awful.layout.getname() ~= "floating" then
        if c.maximized then
            c.maximized = false
        end
        if c.floating then
            c.floating = false
        end
    end
end)

client.connect_signal("untagged", function(c)
    local shown_tiled_clients = awful.screen.focused().tiled_clients

    -- hide borders if last client and not floating
    if #shown_tiled_clients == 1 and (not shown_tiled_clients[1].floating and awful.layout.getname() ~= "floating") then
        shown_tiled_clients[1].border_width = beautiful.border_width_single_client
    end
end)

client.connect_signal("property::minimized", function(c)
    local shown_tiled_clients = awful.screen.focused().tiled_clients

    if c.minimized then
        -- hide borders of other client if only tiled remaining and layout not floating
        if #shown_tiled_clients == 1 and (not shown_tiled_clients[1].floating and awful.layout.getname() ~= "floating") then
            shown_tiled_clients[1].border_width = beautiful.border_width_single_client
        end
    else
        if c.floating or awful.layout.getname() == "floating" then
            c.border_width = beautiful.border_width
        else
            -- show borders of tiled clients only if multiple clients
            if #shown_tiled_clients == 1 then
                c.border_width = beautiful.border_width_single_client
            elseif #shown_tiled_clients == 2 then -- the other client needs its borders
                shown_tiled_clients[1].border_width = beautiful.border_width
                shown_tiled_clients[2].border_width = beautiful.border_width
            else -- all previous clients already have their borders now
                c.border_width = beautiful.border_width -- maybe not needed
            end
        end
    end
end)
-- }}}
