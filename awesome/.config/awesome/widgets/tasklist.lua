local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi
local color = require("themes.util.color")
local gtable = require("gears.table")
local gstring = require("gears.string")
local menu = require("popups.menu")
local desktopapps = require("util.desktopapps")
local dbus = require("dbus_proxy")
local Gio = require("lgi").Gio

-- TODO instead of creating and deleting widgets on the fly,
--      use caching: hide unused ones and reuse them if needed, create new eventually

-- TODO better task count indicator than number in task text
-- TODO add popup menu for tasks with count > 1 to select wich task on click:
--      if task is not selected, no popup menu and select last focused client of this task
--      if task is selected, open popup menu to choose

-- TODO cache awful.menus
-- TODO click outside closes awful.menus

-- TODO check if behaviour when filter is for focused tags only

local bg_hover_normal = color.lighten_by(beautiful.tasklist_bg_normal, 0.05)
local bg_hover_focus = color.lighten_by(beautiful.tasklist_bg_focus, 0.05)
local bg_hover_urgent = color.lighten_by(beautiful.tasklist_bg_urgent, 0.05)

local tooltip
if beautiful.tasklist_disable_task_name then
    tooltip = awful.tooltip {
        mode = "outside",
        preferred_positions = { "bottom", "right", "top", "left" },
        preferred_alignments = { "middle", "front", "back" },
        gaps = dpi(6)
    }
end

local function set_task_widget_style(widget)
    if widget.focused then
        if widget.hovered then
            widget.progressbar_widget.background_color = bg_hover_focus
        else
            widget.progressbar_widget.background_color = beautiful.tasklist_bg_focus
        end
        widget.background_widget.fg = beautiful.tasklist_fg_focus
    elseif widget.urgent then
        if widget.hovered then
            widget.progressbar_widget.background_color = bg_hover_urgent
        else
            widget.progressbar_widget.background_color = beautiful.tasklist_bg_urgent
        end
        widget.background_widget.fg = beautiful.tasklist_fg_urgent
    else
        if widget.hovered then
            widget.progressbar_widget.background_color = bg_hover_normal
        else
            widget.progressbar_widget.background_color = beautiful.tasklist_bg_normal
        end
        widget.background_widget.fg = beautiful.tasklist_fg_normal
    end
end

local function new_task_widget(c, desktopapp, clients)
    local text_widget = wibox.widget {
        markup = desktopapp.Name .. " ["..tostring(1).."]",
        visible = not beautiful.tasklist_disable_task_name,
        widget = wibox.widget.textbox
    }

    -- TODO add notif_count badge over icon
    local background_widget = wibox.widget {
        {
            {
                {
                    {
                        forced_height = dpi(22),
                        forced_width = dpi(22),
                        image = desktopapp.Icon,
                        visible = not beautiful.tasklist_disable_icon,
                        widget = wibox.widget.imagebox,
                    },
                    text_widget,
                    spacing = dpi(6),
                    layout = wibox.layout.fixed.horizontal
                },
                left = dpi(6),
                right = dpi(6),
                widget = wibox.container.margin
            },
            halign = 'center',
            widget = wibox.container.place
        },
        bg = "#00000000", -- transparent
        fg = _G.client.focus == c and beautiful.tasklist_fg_focus or beautiful.tasklist_fg_normal,
        widget = wibox.container.background
    }

    local progressbar_widget = wibox.widget {
        background_color = _G.client.focus == c and beautiful.tasklist_bg_focus or beautiful.tasklist_bg_normal,
        color = color.green.."77",
        value = 0,
        widget = wibox.widget.progressbar
    }

    local task_widget = wibox.widget {
        progressbar_widget,
        background_widget,
        uid = desktopapp.id,
        text_widget = text_widget,
        background_widget = background_widget,
        progressbar_widget = progressbar_widget,
        focused = _G.client.focus == c,
        urgent = c.urgent,
        layout = wibox.layout.stack
    }

    -- TODO on mouse click check if there is a mouse enter in another item. if yes, swap them. it is a form of drag to rearrange.
    --      maybe make my own layout to be able to to this drag visually (the item follows the mouse).
    -- make a system to be able to pin items even if they are closed ?
    task_widget:buttons {
        awful.button({ }, 1, function()
            -- TODO do not rebuild this menu each time: cache it and add/remove elements dynamically
            if #clients > 1 then
                -- TODO better menu
                local temp = {}
                for i, c in pairs(clients) do
                    temp[i] = {
                        c.name,
                        function()
                            c:raise()
                            c:jump_to()
                        end,
                        desktopapp.Icon
                    }
                end
                menu(temp):show()
            elseif clients[1] == _G.client.focus then
                clients[1].minimized = true
            else
                clients[1]:raise()
                clients[1]:jump_to()
            end
        end),
        awful.button({ }, 2, function()
            if desktopapp.cmdline then
                awful.spawn.easy_async_with_shell(desktopapp.cmdline, function() end)
            end
        end),
        awful.button({ }, 3, function()
            local items
            if desktopapp.Actions then
                items = gtable.clone(desktopapp.Actions)
                items[#items + 1] = { separator = true }
            else
                items = {}
            end
            items[#items + 1] = {
                "Tout quitter",
                function()
                    for _,c in ipairs(clients) do
                        c:kill()
                    end
                end
            }
            menu(items):show()
        end),
        -- TODO use faster implementation of a circular list than this
        awful.button({ }, 4, function()
            local temp = table.remove(clients)
            table.insert(clients, 1, temp)
            clients[1]:raise()
            clients[1]:jump_to()
        end),
        awful.button({ }, 5, function()
            local temp = table.remove(clients, 1)
            table.insert(clients, temp)
            clients[1]:raise()
            clients[1]:jump_to()
        end)
    }

    if tooltip then
        tooltip:add_to_object(task_widget)
    end

    task_widget:connect_signal("mouse::enter", function()
        if tooltip then
            tooltip.text = desktopapp.Name
        end

        task_widget.hovered = true
        set_task_widget_style(task_widget)
    end)
    task_widget:connect_signal("mouse::leave", function()
        task_widget.hovered = false
        set_task_widget_style(task_widget)
    end)

    return task_widget
end

local function new_task(desktopapp, c, tasklist)
    local clients = { c }
    local task = {
        desktopapp = desktopapp,
        widget = new_task_widget(c, desktopapp, clients),
        count = 1,
        notif_count = 0,
        notif_count_visible = false,
        notif_progress = 0,
        notif_progress_visible = false,
        clients = clients,
        focus = function(self)
            if not self.widget then return end
    
            self.widget.focused = true
            set_task_widget_style(self.widget)
        end,
        unfocus = function(self)
            if not self.widget then return end
    
            self.widget.focused = false
            set_task_widget_style(self.widget)
        end,
        set_urgent = function(self, value)
            if not self.widget then return end

            self.widget.urgent = value
            set_task_widget_style(self.widget)
        end,
        update_notif = function(self, progress)
            if progress then
                self.notif_count = progress["count"] or self.notif_count
                self.notif_count_visible = progress["count-visible"] or self.notif_count_visible
                self.notif_progress = progress["progress"] or self.notif_progress
                self.notif_progress_visible = progress["progress-visible"] or self.notif_progress_visible
            end

            self.widget.progressbar_widget.value = self.notif_progress
        end,
        add_client = function(self, c)
            self.count = self.count + 1
            if self.count == 1 then
                self.widget = new_task_widget(c, self.desktopapp, self.clients)
                self:update_notif()
                tasklist:add(self.widget)
            else
                self.widget.text_widget.markup = desktopapp.Name .. " ["..tostring(self.count).."]"
            end
            table.insert(self.clients, c)
        end,
        remove_client = function(self, c)
            for k,v in ipairs(self.clients) do
                if v == c then
                    table.remove(self.clients, k)
                    break
                end
            end
            self.count = self.count - 1
            if self.count == 0 then
                tasklist:remove_task_widget(self.desktopapp.id)
                self.widget = nil
            else
                self.widget.text_widget.markup = desktopapp.Name .. " ["..tostring(self.count).."]"
            end
        end
    }

    tasklist:add(task.widget)

    return task
end

local tasklist_id_counter = 1
return function(s, filter_func)
    local filter = filter_func or function(c, s) return true end

    local tasklist = wibox.widget {
        visible = false,
        uid = tasklist_id_counter,
        remove_task_widget = function(self, id)
            for k,v in ipairs(self.children) do
                if v.uid == id then
                    if tooltip then
                        tooltip:remove_from_object(v)
                    end
                    return self:remove(k)
                end
            end
        end,
        layout = wibox.layout.flex.horizontal
    }

    local managed_by_tasklist_prop = "managed_by_tasklist"..tasklist.uid
    tasklist_id_counter = tasklist_id_counter + 1
    
    local class_to_task, desktopapp_id_to_task = {}, {}

    local function manage_task(c)
        if (c.skip_taskbar or c.hidden or c.type == "splash" or c.type == "dock" or c.type == "desktop")
            and not filter(c, s) then return end
        
        c[managed_by_tasklist_prop] = true

        local task = class_to_task[c.class]
        if not task then
            local desktopapp = desktopapps.get_desktopapp_from_client(c)
            if desktopapp then
                class_to_task[c.class] = new_task(desktopapp, c, tasklist)
                desktopapp_id_to_task[desktopapp.id] = class_to_task[c.class]
            else
                -- client with no found desktop file
                local id = tostring(c.window)
                class_to_task[id] = new_task({ Name = c.name or gstring.xml_escape("<unkown>"), Icon = c.icon, id = id }, c, tasklist)
            end
        else
            task:add_client(c)
        end
    end

    local function unmanage_task(c)
        if not c[managed_by_tasklist_prop] then return end

        local task = class_to_task[c.class]
        if not task then
            local id = tostring(c.window)
            task = class_to_task[id]
            if not task then return end
            class_to_task[id] = nil
        end
        task:remove_client(c)
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
        for _,task in pairs(class_to_task) do
            task.count = 0
            task.clients = {}
        end

        for _,c in pairs(client.get()) do
            manage_task(c)
        end
    end

    local function start_tasklist()
        update_task_list()

        _G.client.connect_signal("tagged", manage_task)
        _G.client.connect_signal("untagged", unmanage_task)
        if filter_func then
            _G.tag.connect_signal("property::selected", update_task_list)
        end
    
        _G.client.connect_signal("focus", function(c)
            if not c[managed_by_tasklist_prop] then return end

            local task = class_to_task[c.class] or class_to_task[tostring(c.window)]
            if not task then return end
            task:focus()
        end)
        _G.client.connect_signal("unfocus", function(c)
            if not c[managed_by_tasklist_prop] then return end

            local task = class_to_task[c.class] or class_to_task[tostring(c.window)]
            if not task then return end
            task:unfocus()
        end)
        _G.client.connect_signal("property::urgent", function(c)
            if not c[managed_by_tasklist_prop] then return end

            local task = class_to_task[c.class] or class_to_task[tostring(c.window)]
            if not task then return end
            task:set_urgent(c.urgent)
        end)
    
        -- TODO watch sender of this signal and reset all tasks count and progress when name lost
        dbus.Bus.SESSION:signal_subscribe(
            nil, 'com.canonical.Unity.LauncherEntry',
            'Update', nil, nil,
            Gio.DBusSignalFlags.NONE, function(conn, sender, object_path, interface_name, signal_name, parameters, user_data)
                local task = desktopapp_id_to_task[parameters[1]:match("^application://(.+).desktop$")]
                if not task then return end
                task:update_notif(parameters[2])
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
