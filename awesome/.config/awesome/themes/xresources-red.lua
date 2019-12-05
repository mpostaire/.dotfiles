local theme_assets = require("beautiful.theme_assets")
local xresources = require("beautiful.xresources")
local xresources_theme = xresources.get_current_theme()
local dpi = xresources.apply_dpi
local gears = require("gears")
local naughty = require("naughty")
local awful = require("awful")
local color = require("util.color")
local beautiful = require("beautiful")
local variables = require("config.variables")
local gfs = require("gears.filesystem")
local capi = {screen = screen}
local themes_path = gfs.get_configuration_dir().."themes/"

local theme = {}

-- {{{ Wallpaper
local function set_wallpaper(wallpaper_path)
    if string.sub(wallpaper_path, 1, 1) == "~" then
        wallpaper_path = variables.home .. string.sub(wallpaper_path, 2)
    end

    if gfs.file_readable(wallpaper_path) then
        theme.wallpaper = wallpaper_path
    else
        theme.wallpaper = gfs.get_themes_dir().."default/background.png"
    end

    -- sets it for each screen
    awful.screen.connect_for_each_screen(function(s)
        if theme.wallpaper then
            local wallpaper = theme.wallpaper
            -- If wallpaper is a function, call it with the screen
            if type(wallpaper) == "function" then
                wallpaper = wallpaper(s)
            end
            gears.wallpaper.maximized(wallpaper, s, true)
        end
    end)
end

set_wallpaper("~/Images/lunar_eclipse.jpg")
-- }}}

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
capi.screen.connect_signal("property::geometry", set_wallpaper)


theme.black = xresources_theme["color0"]
theme.black_alt = xresources_theme["color8"]

theme.red = xresources_theme["color1"]
theme.red_alt = xresources_theme["color9"]

theme.green = xresources_theme["color2"]
theme.green_alt = xresources_theme["color10"]

theme.yellow = xresources_theme["color3"]
theme.yellow_alt = xresources_theme["color11"]

theme.blue = xresources_theme["color4"]
theme.blue_alt = xresources_theme["color12"]

theme.magenta = xresources_theme["color5"]
theme.magenta_alt = xresources_theme["color13"]

theme.cyan = xresources_theme["color6"]
theme.cyan_alt = xresources_theme["color14"]

theme.white = xresources_theme["color7"]
theme.white_alt = xresources_theme["color15"]

theme.true_white = "#FFFFFF"

theme.font          = "DejaVu Sans Mono 10"
theme.nerd_font     = "DejaVuSansMono Nerd Font 10"
theme.icon_font     = "Suru-Icons 12"

theme.bg_normal     = theme.black
theme.bg_focus      = theme.black_alt
theme.bg_urgent     = theme.yellow
theme.bg_minimize   = theme.black
theme.bg_systray    = theme.black

theme.fg_normal     = theme.white
theme.fg_focus      = theme.true_white
theme.fg_urgent     = theme.black
theme.fg_minimize   = theme.true_white

theme.prompt_fg_cursor = theme.bg_normal
theme.prompt_bg_cursor = theme.fg_normal

theme.gap_single_client = false
theme.maximized_hide_border = true
theme.fullscreen_hide_border = true
theme.column_count = 1
-- theme.useless_gap   = dpi(10)
theme.useless_gap   = dpi(0)
theme.border_width  = dpi(2)
-- used when titlebars are showed
theme.border_normal_alt = color.darken_by(theme.black_alt, 0.5)
theme.border_focus_alt  = color.darken_by(theme.black, 0.25)
--
theme.border_normal = theme.black_alt
theme.border_focus  = theme.red
theme.border_marked = "#91231c"

-- {{{ taglist
theme.taglist_fg_focus = theme.red
theme.taglist_fg_occupied = theme.white
theme.taglist_fg_empty = theme.white_alt
theme.taglist_fg_urgent = theme.yellow

theme.taglist_bg_focus = theme.black
theme.taglist_bg_occupied = theme.black
theme.taglist_bg_empty = theme.black
theme.taglist_bg_urgent = theme.black
-- }}}

-- {{{ titlebar
theme.titlebar_bg_normal = theme.black_alt
theme.titlebar_bg_focus = theme.black

theme.titlebar_fg_normal = theme.white
theme.titlebar_fg_focus = theme.true_white
-- }}}

-- {{{ snap
theme.snap_bg = theme.yellow
theme.snap_shape = gears.shape.rectangle
theme.snap_border_width = dpi(3)
-- }}}

-- {{{ notifications
theme.notification_border_width = theme.border_width
theme.notification_margin = dpi(20)
-- these parameters needs to be manually overwritten as of now
naughty.config.defaults.margin = theme.notification_margin
naughty.config.defaults.border_width = theme.border_width
-- }}}

-- {{{ hotkeys popup
theme.hotkeys_modifiers_fg = theme.white_alt
theme.hotkeys_border_color = theme.black_alt
-- }}}

-- {{{ wibar
theme.wibar_height = dpi(32)
-- }}}

-- {{{ tasklist
-- theme.tasklist_disable_icon = true
theme.tasklist_fg_urgent = theme.yellow
theme.tasklist_bg_urgent = theme.bg_normal
theme.tasklist_font_urgent = "DejaVu Sans Mono Bold 10"
theme.tasklist_fg_minimize = theme.white_alt
-- }}}

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

-- Generate taglist squares:
local taglist_square_size = dpi(4)
theme.taglist_squares_sel = theme_assets.taglist_squares_sel(
    taglist_square_size, theme.fg_normal
)
theme.taglist_squares_unsel = theme_assets.taglist_squares_unsel(
    taglist_square_size, theme.fg_normal
)

-- Variables set for theming notifications:
-- notification_font
-- notification_[bg|fg]
-- notification_[width|height|margin]
-- notification_[border_color|border_width|shape|opacity]

-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_submenu_icon = themes_path.."icons/submenu.png"
theme.menu_submenu = '▶'
theme.menu_height = dpi(25)
theme.menu_width  = dpi(150)
theme.menu_fg_normal = theme.menu_fg_normal
theme.menu_fg_focus = theme.bg_normal
theme.menu_bg_normal = theme.menu_bg_normal
theme.menu_bg_focus = theme.fg_normal

-- You can add as many variables as
-- you wish and access them by using
-- beautiful.variable in your rc.lua
--theme.bg_widget = "#cc0000"

-- Define the image to load
theme.titlebar_close_button_normal = themes_path.."icons/titlebar/close_normal.png"
theme.titlebar_close_button_focus  = themes_path.."icons/titlebar/close_focus.png"

theme.titlebar_minimize_button_normal = themes_path.."icons/titlebar/minimize_normal.png"
theme.titlebar_minimize_button_focus  = themes_path.."icons/titlebar/minimize_focus.png"

theme.titlebar_ontop_button_normal_inactive = themes_path.."icons/titlebar/ontop_normal_inactive.png"
theme.titlebar_ontop_button_focus_inactive  = themes_path.."icons/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_active = themes_path.."icons/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_active  = themes_path.."icons/titlebar/ontop_focus_active.png"

theme.titlebar_sticky_button_normal_inactive = themes_path.."icons/titlebar/sticky_normal_inactive.png"
theme.titlebar_sticky_button_focus_inactive  = themes_path.."icons/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_active = themes_path.."icons/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_active  = themes_path.."icons/titlebar/sticky_focus_active.png"

theme.titlebar_floating_button_normal_inactive = themes_path.."icons/titlebar/floating_normal_inactive.png"
theme.titlebar_floating_button_focus_inactive  = themes_path.."icons/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_active = themes_path.."icons/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_active  = themes_path.."icons/titlebar/floating_focus_active.png"

theme.titlebar_maximized_button_normal_inactive = themes_path.."icons/titlebar/maximized_normal_inactive.png"
theme.titlebar_maximized_button_focus_inactive  = themes_path.."icons/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_active = themes_path.."icons/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_active  = themes_path.."icons/titlebar/maximized_focus_active.png"

-- You can use your own layout icons like this:
theme.layout_fairh = themes_path.."icons/layouts/fairh.png"
theme.layout_fairv = themes_path.."icons/layouts/fairv.png"
theme.layout_floating  = themes_path.."icons/layouts/floating.png"
theme.layout_magnifier = themes_path.."icons/layouts/magnifier.png"
theme.layout_max = themes_path.."icons/layouts/max.png"
theme.layout_fullscreen = themes_path.."icons/layouts/fullscreen.png"
theme.layout_tilebottom = themes_path.."icons/layouts/tilebottom.png"
theme.layout_tileleft   = themes_path.."icons/layouts/tileleft.png"
theme.layout_tile = themes_path.."icons/layouts/tile.png"
theme.layout_tiletop = themes_path.."icons/layouts/tiletop.png"
theme.layout_spiral  = themes_path.."icons/layouts/spiral.png"
theme.layout_dwindle = themes_path.."icons/layouts/dwindle.png"
theme.layout_cornernw = themes_path.."icons/layouts/cornernw.png"
theme.layout_cornerne = themes_path.."icons/layouts/cornerne.png"
theme.layout_cornersw = themes_path.."icons/layouts/cornersw.png"
theme.layout_cornerse = themes_path.."icons/layouts/cornerse.png"

-- Generate Awesome icon:
theme.awesome_icon = theme_assets.awesome_icon(
    theme.menu_height, theme.fg_focus, theme.bg_normal
)

-- {{{ User defined variables (use search to figure out what they do)
theme.border_width_single_client = dpi(0)
theme.wibar_widgets_padding = dpi(8)
theme.wibar_border_color = theme.black_alt
theme.widgets_inner_padding = dpi(4)
theme.wibar_bottom_border_width = theme.border_width
theme.notification_offset = dpi(4)
theme.font_height = beautiful.get_font_height(theme.font)
theme.awesome_icon_wibar = theme_assets.awesome_icon(
    theme.wibar_height - theme.wibar_bottom_border_width, theme.true_white, theme.red
)
theme.titlebar_height = theme.wibar_height

theme.menu_item_margins = dpi(5)

theme.fg_normal_hover = color.lighten_by(theme.fg_normal, 0.5)
theme.white_alt_hover = color.lighten_by(theme.white_alt, 0.25)
theme.red_hover = color.lighten_by(theme.red, 0.25)
theme.yellow_hover = color.lighten_by(theme.yellow, 0.25)
-- }}}

-- Define the icon theme for application icons. If not set then the icons
-- from /usr/share/icons and /usr/share/icons/hicolor will be used.
-- // TODO make this find icon theme automatically
theme.icon_theme = "Papirus Red"

return theme

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
