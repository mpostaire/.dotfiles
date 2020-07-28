local awful = require("awful")
local ruled = require("ruled")
local beautiful = require("beautiful")

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
