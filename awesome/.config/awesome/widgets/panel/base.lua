local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")
local color = require("themes.color")
local awful = require("awful")
local dpi = require("beautiful.xresources").apply_dpi
local helpers = require("util.helpers")
local autoclose_popup = require("util.autoclose_popup")

local popup_spawn_button = 1

local function make_popup(control_widget)
    return autoclose_popup {
        widget = {
            {
                control_widget,
                margins = beautiful.notification_margin,
                widget = wibox.container.margin
            },
            color = beautiful.border_normal,
            left = beautiful.border_width,
            right = beautiful.border_width,
            bottom = beautiful.border_width,
            widget = wibox.container.margin
        },
        ontop = true,
        visible = true,
        spawn_button = popup_spawn_button
    }
end

return function(args)
    if not args then args = {} end
    local icon = args.icon
    local label = args.label
    local control_widget = args.control_widget
    local default_style = {
        padding = dpi(8),
        spacing = dpi(4),
        label_color = beautiful.fg_normal,
        icon_color = beautiful.fg_normal,
        label_font = beautiful.font,
        icon_font = beautiful.icon_font
    }
    local style = args.style or default_style

    local icon_widget = wibox.widget {
        markup = icon,
        id = "icon",
        font = style.icon_font or default_style.icon_font,
        widget = wibox.widget.textbox
    }

    local text_widget
    if type(label) == 'table' and label.widget_name and label.widget_name == 'wibox.widget.textbox' then
        text_widget = label
    else
        text_widget = wibox.widget {
            markup = label,
            id = "text",
            font = style.label_font or default_style.label_font,
            widget = wibox.widget.textbox
        }
    end

    local widget = wibox.widget {
        {
            icon_widget,
            id = "icon_margin",
            left = style.padding or default_style.padding,
            right = style.spacing or default_style.spacing,
            widget = wibox.container.margin
        },
        {
            text_widget,
            id = "text_margin",
            right = style.padding or default_style.padding,
            widget = wibox.container.margin
        },
        layout = wibox.layout.fixed.horizontal
    }

    widget.type = "panel_widget"
    widget._private.highlight = false
    widget.icon_widget = icon_widget
    widget.text_widget = text_widget
    widget._private.format = text_widget.format
    -- TODO: using crush() here may be a mistake: investigate
    widget._private.style = gears.table.crush(style, default_style)
    widget.control_widget = control_widget

    if control_widget then
        local function show_popup()
            if widget._private.popup_enabled then
                local geo = helpers.get_widget_geometry(widget)
                local screen_geo = awful.screen.focused().geometry

                if geo.x + widget.control_popup.width > screen_geo.width then
                    geo.x = screen_geo.width - widget.control_popup.width + beautiful.border_width
                end

                widget.control_popup.x = geo.x
                widget.control_popup.y = geo.y + beautiful.wibar_height - beautiful.border_width

                if widget.control_widget.show_callback then
                    widget.control_widget.show_callback()
                end

                widget.control_popup.visible = true
            end
        end

        local function toggle_popup()
            if widget.control_popup.visible then
                widget.control_popup.visible = false
            else
                show_popup()
            end
        end

        widget._private.popup_enabled = true
        control_widget.parent = widget
        widget.control_popup = make_popup(control_widget)
        -- we hide it this way because we want it to be visible by default to calculate its position
        widget.control_popup.visible = false
        widget:buttons(gears.table.join(
            awful.button({}, popup_spawn_button, toggle_popup)
        ))
    else
        widget._private.popup_enabled = false
    end

    widget._private.old_cursor, widget._private.old_wibox = nil, nil
    widget._private.mouse_enter_effect = function()
        widget:highlight(true)

        local w = _G.mouse.current_wibox
        widget._private.old_cursor, widget._private.old_wibox = w.cursor, w
        w.cursor = "hand2"
    end

    widget._private.mouse_leave_effect = function()
        widget:highlight(false)

        if widget._private.old_wibox then
            widget._private.old_wibox.cursor = widget._private.old_cursor
            widget._private.old_wibox = nil
        end
    end

    function widget:update(i, l)
        self:update_icon(i)
        self:update_label(l)
    end

    function widget:update_icon(i)
        if self._private.highlight then
            self.icon_widget:set_markup_silently('<span foreground="'..color.lighten_by(self._private.style.icon_color, 0.5)..'">'..i..'</span>')
        else
            self.icon_widget:set_markup_silently('<span foreground="'..self._private.style.icon_color..'">'..i..'</span>')
        end
    end

    function widget:update_label(l)
        if self._private.highlight then
            if self._private.format then
                self.text_widget.format = '<span foreground="'..color.lighten_by(self._private.style.label_color, 0.5)..'">'..l..'</span>'
            else
                self.text_widget:set_markup_silently('<span foreground="'..color.lighten_by(self._private.style.label_color, 0.5)..'">'..l..'</span>')
            end
        else
            if self._private.format then
                self.text_widget.format = l
            else
                self.text_widget:set_markup_silently('<span foreground="'..self._private.style.label_color..'">'..l..'</span>')
            end
        end
    end

    function widget:highlight(highlight)
        self._private.highlight = highlight
        if self.text_widget.visible then
            if self._private.format then
                self:update(self.icon_widget.text, self._private.format)
            else
                self:update(self.icon_widget.text, self.text_widget.text)
            end
        else
            self:update_icon(self.icon_widget.text)
        end
    end

    function widget:show_label(visible)
        if visible then
            self:get_children_by_id('icon_margin')[1].right = self._private.style.spacing
        else
            self:get_children_by_id('icon_margin')[1].right = 0
        end
        self.text_widget.visible = visible
    end

    function widget:show_icon(visible)
        if visible then
            self:get_children_by_id('text_margin')[1].right = self._private.style.padding
            self:get_children_by_id('icon_margin')[1].left = self._private.style.padding
        else
            self:get_children_by_id('text_margin')[1].right = 0
        end
        self.icon_widget.visible = visible
    end

    function widget:show(visible)
        local text_margin = self:get_children_by_id('text_margin')[1]
        local icon_margin = self:get_children_by_id('icon_margin')[1]

        if visible then
            text_margin.right = self._private.style.padding
            icon_margin.left = self._private.style.padding
            icon_margin.right = self._private.style.spacing
        else
            text_margin.margins = 0
            icon_margin.margins = 0
        end
        self:show_label(visible)
        self:show_icon(visible)
    end

    function widget:set_popup_enabled(popup_enabled)
        self._private.popup_enabled = popup_enabled

        if popup_enabled and not self.control_popup then
            self.control_popup = make_popup(self.control_widget)
            self.control_popup.visible = false
        elseif not popup_enabled and self.control_popup then
            self.control_popup.visible = false
        end
    end

    function widget:set_label_color(label_color)
        self._private.style.label_color = label_color
        if self._private.format then
            self:update_label(self._private.format)
        else
            self:update_label(self.text_widget.text)
        end
    end

    function widget:set_icon_color(icon_color)
        self._private.style.icon_color = icon_color
        self:update_icon(self.icon_widget.text)
    end

    function widget:set_mouse_effects(val)
        if val then
            self._private.old_cursor, self._private.old_wibox = nil, nil
            self:connect_signal("mouse::enter", self._private.mouse_enter_effect)
            self:connect_signal("mouse::leave", self._private.mouse_leave_effect)
        else
            self._private.old_cursor, self._private.old_wibox = nil, nil
            self:disconnect_signal("mouse::enter", self._private.mouse_enter_effect)
            self:disconnect_signal("mouse::leave", self._private.mouse_leave_effect)
        end
    end

    widget:set_mouse_effects(true)

    return widget
end
