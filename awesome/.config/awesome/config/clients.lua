local awful = require("awful")
local ruled = require("ruled")
local beautiful = require("beautiful")
-- when a client is closed, another client will be focused
require("awful.autofocus")

-- Rules to apply to new clients.
ruled.client.connect_signal("request::rules", function()
    -- All clients will match this rule.
    ruled.client.append_rule {
        id         = "global",
        rule       = { },
        properties = {
            focus     = awful.client.focus.filter,
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            raise     = true,
            screen    = awful.screen.preferred,
            placement = awful.placement.no_overlap + awful.placement.no_offscreen,
            size_hints_honor = true
        }
    }
    
    -- Floating clients.
    ruled.client.append_rule {
        id       = "floating",
        rule_any = {
            instance = {
                "DTA", -- Firefox addon DownThemAll.
                "copyq",
                "pinentry",
                "Browser" -- Firefox about window
            },
            class    = {
                "Arandr",
                "Blueman-manager",
                "Gpick",
                "Kruler",
                "MessageWin", -- kalarm.
                "Sxiv",
                "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
                "Wpa_gui",
                "veromix",
                "xtightvncviewer",
                "Gnome-calculator"
            },
            -- Note that the name property shown in xprop might be set slightly after creation of the client
            -- and the name shown there might not match defined rules here.
            name    = {
                "Event Tester",  -- xev.
            },
            role    = {
                "AlarmWindow",    -- Thunderbird's calendar.
                "ConfigManager",  -- Thunderbird's about:config.
                "pop-up",         -- e.g. Google Chrome's (detached) Developer Tools.
            }
        },
        properties = { floating = true }
    }

    -- Add titlebars to normal clients and dialogs
    ruled.client.append_rule {
        id         = "titlebars",
        rule_any   = { type = { "normal", "dialog" } },
        properties = { titlebars_enabled = true      }
    }

    -- Dialog clients centered on screen
    ruled.client.append_rule {
        id         = "dialog_centered",
        rule_any   = { type = { "dialog" } },
        properties = { callback = function(c) awful.placement.centered(c) end }
    }

    -- TODO transient_for windows no titlebars and borders
    -- TODO modal windows : their parent cannot be focused (if focus in parent transfer it to the modal window)

    -- Vscode bug: its titlebar cannot be used to move window in awesomewm
    -- and its maximize/minimize button only works for maximizing so we force it to have one
    ruled.client.append_rule {
        rule = {class = "Code"},
        properties = {
            show_titlebars = true,
        }
    }

    -- URxvt size fix
    ruled.client.append_rule {
        rule = {class = "URxvt"},
        properties = {
            size_hints_honor = false
        }
    }

    -- Set Firefox to always map on the tag named "2" on screen 1.
    ruled.client.append_rule {
        rule       = { class = "Firefox"     },
        properties = { screen = 1, tag = "2" }
    }

    ruled.client.append_rule {
        rule = {class = "Steam"},
        properties = {tag = "6"}
    }
end)

-- Signal function to execute when a new client appears.
_G.client.connect_signal("manage", function(c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    if not _G.awesome.startup then awful.client.setslave(c) end

    if _G.awesome.startup
        and not c.size_hints.user_position
        and not c.size_hints.program_position then
            -- Prevent clients from being unreachable after screen count changes.
            awful.placement.no_offscreen(c)
    end
end)

-- Enable sloppy focus, so that focus follows mouse except in floating layout.
_G.client.connect_signal("mouse::enter", function(c)
    if awful.layout.getname() ~= "floating" then
        c:emit_signal("request::activate", "mouse_enter", {raise = false})
    end
end)

_G.client.connect_signal("focus", function(c)
    c.border_color = beautiful.border_focus
end)
_G.client.connect_signal("unfocus", function(c)
    c.border_color = beautiful.border_normal
end)

-- Focus urgent clients automatically
client.connect_signal("property::urgent", function(c)
    c.minimized = false
    c:raise()
    c:jump_to()
end)

-- No borders if tiled and there is only one client, titlebar only in floating layout,
-- client do not remember if was maximized in floating layout when switching layout,
-- if tiled layout and floating client, maximize will switch client to tiled.

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

_G.tag.connect_signal("property::layout", handle_everything)

_G.tag.connect_signal("property::selected", handle_everything)

_G.client.connect_signal("manage", function(c)
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

_G.client.connect_signal("unmanage", function(c)
    local shown_tiled_clients = awful.screen.focused().tiled_clients

    -- hide borders if last client and not floating
    if #shown_tiled_clients == 1 and (not shown_tiled_clients[1].floating and awful.layout.getname() ~= "floating") then
        shown_tiled_clients[1].border_width = 0
    end
end)

_G.client.connect_signal("property::floating", function(c)
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
        if awful.layout.getname() ~= "floating" and not c.fullscreen and not c.requests_no_titlebar and not awesome.startup then
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

_G.client.connect_signal("property::maximized", function(c)
    if awful.layout.getname() ~= "floating" then
        if c.maximized then
            c.maximized = false
        end
        if c.floating then
            c.floating = false
        end
    end
end)

_G.client.connect_signal("untagged", function(c)
    local shown_tiled_clients = awful.screen.focused().tiled_clients

    -- hide borders if last client and not floating
    if #shown_tiled_clients == 1 and (not shown_tiled_clients[1].floating and awful.layout.getname() ~= "floating") then
        shown_tiled_clients[1].border_width = 0
    end
end)

_G.client.connect_signal("property::minimized", function(c)
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
