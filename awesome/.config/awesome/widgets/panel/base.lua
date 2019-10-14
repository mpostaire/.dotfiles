local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")
local color = require("util.color")
local awful = require("awful")
local dpi = require("beautiful.xresources").apply_dpi
local capi = {mouse = mouse}

local base_panel_widget = {}
base_panel_widget.__index = base_panel_widget

local function make_popup(control_widget)
    return awful.popup {
        widget = {
            {
                control_widget,
                margins = beautiful.notification_margin,
                widget = wibox.container.margin
            },
            color = beautiful.border_normal,
            left = beautiful.border_width,
            bottom = beautiful.border_width,
            widget = wibox.container.margin
        },
        placement = function(d, args)
            awful.placement.top_right(d, args)
            d.y = d.y + beautiful.wibar_height - beautiful.border_width
        end,
        visible = false,
        ontop = true
    }
end

function base_panel_widget:new(icon, label, control_widget, style)
    local default_style = {
        padding = dpi(8),
        spacing = dpi(4),
        label_color = beautiful.fg_normal,
        icon_color = beautiful.fg_normal,
        label_font = beautiful.font,
        icon_font = beautiful.icon_font
    }

    if not style then
        style = default_style
    end

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
            id = "icon_margins",
            left = style.padding or default_style.padding,
            right = style.spacing or default_style.spacing,
            widget = wibox.container.margin
        },
        {
            text_widget,
            id = "text_margins",
            right = style.padding or default_style.padding,
            widget = wibox.container.margin
        },
        layout = wibox.layout.fixed.horizontal
    }
    setmetatable(widget, base_panel_widget)

    widget.type = "panel_widget"
    widget._private.highlight = false
    widget.icon_widget = icon_widget
    widget.text_widget = text_widget
    widget._private.format = text_widget.format
    -- TODO: using crush() here may be a mistake: investigate
    widget._private.style = gears.table.crush(style, default_style)
    widget.control_widget = control_widget

    if control_widget then
        widget._private.popup_enabled = true
        control_widget.parent = widget
        widget.control_popup = make_popup(control_widget)
        widget:buttons(gears.table.join(
            awful.button({}, 1, function()
                if widget._private.popup_enabled then
                    widget.control_popup.visible = not widget.control_popup.visible
                end
            end)
        ))
    else
        widget._private.popup_enabled = false
    end

    widget._private.old_cursor, widget._private.old_wibox = nil, nil
    widget._private.mouse_enter_effect = function()
        widget:highlight(true)

        local w = capi.mouse.current_wibox
        widget._private.old_cursor, widget._private.old_wibox = w.cursor, w
        w.cursor = "hand1"
    end

    widget._private.mouse_leave_effect = function()
        widget:highlight(false)

        if widget._private.old_wibox then
            widget._private.old_wibox.cursor = widget._private.old_cursor
            widget._private.old_wibox = nil
        end
    end

    widget:set_mouse_effects(true)

    return widget
end

function base_panel_widget:update(icon, label)
    self:update_icon(icon)
    self:update_label(label)
end

function base_panel_widget:update_icon(icon)
    if self._private.highlight then
        self.icon_widget:set_markup_silently('<span foreground="'..color.lighten_by(self._private.style.icon_color, 0.5)..'">'..icon..'</span>')
    else
        self.icon_widget:set_markup_silently('<span foreground="'..self._private.style.icon_color..'">'..icon..'</span>')
    end
end

function base_panel_widget:update_label(label)
    if self._private.highlight then
        if self._private.format then
            self.text_widget.format = '<span foreground="'..color.lighten_by(self._private.style.label_color, 0.5)..'">'..label..'</span>'
        else
            self.text_widget:set_markup_silently('<span foreground="'..color.lighten_by(self._private.style.label_color, 0.5)..'">'..label..'</span>')
        end
    else
        if self._private.format then
            self.text_widget.format = label
        else
            self.text_widget:set_markup_silently('<span foreground="'..self._private.style.label_color..'">'..label..'</span>')
        end
    end
end

function base_panel_widget:highlight(highlight)
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

function base_panel_widget:show_label(visible)
    if visible then
        self:get_children_by_id('icon_margins')[1].right = self._private.style.spacing
    else
        self:get_children_by_id('icon_margins')[1].right = 0
    end
    self.text_widget.visible = visible
end

function base_panel_widget:set_popup_enabled(popup_enabled)
    self._private.popup_enabled = popup_enabled

    if popup_enabled and not self.control_popup then
        self.control_popup = make_popup(self.control_widget)
    end
end

function base_panel_widget:set_label_color(label_color)
    self._private.style.label_color = label_color
    if self._private.format then
        self:update_label(self._private.format)
    else
        self:update_label(self.text_widget.text)
    end
end

function base_panel_widget:set_icon_color(icon_color)
    self._private.style.icon_color = icon_color
    self:update_icon(self.icon_widget.text)
end

function base_panel_widget:set_mouse_effects(val)
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

return base_panel_widget
