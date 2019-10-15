local awful = require("awful")

return function(args)
    local popup = awful.popup {
        border_width = args.border_width,
        border_color = args.border_color,
        ontop = args.ontop,
        cursor = args.cursor,
        visible = args.visible,
        opacity = args.opacity,
        type = args.type,
        x = args.x,
        y = args.y,
        width = args.width,
        height = args.height,
        screen = args.screen,
        widget = args.widget,
        shape_bounding = args.shape_bounding,
        shape_clip = args.shape_clip,
        shape_input = args.shape_input,
        bg = args.bg,
        bgimage = args.bgimage,
        fg = args.fg,
        shape = args.shape,
        input_passthrough = args.input_passthrough,
        placement = args.placement,
        preferred_positions = args.preferred_positions,
        preferred_anchors = args.preferred_anchors,
        offset = args.offset,
        hide_on_right_click = args.hide_on_right_click,
    }
    return popup
end
