local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi
local tasklist = require("awful.widget.tasklist")
local clientmenu = require("popups.clientmenu")
local color = require("themes.util.color")
local desktopapps = require("util.desktopapps")
local dbus = require("dbus_proxy")
local Gio = require("lgi").Gio

-- TODO refactor needed: there is a lot to fix and optimize
-- TODO instead of creating and deleting widges on the fly,
--      use caching: hide unused ones and reuse them if needed, create new eventually

local filter = tasklist.filter.currenttags

local bg_hover = color.lighten_by(beautiful.tasklist_bg_normal, 0.05)
local sticky = beautiful.tasklist_sticky or "▪"
local ontop = beautiful.tasklist_ontop or '⌃'
local above = beautiful.tasklist_above or '▴'
local below = beautiful.tasklist_below or '▾'
local floating = beautiful.tasklist_floating or '✈'
local maximized = beautiful.tasklbeautiful or '<b>+</b>'
local maximized_horizontal = beautiful.tasklist_maximized_horizontal or '⬌'
local maximized_vertical = beautiful.tasklist_maximized_vertical or '⬍'

local function get_name(desktopapp, count)
    -- print(tostring(count))
    count = count or 1
    local name = desktopapp.Name .. " ["..tostring(count).."]"
    -- if not beautiful.tasklist_plain_task_name then
    --     if c.sticky then name = name .. sticky end

    --     if c.ontop then name = name .. ontop
    --     elseif c.above then name = name .. above
    --     elseif c.below then name = name .. below end

    --     if c.maximized then
    --         name = name .. maximized
    --     else
    --         if c.maximized_horizontal then name = name .. maximized_horizontal end
    --         if c.maximized_vertical then name = name .. maximized_vertical end
    --         if c.floating then name = name .. floating end
    --     end
    -- end
    return name
end

local function new_task_widget(c, desktopapp, notif_progress)
    local text_widget = wibox.widget {
        markup = get_name(desktopapp, 1),
        id = "text",
        visible = not beautiful.tasklist_disable_task_name,
        widget = wibox.widget.textbox
    }

    local background_widget = wibox.widget {
        {
            {
                {
                    {
                        forced_height = dpi(22),
                        forced_width = dpi(22),
                        client = c, -- TODO replace this by desktopapp.Icon
                        visible = not beautiful.tasklist_disable_icon,
                        widget = awful.widget.clienticon,
                    },
                    text_widget,
                    spacing = dpi(4),
                    layout = wibox.layout.fixed.horizontal
                },
                left = dpi(4),
                right = dpi(4),
                widget = wibox.container.margin
            },
            halign = 'center',
            widget = wibox.container.place
        },
        bg = "#00000000", -- transparent
        fg = _G.client.focus == c and beautiful.tasklist_fg_focus or beautiful.tasklist_fg_normal,
        widget = wibox.widget.background
    }

    local progressbar_widget = wibox.widget {
        background_color = _G.client.focus == c and beautiful.tasklist_bg_focus or beautiful.tasklist_bg_normal,
        color = beautiful.accent.."55",
        value = notif_progress or 0,
        widget = wibox.widget.progressbar
    }

    local task_widget = wibox.widget {
        progressbar_widget,
        background_widget,
        desktopapp = desktopapp,
        text_widget = text_widget, -- TODO remove these from widget and place getter/prop setter functions instead ?
        background_widget = background_widget,
        progressbar_widget = progressbar_widget,
        layout = wibox.layout.stack
    }

    local buttons = {
        awful.button({ }, 1, function()
            if c == _G.client.focus then
                c.minimized = true
            else
                c:emit_signal(
                    "request::activate",
                    "tasklist",
                    { raise = true }
                )
            end
        end),
        awful.button({ }, 3, function()
            clientmenu.launch(c)
        end),
        -- TODO these buttons (a task need a list of all associated clients ??)
        -- awful.button({ }, 4, function()
        --     awful.client.focus.byidx(1)
        -- end),
        -- awful.button({ }, 5, function()
        --     awful.client.focus.byidx(-1)
        -- end)
    }
    task_widget:buttons(buttons)

    task_widget:connect_signal("mouse::enter", function()
        if _G.client.focus ~= c then
            progressbar_widget.background_color = bg_hover
        end
    end)
    task_widget:connect_signal("mouse::leave", function()
        if _G.client.focus ~= c then
            progressbar_widget.background_color = beautiful.tasklist_bg_normal
        end
    end)

    return task_widget
end

return function(s)
    local tasklist = wibox.widget {
        visible = false,
        layout = wibox.layout.flex.horizontal
    }

    local class_to_task = {}
    local desktopapp_id_to_task = {}

    local function remove_task_widget(desktopapp)
        for k,v in ipairs(tasklist.children) do
            if v.desktopapp == desktopapp then
                return tasklist:remove(k)
            end
        end
    end

    local function manage_task(c)
        if not filter(c, s) then return end
        
        c.managed_by_tasklist = true

        local task = class_to_task[c.class]
        if not task then
            local entry = desktopapps.get_desktopapp_from_client(c)
            -- TODO add the new_task_widget in this table (then we no longer need to loop to find widget associated with desktopapp)
            class_to_task[c.class] = {
                desktopapp = entry,
                widget = new_task_widget(c, entry),
                count = 1,
                notif_count = 0,
                notif_count_visible = false,
                notif_progress = 0,
                notif_progress_visible = false
            }
            desktopapp_id_to_task[entry.id] = class_to_task[c.class]
            tasklist:add(class_to_task[c.class].widget)
            -- TODO handle case where there is no entry found (happens if window has no .desktop file or my matcher didn't find it)
        else
            task.count = task.count + 1
            if task.count == 1 then
                task.widget = new_task_widget(c, task.desktopapp, task.notif_progress)
                tasklist:add(task.widget)
            else
                task.widget.text_widget.markup = get_name(task.desktopapp, task.count)
            end
        end
    end

    local function unmanage_task(c)
        if not c.managed_by_tasklist then return end
        
        local task = class_to_task[c.class]
        if not task then return end
        task.count = task.count - 1
        if task.count == 0 then
            remove_task_widget(task.desktopapp)
            class_to_task[c.class].widget = nil
        else
            task.widget.text_widget.markup = get_name(task.desktopapp, task.count)
        end
    end

    local tag_selected_count = #awful.screen.focused().selected_tags
    local function update_task_list(t)
        local new_tag_selected_count = #awful.screen.focused().selected_tags
        if t and (not t.selected and tag_selected_count - new_tag_selected_count == 0) then
            tag_selected_count = new_tag_selected_count
            return
        end
        tag_selected_count = new_tag_selected_count

        tasklist:reset()
        for _,v in pairs(class_to_task) do
            v.count = 0
        end

        for _,c in pairs(client.get()) do
            manage_task(c)
        end
    end

    local function start_tasklist()
        update_task_list()

        _G.client.connect_signal("tagged", manage_task)
        _G.client.connect_signal("untagged", unmanage_task)
        _G.tag.connect_signal("property::selected", update_task_list)
    
        _G.client.connect_signal("focus", function(c)
            if not c.managed_by_tasklist then return end
    
            local task = class_to_task[c.class]
            if not task then return end
    
            local task_widget = task.widget
            if not task_widget then return end
    
            task_widget.progressbar_widget.background_color = beautiful.tasklist_bg_focus
            task_widget.background_widget.fg = beautiful.tasklist_fg_focus
        end)
        _G.client.connect_signal("unfocus", function(c)
            if not c.managed_by_tasklist then return end
    
            local task = class_to_task[c.class]
            if not task then return end
    
            local task_widget = task.widget
            if not task_widget then return end
    
            task_widget.progressbar_widget.background_color = beautiful.tasklist_bg_normal
            task_widget.background_widget.fg = beautiful.tasklist_fg_normal
        end)
    
        -- _G.client.connect_signal("property::name", update_name)
        -- _G.client.connect_signal("property::urgent", update_name)
        -- _G.client.connect_signal("property::sticky", update_name)
        -- _G.client.connect_signal("property::ontop", update_name)
        -- _G.client.connect_signal("property::above", update_name)
        -- _G.client.connect_signal("property::below", update_name)
        -- _G.client.connect_signal("property::floating", update_name)
        -- _G.client.connect_signal("property::maximized_horizontal", update_name)
        -- _G.client.connect_signal("property::maximized_vertical", update_name)
        -- _G.client.connect_signal("property::maximized", update_name)
        -- _G.client.connect_signal("property::minimized", update_name)
    
        -- TODO watch name 'com.canonical.Unity.LauncherEntry' and reset all tasks count and progress when name lost
        dbus.Bus.SESSION:signal_subscribe(
            nil, 'com.canonical.Unity.LauncherEntry',
            'Update', nil, nil,
            Gio.DBusSignalFlags.NONE, function(conn, sender, object_path, interface_name, signal_name, parameters, user_data)
                local task = desktopapp_id_to_task[parameters[1]:match("^application://(.+).desktop$")]
                if not task then return end

                task.notif_count = parameters[2]["count"]
                task.notif_count_visible = parameters[2]["count-visible"]
                task.notif_progress = parameters[2]["progress"]
                task.notif_progress_visible = parameters[2]["progress-visible"]

                task.widget.progressbar_widget.value = task.notif_progress
            end
        )
    end

    desktopapps.on_entries_updated(function()
        if not tasklist.visible then
            tasklist.visible = true
            start_tasklist()
        end
    end)

    return tasklist
end

-- TODO firefox intall extension popup is skip_taskbar and transient_for (it has titlebars but shouldn't)
