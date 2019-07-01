-- TODO: app switcher that can select clients between all tags
-- currently only clients from selected tags are listed (useful for floating but not really for tiling)

-- look https://github.com/awesomeWM/awesome/blob/master/docs/90-FAQ.md#how-to-add-an-application-switcher
-- make this without a tasklist anf get inspiration from awful menu clientlist

local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")

local app_switcher = awful.popup {
    widget = awful.widget.tasklist {
        screen   = screen[1],
        filter   = awful.widget.tasklist.filter.currenttags,
        buttons  = tasklist_buttons,
        layout   = {
            -- spacing = 5,
            -- forced_num_rows = 2,
            layout = wibox.layout.grid.horizontal
        },
        widget_template = {
            {
                {
                    id     = 'clienticon',
                    widget = awful.widget.clienticon,
                },
                margins = 4,
                widget  = wibox.container.margin,
            },
            id              = 'background_role',
            forced_width    = 96,
            forced_height   = 96,
            widget          = wibox.container.background,
            create_callback = function(self, c, index, objects) --luacheck: no unused
                self:get_children_by_id('clienticon')[1].client = c
            end,
        },
    },
    border_color = beautiful.border_normal,
    border_width = beautiful.border_width,
    ontop        = true,
    placement    = awful.placement.centered,
    visible = false
}

awful.keygrabber {
    keybindings = {
        {{'Mod1'         }, 'Tab', function()
            awful.client.focus.byidx(1)
            if client.focus then
                client.focus.minimized = false
                client.focus:raise()
            end
        end},
        {{'Mod1', 'Shift'}, 'Tab', function()
            awful.client.focus.byidx(-1)
            if client.focus then
                client.focus.minimized = false
                client.focus:raise()
            end
        end},
    },
    -- Note that it is using the key name and not the modifier name.
    stop_key           = 'Mod1',
    stop_event         = 'release',
    start_callback     = function()
        app_switcher.visible = true
        awful.client.focus.history.disable_tracking()
    end,
    stop_callback      = function()
        app_switcher.visible = false
        awful.client.focus.history.enable_tracking()
    end,
    root_keybindings = {
        {{'Mod1'}, 'Tab', function() end},
        {{'Mod1', 'Shift'}, 'Tab', function() end},
    },
    -- export_keybindings = true,
}

return app_switcher
