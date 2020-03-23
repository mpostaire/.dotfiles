local wibox = require("wibox")
local beautiful = require("beautiful")
local gshape = require("gears.shape")

return function(args)
    if not args then args = {} end
    local handle_shape = args.handle_shape or gshape.rectangle
    local handle_color = args.handle_color or beautiful.fg_focus
    local handle_margins = args.handle_margins or 0
    local handle_width = args.handle_width or 2
    local handle_border_color = args.handle_border_color or beautiful.fg_normal
    local handle_border_width = args.handle_border_width or 0
    local bar_shape = args.bar_shape or gshape.rectangle
    local bar_height = args.bar_height or 2
    local bar_left_color = args.bar_left_color or beautiful.fg_focus
    local bar_right_color = args.bar_right_color or beautiful.fg_focus
    local bar_margins = args.bar_margins or 0
    local bar_border_width = args.bar_border_width or 0
    local bar_border_color = args.bar_border_color or beautiful.fg_normal
    local value = args.value or 0
    local minimum = args.minimum or 0
    local maximum = args.maximum or 100
    local forced_height = args.forced_height or nil
    local forced_width = args.forced_width or nil
    local opacity = args.opacity or 1
    local visible = args.visible or true

    local progressbar = wibox.widget {
        border_color = "#00000000",
        border_width = 0,
        bar_border_color = "#00000000",
        bar_border_width = 0,
        color = bar_left_color,
        background_color = bar_right_color,
        bar_shape = bar_shape,
        shape = bar_shape,
        max_value = maximum,
        margins = 0,
        paddings = 0,
        forced_height = forced_height,
        forced_width = forced_width,
        opacity = opacity,
        value = value,

        widget = wibox.widget.progressbar
    }

    local slider = wibox.widget {
        handle_shape = handle_shape,
        handle_color = handle_color,
        handle_margins = handle_margins,
        handle_width = handle_width,
        handle_border_color = handle_border_color,
        handle_border_width = handle_border_width,
        bar_shape = bar_shape,
        bar_height = bar_height,
        bar_color = "#00000000",
        bar_margins = bar_margins,
        bar_border_width = bar_border_width,
        bar_border_color = bar_border_color,
        value = value,
        minimum = minimum,
        maximum = maximum,
        forced_height = forced_height,
        forced_width = forced_width,
        opacity = opacity,
        widget = wibox.widget.slider
    }

    local layout = wibox.widget {
        {
            nil,
            {
                progressbar,
                layout = wibox.layout.fixed.vertical
            },
            nil,
            expand = "none",
            layout = wibox.layout.align.vertical
        },
        slider,
        visible = visible,
        layout = wibox.layout.stack
    }
    slider:connect_signal("property::value", function()
        progressbar.value = slider.value
    end)

    layout.handle = slider

    return layout
end
