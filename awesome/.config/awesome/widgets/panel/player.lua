local base_panel_widget = require("widgets.panel.base")
local player_control = require("widgets.controls.player")
local mpris = require("util.mpris")

local icon = ""

return function()
    local widget = base_panel_widget{icon = icon, control_widget = player_control()}
    widget:show_label(false)

    if mpris.player_count == 0 then widget.visible = false end

    mpris.on_player_added(function(player)
        if not widget.visible then widget.visible = true end
    end)
    mpris.on_player_removed(function(player)
        if mpris.player_count == 0 then widget.visible = false end
    end)

    return widget
end
