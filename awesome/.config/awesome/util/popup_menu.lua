-- a popup based improved imitation of an awful menu

-- Rewrite make_item and make_popup fuction to make them object methods
-- try rewriting make_item to use more of widget declarative programming

-- make this compatible with more widgets as items (like progressbar, slider, check button, etc)

-- maybe make the align layout wrapped inside a constraint container

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

    local icon_normal, icon_focus
    if item.icon then
        icon_normal = gears.color.recolor_image(item.icon, beautiful.fg_normal)
        icon_focus = gears.color.recolor_image(item.icon, beautiful.bg_normal)

        icon_widget:set_image(icon_normal)
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
            table.insert(self.children, submenu)
            self.children.length = self.children.length + 1
        end
    end
    layout.third = wibox.container.margin(submenu_widget, beautiful.menu_item_margins, 0, 0, 0)

    local margin_widget = wibox.container.margin(layout, beautiful.menu_item_margins, beautiful.menu_item_margins,
                                                        beautiful.menu_item_margins, beautiful.menu_item_margins)
    local background_widget = wibox.container.background(margin_widget)

    local index = self.items.length + 1

    local function click()
        self:select(index)
        self:exec()
    end

    background_widget:buttons(awful.util.table.join(
		awful.button({}, 1, click),
        awful.button({}, 3, click)
    ))

    background_widget:connect_signal("mouse::enter", function()
        self:select(index)
        if type(self.items[self.selected].cmd) == "table" then
            self:exec()
        else
            for _,v in ipairs(self.children) do
                v:hide()
            end
        end
    end)

    table.insert(
        self.items,
        {
            background_widget = background_widget,
            icon_widget = icon_widget,
            text_widget = text_widget,
            submenu_widget = submenu_widget,
            icon_normal = icon_normal,
            icon_focus = icon_focus,
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
    pop_menu.children = { length = 0 }
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
        -- ajout cas si clic gauche ou droit en dehors -> hide()
        -- voir ça avec mousegrabber et mouse.is_****_mouse_button_pressed
    end

    return pop_menu
end

function popup_menu:select(n)
    if n > self.items.length or n < 1 then
        self.selected = -1
        return
    end

    if self.selected ~= -1 then
        self.items[self.selected].background_widget.bg = beautiful.bg_normal
        self.items[self.selected].background_widget.fg = beautiful.fg_normal
        self.items[self.selected].icon_widget.image = self.items[self.selected].icon_normal
        self.items[self.selected].submenu_widget.image = self.items[self.selected].icon_submenu_normal
    end
    self.selected = n
    self.items[n].background_widget.bg = beautiful.fg_normal
    self.items[n].background_widget.fg = beautiful.bg_normal
    self.items[self.selected].icon_widget.image = self.items[self.selected].icon_focus
    self.items[self.selected].submenu_widget.image = self.items[self.selected].icon_submenu_focus
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
        self.items[self.selected].cmd()
        self:hide(true)
    else
        awful.keygrabber.stop(self.keygrabber)
        self.items[self.selected].cmd:show()
    end
end

function popup_menu:toggle()
    if self.popup.visible then
        self:hide()
    else
        self:show()
    end
end

function popup_menu:show()
    if self.popup.visible then return end

    awful.keygrabber.run(self.keygrabber)

    local screen_geo = mouse.screen.geometry

    if self.parent then
        local target_x = self.parent.popup.x + self.parent.popup.width - beautiful.border_width
        if target_x + self.popup.width > screen_geo.width then
            target_x = self.parent.popup.x - (self.popup.width - beautiful.border_width)
        end
        local target_y = self.parent.popup.y + (beautiful.font_height + 2 * beautiful.menu_item_margins) * (self.parent.selected - 1)
        if target_y + self.popup.height > screen_geo.height then
            target_y = screen_geo.height - self.popup.height
        end

        self.popup.x = target_x
        self.popup.y = target_y
    else
        local mouse_coords = mouse.coords()

        if mouse_coords.x + self.popup.width > screen_geo.width then
            self.popup.x = screen_geo.width - self.popup.width
        else
            self.popup.x = mouse_coords.x
        end
        if mouse_coords.y + self.popup.width > screen_geo.height then
            self.popup.y = screen_geo.height - self.popup.height + mouse_coords.y - screen_geo.height
        else
            self.popup.y = mouse_coords.y
        end
    end

    self.popup.visible = true
end

function popup_menu:hide(hide_parents)
    if not self.popup.visible then return end

    self.popup.visible = false
    if self.selected ~= -1 then
        self.items[self.selected].background_widget.bg = beautiful.bg_normal
        self.items[self.selected].background_widget.fg = beautiful.fg_normal
        self.items[self.selected].icon_widget.image = self.items[self.selected].icon_normal
        self.items[self.selected].submenu_widget.image = self.items[self.selected].icon_submenu_normal
        self.selected = -1
    end

    awful.keygrabber.stop(self.keygrabber)

    for _,v in ipairs(self.children) do
        v:hide()
    end
    if hide_parents and self.parent then
        self.parent:hide(hide_parents)
    elseif self.parent and self.parent.popup.visible then
        awful.keygrabber.run(self.parent.keygrabber)
    end
end

return popup_menu
