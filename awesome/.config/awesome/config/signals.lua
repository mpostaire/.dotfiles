local awful = require("awful")
local beautiful = require("beautiful")
local capi = {client = client, awesome = awesome, tag = tag}

-- Signal function to execute when a new client appears.
capi.client.connect_signal("manage", function(c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    if not capi.awesome.startup then awful.client.setslave(c) end

    if capi.awesome.startup
        and not c.size_hints.user_position
        and not c.size_hints.program_position then
            -- Prevent clients from being unreachable after screen count changes.
            awful.placement.no_offscreen(c)
    end
end)

-- Enable sloppy focus, so that focus follows mouse.
capi.client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

capi.client.connect_signal("focus", function(c)
    c.border_color = beautiful.border_focus
end)
capi.client.connect_signal("unfocus", function(c)
    c.border_color = beautiful.border_normal
end)

-- Focus urgent clients automatically
client.connect_signal("property::urgent", function(c)
    c.minimized = false
    c:raise()
    c:jump_to()
end)

-- {{{ No borders if tiled and is only one client, titlebar only in floating layout, rounded top titlebar corners,
-- client do not remember if was maximized in floating layout when switching layout, no maximized state if tiled layout
-- /!\ A client in a tag's floating layout is not always floating. Floating is a special mode that ignores the tag's layout.
--     In following comments floating and tiled client really mean its layout not the special mode.
-- Big ugly piece of code but I think I got every corner case covered. It could be simpler but more performance consuming.
-- /!\ With the following code, clients have titlebars while floating and no titlebars otherwise depending
-- of client.requests_no_titlebar or client.show_titlebars

local function show_titlebar(client)
    if not client.requests_no_titlebar or client.show_titlebars then
        awful.titlebar.show(client)
        client.titlebar_showed = true
    end
end

local function hide_titlebar(client)
    awful.titlebar.hide(client)
    client.titlebar_showed = false
end

local function handle_tiled(client)
    -- this if statement is new, if bugs related to maximized state, check there first
    -- if client.maximized then
    --     client.was_maximized = true
    -- end
    client.maximized = false
    hide_titlebar(client)
    if #awful.screen.focused().tiled_clients == 1 and not beautiful.gap_single_client then
        client.border_width = 0
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
        show_titlebar(client)
        client.border_width = beautiful.border_width
        -- resize client to its previous size minus titlebar size
        if not client.floating and not client.fullscreen and not client.requests_no_titlebar then
            client:relative_move(0, 0, 0, -(beautiful.wibar_height - beautiful.border_width))
        end
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

capi.tag.connect_signal("property::layout", handle_everything)

capi.tag.connect_signal("property::selected", handle_everything)

capi.client.connect_signal("manage", function(c)
    -- c.was_maximized = false
    local shown_tiled_clients = awful.screen.focused().tiled_clients

    if c.floating or awful.layout.getname() == "floating" then
        -- show titlebar
        show_titlebar(c)
        -- show borders
        c.border_width = beautiful.border_width -- maybe not needed
    else
        -- hide titlebar
        hide_titlebar(c)
        -- show borders of tiled clients only if multiple clients
        if #shown_tiled_clients == 1 then
            c.border_width = 0
        elseif #shown_tiled_clients == 2 then -- the other client needs its borders
            shown_tiled_clients[1].border_width = beautiful.border_width
            shown_tiled_clients[2].border_width = beautiful.border_width
        else -- all previous clients already have their borders now
            c.border_width = beautiful.border_width -- maybe not needed
        end
    end
end)

capi.client.connect_signal("unmanage", function(c)
    local shown_tiled_clients = awful.screen.focused().tiled_clients

    -- hide borders if last client and not floating
    if #shown_tiled_clients == 1 and (not shown_tiled_clients[1].floating and awful.layout.getname() ~= "floating") then
        shown_tiled_clients[1].border_width = 0
    end
end)

capi.client.connect_signal("property::floating", function(c)
    -- following line may be not needed after signal property::maximized is reworked
    if c.maximized then return end -- fix conflict with signal property::maximized

    local shown_tiled_clients = awful.screen.focused().tiled_clients

    if c.floating or awful.layout.getname() == "floating" then
        -- show titlebar
        show_titlebar(c)
        -- show borders
        c.border_width = beautiful.border_width
        -- hide borders of other client if only tiled remaining and layout not floating
        if #shown_tiled_clients == 1 and awful.layout.getname() ~= "floating" then
            shown_tiled_clients[1].border_width = 0
        end
        -- resize client to its previous size minus titlebar size
        -- FIXME when awesome is restarded and a client is set floating this is applied and the client shrinks each time
        if awful.layout.getname() ~= "floating" and not c.fullscreen and not c.requests_no_titlebar then
            c:relative_move(0, 0, 0, -(beautiful.wibar_height - beautiful.border_width))
        end
    else
        hide_titlebar(c)
        -- show borders of tiled clients only if multiple clients
        if #shown_tiled_clients == 1 then
            c.border_width = 0
        elseif #shown_tiled_clients == 2 then -- the other client needs its borders
            shown_tiled_clients[1].border_width = beautiful.border_width
            shown_tiled_clients[2].border_width = beautiful.border_width
        else -- all previous clients already have their borders now
            c.border_width = beautiful.border_width -- maybe not needed
        end
    end
end)

capi.client.connect_signal("property::maximized", function(c)
    if awful.layout.getname() ~= "floating" then
        if c.maximized then
            c.maximized = false
        end
        if c.floating then
            c.floating = false
        end
    end
end)

capi.client.connect_signal("untagged", function(c)
    local shown_tiled_clients = awful.screen.focused().tiled_clients

    -- hide borders if last client and not floating
    if #shown_tiled_clients == 1 and (not shown_tiled_clients[1].floating and awful.layout.getname() ~= "floating") then
        shown_tiled_clients[1].border_width = 0
    end
end)

capi.client.connect_signal("property::minimized", function(c)
    local shown_tiled_clients = awful.screen.focused().tiled_clients

    if c.minimized then
        -- hide borders of other client if only tiled remaining and layout not floating
        if #shown_tiled_clients == 1 and (not shown_tiled_clients[1].floating and awful.layout.getname() ~= "floating") then
            shown_tiled_clients[1].border_width = 0
        end
    else
        if c.floating or awful.layout.getname() == "floating" then
            c.border_width = beautiful.border_width
            show_titlebar(c)
        else
            -- show borders of tiled clients only if multiple clients
            if #shown_tiled_clients == 1 then
                c.border_width = 0
            elseif #shown_tiled_clients == 2 then -- the other client needs its borders
                shown_tiled_clients[1].border_width = beautiful.border_width
                shown_tiled_clients[2].border_width = beautiful.border_width
            else -- all previous clients already have their borders now
                c.border_width = beautiful.border_width -- maybe not needed
            end
            hide_titlebar(c)
        end
    end
end)
-- }}}
