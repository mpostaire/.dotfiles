local theme_assets = require("beautiful.theme_assets")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local gears = require("gears")
local naughty = require("naughty")
local awful = require("awful")
local color = require("themes.util.color")
local beautiful = require("beautiful")
local variables = require("config.variables")
local gfs = require("gears.filesystem")
local themes_path = gfs.get_configuration_dir().."themes/"

require("themes.util.wallpaper").set("~/Images/dog.jpeg", "fit")

local theme = {}

theme.accent = color.blue

theme.font          = "DejaVu Sans Mono 10"
theme.nerd_font     = "DejaVuSansMono Nerd Font 10"
theme.icon_font     = "Suru-Icons 12"

theme.bg_normal     = color.bg
theme.bg_focus      = color.black
theme.bg_urgent     = color.yellow
theme.bg_minimize   = color.black

theme.fg_normal     = color.fg
theme.fg_focus      = color.white
theme.fg_urgent     = color.black
theme.fg_minimize   = color.true_white

theme.prompt_fg_cursor = theme.bg_normal
theme.prompt_bg_cursor = theme.fg_normal

theme.gap_single_client = false
theme.maximized_hide_border = true
theme.fullscreen_hide_border = true
theme.column_count = 1
-- theme.useless_gap   = dpi(10)
theme.useless_gap   = dpi(0)
theme.border_width  = dpi(2)
--
theme.border_normal = color.black
theme.border_focus  = theme.accent
theme.border_marked = "#91231c"

-- {{{ taglist
theme.taglist_fg_focus = theme.accent
theme.taglist_fg_occupied = color.fg
theme.taglist_fg_empty = color.fg
theme.taglist_fg_urgent = color.yellow_alt

theme.taglist_bg_focus = color.bg
theme.taglist_bg_occupied = color.bg
theme.taglist_bg_empty = color.bg
theme.taglist_bg_urgent = color.bg
-- }}}

-- {{{ titlebar
theme.titlebar_bg_normal = theme.border_normal
theme.titlebar_bg_focus = theme.border_focus

theme.titlebar_fg_normal = theme.fg_normal
theme.titlebar_fg_focus = theme.fg_focus
-- }}}

-- {{{ snap
theme.snap_bg = color.yellow_alt
theme.snap_shape = gears.shape.rectangle
theme.snap_border_width = dpi(3)
-- }}}

-- {{{ notifications
theme.notification_border_width = theme.border_width
theme.notification_border_color = theme.border_normal
theme.notification_margin = dpi(20)
theme.notification_icon_size = dpi(64)
theme.notification_max_width = dpi(512)
theme.notification_max_height = dpi(128)
theme.notification_spacing = dpi(4)
-- these parameters needs to be manually overwritten as of now
naughty.config.defaults.margin = theme.notification_margin
naughty.config.defaults.border_width = theme.border_width
-- }}}

-- {{{ hotkeys popup
theme.hotkeys_modifiers_fg = color.white_alt
theme.hotkeys_border_color = theme.border_normal
-- }}}

-- {{{ wibar
theme.wibar_height = dpi(32)
-- }}}

-- {{{ tasklist
-- theme.tasklist_disable_icon = true
theme.tasklist_fg_normal = theme.fg_normal
theme.tasklist_bg_normal = theme.bg_normal
theme.tasklist_fg_focus = theme.fg_focus
theme.tasklist_bg_focus = theme.bg_focus
theme.tasklist_fg_urgent = color.yellow_alt
theme.tasklist_bg_urgent = theme.bg_normal
theme.tasklist_font_urgent = "DejaVu Sans Mono Bold 10"
theme.tasklist_fg_minimize = color.white_alt
-- theme.tasklist_disable_task_name = true
-- }}}

theme.systray_icon_spacing = dpi(12)

-- theme.taglist_fg_focus = red

-- There are other variable sets
-- overriding the default one when
-- defined, the sets are:
-- taglist_[bg|fg]_[focus|urgent|occupied|empty|volatile]
-- tasklist_[bg|fg]_[focus|urgent]
-- titlebar_[bg|fg]_[normal|focus]
-- tooltip_[font|opacity|fg_color|bg_color|border_width|border_color]
-- mouse_finder_[color|timeout|animate_timeout|radius|factor]
-- prompt_[fg|bg|fg_cursor|bg_cursor|font]
-- hotkeys_[bg|fg|border_width|border_color|shape|opacity|modifiers_fg|label_bg|label_fg|group_margin|font|description_font]
-- Example:
--theme.taglist_bg_focus = "#ff0000"

-- Variables set for theming notifications:
-- notification_font
-- notification_[bg|fg]
-- notification_[width|height|margin]
-- notification_[border_color|border_width|shape|opacity]

-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
-- theme.menu_submenu_icon = themes_path.."icons/submenu.png"
-- theme.menu_checked_icon = themes_path.."icons/checked.png"
-- theme.menu_unchecked_icon = themes_path.."icons/unchecked.png"
theme.menu_checked = ''
theme.menu_unchecked = ''
theme.menu_height = dpi(25)
theme.menu_max_width = dpi(500)
theme.menu_fg_normal = theme.fg_normal
theme.menu_fg_focus = theme.bg_normal
theme.menu_fg_disabled = color.darken_by(theme.menu_fg_normal, 0.4)
theme.menu_bg_normal = theme.menu_bg_normal
theme.menu_bg_focus = theme.fg_normal
theme.menu_bg_disabled = theme.menu_bg_normal
theme.menu_border_color = theme.border_normal 
theme.menu_separator_span_ratio = 1
theme.menu_separator_thickness = dpi(1)
theme.menu_separator_spacing = dpi(0)
theme.menu_submenu_timer = 0.2
-- theme.menu_disable_icons = true

-- You can add as many variables as
-- you wish and access them by using
-- beautiful.variable in your rc.lua
--theme.bg_widget = "#cc0000"

-- -- Define the image to load
-- theme.titlebar_close_button_normal = themes_path.."icons/titlebar/close_normal.png"
-- theme.titlebar_close_button_focus  = themes_path.."icons/titlebar/close_focus.png"

-- theme.titlebar_minimize_button_normal = themes_path.."icons/titlebar/minimize_normal.png"
-- theme.titlebar_minimize_button_focus  = themes_path.."icons/titlebar/minimize_focus.png"

-- theme.titlebar_ontop_button_normal_inactive = themes_path.."icons/titlebar/ontop_normal_inactive.png"
-- theme.titlebar_ontop_button_focus_inactive  = themes_path.."icons/titlebar/ontop_focus_inactive.png"
-- theme.titlebar_ontop_button_normal_active = themes_path.."icons/titlebar/ontop_normal_active.png"
-- theme.titlebar_ontop_button_focus_active  = themes_path.."icons/titlebar/ontop_focus_active.png"

-- theme.titlebar_sticky_button_normal_inactive = themes_path.."icons/titlebar/sticky_normal_inactive.png"
-- theme.titlebar_sticky_button_focus_inactive  = themes_path.."icons/titlebar/sticky_focus_inactive.png"
-- theme.titlebar_sticky_button_normal_active = themes_path.."icons/titlebar/sticky_normal_active.png"
-- theme.titlebar_sticky_button_focus_active  = themes_path.."icons/titlebar/sticky_focus_active.png"

-- theme.titlebar_floating_button_normal_inactive = themes_path.."icons/titlebar/floating_normal_inactive.png"
-- theme.titlebar_floating_button_focus_inactive  = themes_path.."icons/titlebar/floating_focus_inactive.png"
-- theme.titlebar_floating_button_normal_active = themes_path.."icons/titlebar/floating_normal_active.png"
-- theme.titlebar_floating_button_focus_active  = themes_path.."icons/titlebar/floating_focus_active.png"

-- theme.titlebar_maximized_button_normal_inactive = themes_path.."icons/titlebar/maximized_normal_inactive.png"
-- theme.titlebar_maximized_button_focus_inactive  = themes_path.."icons/titlebar/maximized_focus_inactive.png"
-- theme.titlebar_maximized_button_normal_active = themes_path.."icons/titlebar/maximized_normal_active.png"
-- theme.titlebar_maximized_button_focus_active  = themes_path.."icons/titlebar/maximized_focus_active.png"

-- You can use your own layout icons like this:
local icon_color = theme.fg_normal
theme.layout_fairh = gears.color.recolor_image(themes_path.."icons/layouts/fairh.png", icon_color)
theme.layout_fairv = gears.color.recolor_image(themes_path.."icons/layouts/fairv.png", icon_color)
theme.layout_floating  = gears.color.recolor_image(themes_path.."icons/layouts/floating.png", icon_color)
theme.layout_magnifier = gears.color.recolor_image(themes_path.."icons/layouts/magnifier.png", icon_color)
theme.layout_max = gears.color.recolor_image(themes_path.."icons/layouts/max.png", icon_color)
theme.layout_fullscreen = gears.color.recolor_image(themes_path.."icons/layouts/fullscreen.png", icon_color)
theme.layout_tilebottom = gears.color.recolor_image(themes_path.."icons/layouts/tilebottom.png", icon_color)
theme.layout_tileleft   = gears.color.recolor_image(themes_path.."icons/layouts/tileleft.png", icon_color)
theme.layout_tile = gears.color.recolor_image(themes_path.."icons/layouts/tile.png", icon_color)
theme.layout_tiletop = gears.color.recolor_image(themes_path.."icons/layouts/tiletop.png", icon_color)
theme.layout_spiral  = gears.color.recolor_image(themes_path.."icons/layouts/spiral.png", icon_color)
theme.layout_dwindle = gears.color.recolor_image(themes_path.."icons/layouts/dwindle.png", icon_color)
theme.layout_cornernw = gears.color.recolor_image(themes_path.."icons/layouts/cornernw.png", icon_color)
theme.layout_cornerne = gears.color.recolor_image(themes_path.."icons/layouts/cornerne.png", icon_color)
theme.layout_cornersw = gears.color.recolor_image(themes_path.."icons/layouts/cornersw.png", icon_color)
theme.layout_cornerse = gears.color.recolor_image(themes_path.."icons/layouts/cornerse.png", icon_color)

-- Generate Awesome icon:
theme.awesome_icon = theme_assets.awesome_icon(
    theme.menu_height or dpi(25), theme.fg_focus, theme.bg_normal
)

-- Define the icon theme for application icons. Tries to find the current Gtk icon theme or defaults to Adwaita
local lgi = require("lgi")
local success, Gtk = pcall(lgi.require, "Gtk", "3.0")
if success then
    theme.icon_theme = Gtk.Settings.get_default()["gtk-icon-theme-name"] or "Adwaita"
end

return theme
