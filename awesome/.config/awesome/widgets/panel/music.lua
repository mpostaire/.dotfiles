-- local wibox = require("wibox")
-- local beautiful = require("beautiful")
-- local awful = require("awful")
-- local variables= require("config.variables")
-- local gears = require("gears")
-- local naughty = require("naughty")
-- local mpris = require("util.mpris")
-- local player = require("popups.player")

-- local icon = ""

-- -- local function us_to_hms(useconds)
-- --     local seconds = tonumber(useconds) / 1000000

-- --     local h = math.floor((seconds % 86400) / 3600)
-- --     local m = math.floor((seconds % 3600) / 60)
-- --     local s = gears.math.round(seconds % 60)
-- --     if h <= 0 then
-- --         return string.format("%02d:%02d", m, s)
-- --     else
-- --         return string.format("%02d:%02d:%02d", h, m, s)
-- --     end
-- -- end

-- local icon_widget = wibox.widget {
--     {
--         markup = icon,
--         id = "icon",
--         font = "Material Icons 12",
--         widget = wibox.widget.textbox
--     },
--     widget = wibox.container.margin(_, beautiful.wibar_widgets_padding, beautiful.widgets_inner_padding, 0, 0)
-- }

-- local text_widget = wibox.widget {
--     {
--         markup = "Musique",
--         id = "text",
--         widget = wibox.widget.textbox
--     },
--     widget = wibox.container.margin(_, 0, beautiful.wibar_widgets_padding, 0, 0)
-- }

-- local music_widget = wibox.widget {
--     icon_widget,
--     text_widget,
--     layout = wibox.layout.fixed.horizontal
-- }

-- local function get_icon(mouse_hover)
--     if mouse_hover then
--         return '<span foreground="'..beautiful.fg_normal_hover..'">'..icon..'</span>'
--     else
--         return icon
--     end
-- end

-- local function get_text(mouse_hover)
--     local metadata = mpris.Metadata

--     if mouse_hover then
--         return '<span foreground="'..beautiful.fg_normal_hover..'">'..metadata["xesam:title"]..'</span>'
--     else
--         return metadata["xesam:title"]
--     end
-- end

-- local function update_widget()
--     icon_widget:get_children_by_id('icon')[1]:set_markup_silently(get_icon())
--     text_widget:get_children_by_id('text')[1]:set_markup_silently(get_text())
-- end
-- update_widget()

-- local notification_id
-- mpris:on_properties_changed(function (p, changed, invalidated)
--     assert(p == mpris)
--     update_widget()
--     if notification_id then
--         naughty.notify{title="Musique", text=p.Metadata["xesam:title"], replaces_id = notification_id}
--     else
--         notification_id = naughty.notify{title="Musique", text=p.Metadata["xesam:title"]}
--     end
-- end)

-- local old_cursor, old_wibox
-- music_widget:connect_signal("mouse::enter", function()
--     -- mouse_hover color highlight
--     icon_widget:get_children_by_id('icon')[1]:set_markup_silently(get_icon(true))
--     text_widget:get_children_by_id('text')[1]:set_markup_silently(get_text(true))

--     local w = mouse.current_wibox
--     old_cursor, old_wibox = w.cursor, w
--     w.cursor = "hand1"
-- end)
-- music_widget:connect_signal("mouse::leave", function()
--     -- no mouse_hover color highlight
--     icon_widget:get_children_by_id('icon')[1]:set_markup_silently(get_icon())
--     text_widget:get_children_by_id('text')[1]:set_markup_silently(get_text())

--     if old_wibox then
--         old_wibox.cursor = old_cursor
--         old_wibox = nil
--     end
-- end)

-- music_widget:buttons(gears.table.join(
--     awful.button({}, 1, player.toggle_menu)
-- ))

-- local widget_keys = gears.table.join(
--     awful.key({ variables.modkey }, "m", player.toggle_menu,
--     {description = "show the music menu", group = "launcher"}),
--     awful.key({ "Control" }, "KP_Divide", function() mpris:PlayPause() end,
--     {description = "music player pause", group = "multimedia"}),
--     awful.key({ "Control" }, "KP_Right", function() mpris:Next() end,
--     {description = "music player next song", group = "multimedia"}),
--     awful.key({ "Control" }, "KP_Left", function() mpris:Previous() end,
--     {description = "music player previous song", group = "multimedia"}),
--     awful.key({ "Control" }, "KP_Begin", function() mpris:Stop() end,
--     {description = "music player stop", group = "multimedia"})
-- )

-- root.keys(gears.table.join(root.keys(), widget_keys))

-- return music_widget
