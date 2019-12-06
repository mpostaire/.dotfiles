local wibox = require("wibox")

return function()
    local network_widget = wibox.widget {
        text = "network WIP",
        widget = wibox.widget.textbox
    }

    network_widget.type = "control_widget"

    return network_widget
end
