local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")
local color = require("util.color")
local dpi = require("beautiful.xresources").apply_dpi
local capi = {mouse = mouse}

local base_panel_widget = {}
base_panel_widget.__index = base_panel_widget

function base_panel_widget:new(icon, label, style)
    local default_style = {
        padding = dpi(8),
        spacing = dpi(4),
        label_color = beautiful.fg_normal,
        icon_color = beautiful.fg_normal,
        label_font = beautiful.font,
        icon_font = "Material Icons 12"
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

    local text_widget = wibox.widget {
        markup = label,
        id = "text",
        font = style.label_font or default_style.label_font,
        widget = wibox.widget.textbox
    }

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
    widget._private.style = gears.table.crush(style, default_style)

    return widget
end

function base_panel_widget:update(icon, label)
    if self._private.highlight then
        self.icon_widget:set_markup_silently('<span foreground="'..color.lighten_by(self._private.style.icon_color, 0.5)..'">'..icon..'</span>')
        self.text_widget:set_markup_silently('<span foreground="'..color.lighten_by(self._private.style.label_color, 0.5)..'">'..label..'</span>')
    else
        self.icon_widget:set_markup_silently('<span foreground="'..self._private.style.icon_color..'">'..icon..'</span>')
        self.text_widget:set_markup_silently('<span foreground="'..self._private.style.label_color..'">'..label..'</span>')
    end
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
        self.text_widget:set_markup_silently('<span foreground="'..color.lighten_by(self._private.style.label_color, 0.5)..'">'..label..'</span>')
    else
        self.text_widget:set_markup_silently('<span foreground="'..self._private.style.label_color..'">'..label..'</span>')
    end
end

function base_panel_widget:highlight(highlight)
    self._private.highlight = highlight
    if self.text_widget.visible then
        self:update(self.icon_widget.text, self.text_widget.text)
    else
        self:update_icon(self.icon_widget.text)
    end
end

function base_panel_widget:set_label_visible(visible)
    self.text_widget.visible = visible
    self:get_children_by_id('icon_margins')[1].right = 0
end

function base_panel_widget:set_label_color(label_color)
    self._private.style.label_color = label_color
    self:update_label(self.text_widget.text)
end

function base_panel_widget:set_icon_color(icon_color)
    self._private.style.icon_color = icon_color
    self:update_icon(self.icon_widget.text)
end

function base_panel_widget:enable_mouse_hover_effects(on_click, on_hover)
    if not on_click and not on_hover then
        on_click, on_hover = true, true
    end

    self._private.old_cursor, self._private.old_wibox = nil, nil
    self:connect_signal("mouse::enter", function()
        if on_hover then
            self:highlight(true)
        end

        if on_click then
            local w = capi.mouse.current_wibox
            self._private.old_cursor, self._private.old_wibox = w.cursor, w
            w.cursor = "hand1"
        end
    end)

    self:connect_signal("mouse::leave", function()
        if on_hover then
            self:highlight(false)
        end

        if on_click then
            if self._private.old_wibox then
                self._private.old_wibox.cursor = self._private.old_cursor
                self._private.old_wibox = nil
            end
        end
    end)
end

return base_panel_widget
