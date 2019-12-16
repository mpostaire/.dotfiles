local awful = require("awful")
local beautiful = require("beautiful")
local bindings = require("config.bindings")

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    {
        rule = {},
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = bindings.clientkeys,
            buttons = bindings.clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap + awful.placement.no_offscreen,
            size_hints_honor = true
        }
    },
    -- Floating clients.
    {
        rule_any = {
            instance = {
                "DTA", -- Firefox addon DownThemAll.
                "copyq", -- Includes session name in class.
                "pinentry",
                "Browser" -- Firefox about window
            },
            class = {
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
            name = {
                "Event Tester" -- xev.
            },
            role = {
                "AlarmWindow", -- Thunderbird's calendar.
                "ConfigManager", -- Thunderbird's about:config.
                "pop-up" -- e.g. Google Chrome's (detached) Developer Tools.
            }
        },
        properties = {floating = true}
    },
    -- Add titlebars to normal clients and dialogs
    {
        rule_any = {
            type = {"normal", "dialog"}
        },
        properties = {
            show_titlebars = true
        }
    },
    -- Dialog clients centered on screen
    {
        rule_any = {
            type = {"dialog"}
        },
        properties = {
            callback = function(c) awful.placement.centered(c) end
        }
    },
    -- Vscode bug: its titlebar cannot be used to move window in awesomewm
    -- and its maximize/minimize button only works for maximizing so we force it to have one
    {
        rule = {class = "Code"},
        properties = {
            show_titlebars = true,
        }
    },
    -- URxvt size fix
    {
        rule = {class = "URxvt"},
        properties = {
            size_hints_honor = false
        }
    },
    -- Set Firefox to always map on the tag named "2" on screen 1.
    {
        rule = {class = "firefox"},
        properties = {screen = 1, tag = "2"}
    },
    {
        rule = {class = "Steam"},
        properties = {tag = "6"}
    }
}
-- }}}
