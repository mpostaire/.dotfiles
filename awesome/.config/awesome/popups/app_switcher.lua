-- TODO: make this app switcher work for all tags of one screen
-- replace tasklist by a custom widget because we want to highlight a client before selecting it
--  --> we want to focus the selected client only when app switcher is closed, when keys are released
-- we want to use history so when we use app switcher, the first client to be selected will be the next, then
-- when we reopen app switcher, the first client to be selected will be the one precedently selected
-- (check with gnome how it works)
-- we want to prevent popup from being visible when there is 0 clients to show

local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi
local gears = require("gears")
local variables = require("config.variables")
local capi = {client = client, mouse = mouse}

-- check if client 'c' is in selected tags
local function current_tag_filter(c)
    for _,v in pairs(awful.screen.focused().selected_tags) do
        if c.first_tag == v then
            return true
        end
    end
    return false
end

local function focus_client(c)
    c:emit_signal(
        "request::activate",
        "tasklist",
        {raise = true}
    )
    -- c.first_tag:view_only()
end

local function focus_next_client()
    local iterator = awful.client.iterate(current_tag_filter)
    iterator()
    local c = iterator()
    if c then
        focus_client(c)
    end
end

local function focus_prev_client()
    for c in awful.client.iterate(current_tag_filter) do
        focus_client(c)
    end
end

-- launched programs widget mouse handling
local tasklist_buttons = gears.table.join(
    awful.button({variables.altkey}, 1, function (c)
        if c ~= capi.client.focus then
            focus_client(c)
        end
    end),
    awful.button({ }, 4, focus_next_client),
    awful.button({ }, 5, focus_prev_client)
)

local app_switcher = awful.popup {
    widget = awful.widget.tasklist {
        screen = capi.mouse.screen,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
        layout = {
            -- spacing = 5,
            -- forced_num_rows = 2,
            layout = wibox.layout.grid.horizontal
        },
        widget_template = {
            {
                {
                    {
                        {
                            id = 'icon_role',
                            forced_height = dpi(110),
                            forced_width = dpi(110),
                            widget = wibox.widget.imagebox,
                        },
                        halign = 'center',
                        widget = wibox.container.place
                    },
                    nil,
                    {
                        {
                            id = 'text_role',
                            widget = wibox.widget.textbox,
                        },
                        halign = 'center',
                        widget = wibox.container.place
                    },
                    forced_height = dpi(128),
                    forced_width = dpi(128),
                    layout = wibox.layout.align.vertical
                },
                margins = dpi(4),
                widget  = wibox.container.margin,
            },
            id = 'background_role',
            widget = wibox.container.background,
        },
    },
    border_color = beautiful.border_normal,
    border_width = beautiful.border_width,
    ontop = true,
    placement = awful.placement.centered,
    visible = false
}

awful.keygrabber {
    keybindings = {
        {{variables.altkey}, 'Tab', focus_next_client},
        {{variables.altkey, 'Shift'}, 'Tab', focus_prev_client},
    },
    -- Note that it is using the key name and not the modifier name.
    stop_key = variables.altkey,
    stop_event = 'release',
    start_callback = function()
        app_switcher.visible = true
        awful.client.focus.history.disable_tracking()
    end,
    stop_callback = function()
        app_switcher.visible = false
        awful.client.focus.history.enable_tracking()
    end,
    root_keybindings = {
        {{variables.altkey}, 'Tab', focus_next_client, nil, {description = 'app switcher', group = 'client'}},
        {{variables.altkey, 'Shift'}, 'Tab', focus_prev_client, nil, {description = 'reverse app switcher', group = 'client'}},
    },
}

return app_switcher
