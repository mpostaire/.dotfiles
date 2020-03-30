local wibox = require("wibox")
local network = require("util.network")

return function()
    if not network.enabled then return nil end

    local network_widget = wibox.widget {
        text = "network WIP",
        widget = wibox.widget.textbox
    }

    network_widget.type = "control_widget"

    return network_widget
end
