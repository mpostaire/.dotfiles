local base_panel_widget = require("widgets.panel.base")
local power_control = require("widgets.controls.power")

local icon = ""

return function()
    local widget = base_panel_widget:new{icon = icon, control_widget = power_control()}
    widget:show_label(false)

    return widget
end
