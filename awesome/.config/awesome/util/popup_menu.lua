-- a popup based improved imitation of an awful menu

-- make this compatible with more widgets as items (like progressbar, slider, check button, etc)

-- add support for dynamic items addition/removal

-- maybe make the align layout wrapped inside a constraint container

-- see if using a wibox directly is better

local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")

local popup_menu = {}
popup_menu.__index = popup_menu

function popup_menu:make_item(item)
    local layout = wibox.layout.align.horizontal()

    local icon_widget = wibox.widget.imagebox()
    icon_widget.forced_height = 16
    icon_widget.forced_width = 16
    icon_widget.resize = true

    local icons_normal, icons_focus, current_icon = {}, {}

    if item.icons then
        for k,v in pairs(item.icons) do
            icons_normal[k] = gears.color.recolor_image(v, beautiful.fg_normal)
            icons_focus[k] = gears.color.recolor_image(v, beautiful.bg_normal)
        end

        current_icon = item.current_icon or next(icons_normal)

        icon_widget:set_image(icons_normal[current_icon])
    end
    layout.first = wibox.container.margin(icon_widget, 0, beautiful.menu_item_margins, 0, 0)

    local text_widget = wibox.widget.textbox()
    if item.text then
        text_widget:set_markup(item.text)
    end
    layout.second = text_widget

    local submenu_widget = wibox.widget.imagebox()
    submenu_widget.forced_height = 16
    submenu_widget.forced_width = 16
    submenu_widget.resize = true

    local submenu, icon_submenu_normal, icon_submenu_focus
    if item.cmd then
        if type(item.cmd) ~= "function" then
            icon_submenu_normal = gears.color.recolor_image(beautiful.menu_submenu_icon, beautiful.fg_normal)
            icon_submenu_focus = gears.color.recolor_image(beautiful.menu_submenu_icon, beautiful.bg_normal)
            submenu_widget:set_image(icon_submenu_normal)

            submenu = popup_menu:new(item.cmd, self)
        end
    end
    layout.third = wibox.container.margin(submenu_widget, beautiful.menu_item_margins, 0, 0, 0)

    local margin_widget = wibox.container.margin(layout, beautiful.menu_item_margins, beautiful.menu_item_margins,
                                                        beautiful.menu_item_margins, beautiful.menu_item_margins)
    local background_widget = wibox.container.background(margin_widget)

    local index = self.items.length + 1

    background_widget:buttons(awful.util.table.join(
		awful.button({}, 1, function() self:exec() end),
        awful.button({}, 3, function() self:exec() end)
    ))

    background_widget:connect_signal("mouse::enter", function()
        self:select(index)
        if type(self.items[self.selected].cmd) == "table" then
            self:exec()
        elseif self.active_child then
            self.active_child:hide()
            self.active_child = nil
        end
    end)

    if item.create_callback then
        item.create_callback()
    end

    table.insert(
        self.items,
        {
            background_widget = background_widget,
            icon_widget = icon_widget,
            text_widget = text_widget,
            submenu_widget = submenu_widget,
            icons_normal = icons_normal,
            icons_focus = icons_focus,
            current_icon = current_icon,
            icon_submenu_normal = icon_submenu_normal,
            icon_submenu_focus = icon_submenu_focus,
            cmd = submenu or item.cmd
        }
    )
    self.items.length = index

    return background_widget
end

function popup_menu:make_popup(items)

    local item_container = {
        layout = wibox.layout.fixed.vertical
    }

    for k,v in ipairs(items) do
        item_container[k] = self:make_item(v)
    end

    local popup = awful.popup {
        widget = {
            {
                {
                    item_container,
                    layout = wibox.layout.fixed.vertical
                },
                margins = 0,
                widget  = wibox.container.margin
            },
            color = beautiful.border_normal,
            margins = beautiful.border_width,
            widget  = wibox.container.margin
        },
        visible = true,
        ontop = true
    }

    return popup
end

function popup_menu:new(items, parent)
    local pop_menu = {}
    setmetatable(pop_menu, popup_menu)

    pop_menu.items = { length = 0 }
    pop_menu.selected = -1
    pop_menu.parent = parent or nil
    pop_menu.active_child = nil
    pop_menu.popup = pop_menu:make_popup(items)
    -- this line below combined with visible = true at popup declaration is a way to compute its height and width
    -- before using show() once (fixes case when if first show() of this popup, may spawn outside the screen)
    pop_menu.popup.visible = false

    pop_menu.keygrabber = function(mod, key, event)
        if event == "release" then return end

        if key == 'Up' then
            pop_menu:select_up()
        elseif key == 'Down' then
            pop_menu:select_down()
        elseif key == 'Left' then -- close itself if is a submenu
            if pop_menu.parent then
                pop_menu:hide()
            end
        elseif key == 'Right' then -- open submenu if exists
            if pop_menu.selected ~= -1 and type(pop_menu.items[pop_menu.selected].cmd) ~= 'function' then
                pop_menu:exec()
            end
        elseif key == 'Return' then
            pop_menu:exec()
        elseif key == 'Escape' then
            pop_menu:hide()
        end
    end

    pop_menu.mousegrabber = function(mouse)
        if pop_menu:is_mouse_in_menu(mouse) then
            require('naughty').notify{text='coucou'}
            mousegrabber.stop()
            return false
        elseif mouse.buttons[1] or mouse.buttons[2] or mouse.buttons[3] then
            pop_menu:hide(true)
            mousegrabber.stop()
            return false
        else
            return true
        end
    end

    pop_menu.popup.widget:connect_signal("mouse::leave", function()
        if not mousegrabber.isrunning() and pop_menu.popup.visible then
            mousegrabber.run(pop_menu.mousegrabber, "left_ptr")
        end
    end)

    return pop_menu
end

function popup_menu:is_mouse_in_menu(mouse, recursion_direction)
    if mouse.x > self.popup.x and
    mouse.x < self.popup.x + self.popup.width and
    mouse.y > self.popup.y and
    mouse.y < self.popup.y + self.popup.height
    then
        return true
    elseif self.parent and recursion_direction ~= 'down' then
        return self.parent:is_mouse_in_menu(mouse, 'up')
    elseif self.active_child and recursion_direction ~= 'up' then
        return self.active_child:is_mouse_in_menu(mouse, 'down')
    else
        return false
    end
end

function popup_menu:update_item(n, focused)
    if n > self.items.length or n < 1 then
        return
    end

    local item = self.items[n]
    if focused then
        item.background_widget.bg = beautiful.fg_normal
        item.background_widget.fg = beautiful.bg_normal
        item.icon_widget.image = item.icons_focus[item.current_icon]
        item.submenu_widget.image = item.icon_submenu_focus
    else
        item.background_widget.bg = beautiful.bg_normal
        item.background_widget.fg = beautiful.fg_normal
        item.icon_widget.image = item.icons_normal[item.current_icon]
        item.submenu_widget.image = item.icon_submenu_normal
    end
end

function popup_menu:select(n)
    if n > self.items.length or n < 1 then
        self.selected = -1
        return
    end

    self:update_item(self.selected, false)
    self.selected = n
    self:update_item(self.selected, true)
end

function popup_menu:select_up()
    if self.selected == -1 then
        self:select(self.items.length)
        return
    end

    local n = (self.selected - 1) % (self.items.length + 1)
    if n == 0 then n = self.items.length end
    self:select(n)
end

function popup_menu:select_down()
    if self.selected == -1 then
        self:select(1)
        return
    end

    local n = (self.selected + 1) % (self.items.length + 1)
    if n == 0 then n = 1 end
    self:select(n)
end

function popup_menu:exec()
    if self.selected == -1 then return end
    if not self.items[self.selected].cmd then return end

    if type(self.items[self.selected].cmd) == 'function' then
        self.items[self.selected].cmd(self.items[self.selected])
        self:hide(true)
    else
        awful.keygrabber.stop(self.keygrabber)
        self.active_child = self.items[self.selected].cmd
        self.active_child:select(1)
        self.active_child:show()
    end
end

function popup_menu:toggle()
    if self.popup.visible then
        self:hide()
    else
        self:show()
    end
end

function popup_menu:show(x, y)
    if self.popup.visible then return end

    awful.keygrabber.run(self.keygrabber)
    -- we run mousegrabber now even if we didn't leave popup
    -- this is because when a menu is showed at mouse coordinates it is not
    -- exactly under the mouse so the mouse::leave signal is not fired
    if not mousegrabber.isrunning() then
        mousegrabber.run(self.mousegrabber, "left_ptr")
    end

    local target_x, target_y
    local screen_geo = mouse.screen.geometry

    if self.parent then
        target_x = self.parent.popup.x + self.parent.popup.width - beautiful.border_width
        if target_x + self.popup.width > screen_geo.width then
            target_x = self.parent.popup.x - (self.popup.width - beautiful.border_width)
        end
        target_y = self.parent.popup.y + (beautiful.font_height + 2 * beautiful.menu_item_margins) * (self.parent.selected - 1)
        if target_y + self.popup.height > screen_geo.height then
            target_y = screen_geo.height - self.popup.height
        end

        self.popup.x = target_x
        self.popup.y = target_y
    else
        if x and y then
            target_x = x
            target_y = y
        else
            local mouse_coords = mouse.coords()
            target_x = mouse_coords.x
            target_y = mouse_coords.y
        end

        if target_x + self.popup.width > screen_geo.width then
            self.popup.x = screen_geo.width - self.popup.width
        else
            self.popup.x = target_x
        end
        if target_y + self.popup.width > screen_geo.height then
            self.popup.y = screen_geo.height - self.popup.height + target_y - screen_geo.height
        else
            self.popup.y = target_y
        end
    end

    self.popup.visible = true
end

function popup_menu:hide(hide_parents)
    if not self.popup.visible then return end

    self.popup.visible = false
    if self.selected ~= -1 then
        self:update_item(self.selected, false)
        self.selected = -1
    end

    awful.keygrabber.stop(self.keygrabber)
    if not self.parent then
        mousegrabber.stop()
    end

    if self.active_child then
        self.active_child:hide()
        self.active_child = nil
    end
    if hide_parents and self.parent then
        self.parent:hide(hide_parents)
    elseif self.parent and self.parent.popup.visible then
        awful.keygrabber.run(self.parent.keygrabber)
    end
end

return popup_menu
