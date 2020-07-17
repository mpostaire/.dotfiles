local base_panel_widget = require("widgets.panel.base")
local player_control = require("widgets.controls.player")

local icon = ""

return function()
    local widget = base_panel_widget{icon = icon, control_widget = player_control()}
    widget:show_label(false)

    return widget
end
