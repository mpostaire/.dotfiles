local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("util.helpers")

-- // TODO make this a notification center (this is a placeholder for now)

local icon = ""

return function()
    local notifcenter = wibox.widget {
        {
            {
                markup = '<span foreground="'..beautiful.white_alt..'">'..icon..'</span>',
                font = helpers.change_font_size(beautiful.nerd_font, 28),
                align = "center",
                widget = wibox.widget.textbox
            },
            {
                markup = '<span foreground="'..beautiful.white_alt..'">Aucune notification</span>',
                align = "center",
                widget = wibox.widget.textbox
            },
            layout = wibox.layout.fixed.vertical
        },
        valign = "center",
        widget = wibox.container.place
    }

    notifcenter.type = "control_widget"

    return notifcenter
end
