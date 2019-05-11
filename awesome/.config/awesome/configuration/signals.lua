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

local function join(t1, t2)
    for _,v in ipairs(t2) do
        table.insert(t1, v)
    end
end

-- maybe a bit faster than #get_shown_clients() because it doesn't use join()
local function get_shown_clients_number()
    local tags = awful.screen.focused().selected_tags
    local count = 0
    for _,t in ipairs(tags) do
        count = count + #t:clients()
    end
    return count
end

local function get_shown_clients()
    local tags = awful.screen.focused().selected_tags
    local clients = {}
    for _, t in ipairs(tags) do
        join(clients, t:clients())
    end
    return clients
end

-- {{{ No borders if tiled and is only one client, titlebar only in floating layout, client remember if was maximized in
--     floating layout when switching layout
-- bug: maximized window then go tiled and window is not set back to not maximized
client.connect_signal("manage", function(c)
    local shown_clients = get_shown_clients()
    c.was_maximized = false -- hack to remember maximized state when switching from floating to another layout and back
    if c.floating or c.first_tag.layout.name == "floating" then
        awful.titlebar.show(c)
    else
        awful.titlebar.hide(c)
        if #shown_clients == 1 then
            c.border_width = beautiful.border_width_single_client
        else
            for _, cl in ipairs(shown_clients) do
                cl.border_width = beautiful.border_width
            end
        end
    end
end)

client.connect_signal("unmanage", function(c)
    local shown_clients = get_shown_clients()
    for _, cl in ipairs(shown_clients) do
        if cl.floating or cl.first_tag.layout.name == "floating" then
            awful.titlebar.show(cl)
        else
            awful.titlebar.hide(cl)
            if #shown_clients == 1 then
                cl.border_width = beautiful.border_width_single_client
            else
                cl.border_width = beautiful.border_width
            end
        end
    end
end)

client.connect_signal("property::maximized", function(c)
    if c.floating or c.first_tag.layout.name == "floating" then
        awful.titlebar.show(c)
    else
        awful.titlebar.hide(c)
        if get_shown_clients_number == 1 then
            c.border_width = beautiful.border_width_single_client
        else
            c.border_width = beautiful.border_width
        end
    end
end)

tag.connect_signal("property::layout", function(t)
    local shown_clients = get_shown_clients()
    for _, c in ipairs(shown_clients) do
        if c.floating or c.first_tag.layout.name == "floating" then
            awful.titlebar.show(c)
            if c.was_maximized then
                c.maximized = true
                c.was_maximized = false
            end
        else
            awful.titlebar.hide(c)
            if c.maximized then
                c.was_maximized = true
                c.maximized = false
            end
            if #shown_clients == 1 then
                c.border_width = beautiful.border_width_single_client
            else
                c.border_width = beautiful.border_width
            end
        end
    end
end)

tag.connect_signal("property::selected", function(t)
    local shown_clients = get_shown_clients()
    for _, c in ipairs(shown_clients) do
        if c.floating or c.first_tag.layout.name == "floating" then
            awful.titlebar.show(c)
            if c.was_maximized then
                c.maximized = true
                c.was_maximized = false
            end
        else
            awful.titlebar.hide(c)
            if c.maximized then
                c.was_maximized = true
                c.maximized = false
            end
            if #shown_clients == 1 then
                c.border_width = beautiful.border_width_single_client
            else
                c.border_width = beautiful.border_width
            end
        end
    end
end)

-- }}}