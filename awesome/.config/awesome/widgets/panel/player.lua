local base_panel_widget = require("widgets.panel.base")
local player_control = require("widgets.controls.player")
local mpris = require("util.mpris")

local icon = ""

return function()
    local widget = base_panel_widget{icon = icon, control_widget = player_control()}
    widget:show_label(false)

    local function determine_visibility()
        if not mpris.name then
            widget.visible = false
        elseif not widget.visible then
            widget.visible = true
        end
    end

    determine_visibility()
    mpris.on_properties_changed(determine_visibility)

    return widget
end
