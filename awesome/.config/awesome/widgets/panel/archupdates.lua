local beautiful = require("beautiful")
local awful = require("awful")
local base_panel_widget = require("widgets.panel.base")

local icon = ""
local cmd = awful.util.shell.. [[
            -c "var=$(checkupdates 2>/dev/null | wc -l)
                var=$var+$(yay -Qum 2> /dev/null | wc -l)
                echo $var"
]]

return function(show_label)
    local archupdates_widget = base_panel_widget{icon = icon}

    -- if nothing specified, we show the label
    if show_label == nil then
        show_label = true
    end

    local updates, updates_aur = 0, 0

    local function get_text()
        if updates == 0 and updates_aur == 0 then
            archupdates_widget:show(false)
            return ""
        elseif updates == 0 then
            archupdates_widget:set_icon_color(beautiful.blue)
            archupdates_widget:show_icon(true)
            archupdates_widget:show_label(show_label)
            return updates_aur
        elseif updates_aur == 0 then
            archupdates_widget:set_icon_color(beautiful.fg_normal)
            archupdates_widget:show_icon(true)
            archupdates_widget:show_label(show_label)
            return updates
        else
            archupdates_widget:set_icon_color(beautiful.blue)
            archupdates_widget:show_icon(true)
            archupdates_widget:show_label(show_label)
            return updates.."+"..updates_aur
        end
    end

    awful.widget.watch(
        cmd, 1800, -- 30 minutes
        function(_, stdout)
            local s = stdout:match("[^\r\n]+")
            updates, updates_aur = s:match('(%d+)+(%d+)')

            updates = tonumber(updates)
            updates_aur = tonumber(updates_aur)

            if updates + updates_aur > 0 and archupdates_widget then
                archupdates_widget.visible = true
            elseif archupdates_widget then
                archupdates_widget.visible = false
            end

            archupdates_widget:update_label(get_text())
        end
    )

    -- invisible by default
    archupdates_widget:show(false)

    return archupdates_widget
end

-- archupdates_widget:buttons(gears.table.join(
--     awful.button({}, 1, function() notification:toggle() end),
--     awful.button({}, 2, function()
--         notification:set_markup(get_title(), "Recherche en cours...")
--         text_widget_timer:emit_signal("timeout")
--     end)
-- ))

-- local function get_message()
--     local content, suffix
--     if updates == 1 or (updates == 0 and updates_aur == 1) then
--         suffix = "mise à jour en attente"
--     else
--         suffix = "mises à jour en attente"
--     end

--     if updates == 0 and updates_aur == 0 then
--         content = "Le système est à jour"
--     elseif updates == 0 then
--         content = "Il y a " ..updates_aur.. " " ..suffix.. " venant du AUR"
--     elseif updates_aur == 0 then
--         content = "Il y a " ..updates.. " " ..suffix
--     else
--         content = "Il y a " ..updates.. " " ..suffix.. " et " ..updates_aur.. " venant du AUR"
--     end

--     return content
-- end

-- local function get_title()
--     return "<b>Mises à jour</b>"
-- end
