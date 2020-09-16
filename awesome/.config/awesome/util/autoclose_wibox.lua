-- This is a wibox that closes itself when a click outside is detected.
-- The 'spawn_button' argument is mandatory if a wibox is to be launched via a mouse button (on click).
-- Do not specify 'spawn_button' if a wibox is lauched without a mouse button.
-- You can change on the fly 'spawn_button' depending on the situation but you must follow these rules.

local wibox = require("wibox")

return function(args)
    local close_callback = args.close_callback
    args.close_callback = nil
    local w = wibox(args)

    local just_launched = false

    local function is_mouse_in_wibox(mouse)
        if mouse.x > w.x and
            mouse.x < w.x + w.width and
            mouse.y > w.y and
            mouse.y < w.y + w.height
        then
            return true
        else
            return false
        end
    end

    local function grabber(mouse)
        if not args.spawn_button or not mouse.buttons[args.spawn_button] then
            just_launched = false
        elseif mouse.buttons[args.spawn_button] and just_launched then
            return true
        end

        if is_mouse_in_wibox(mouse) then
            return false
        elseif mouse.buttons[1] or mouse.buttons[2] or mouse.buttons[3] or mouse.buttons[4] or mouse.buttons[5] then
            w.visible = false
            return false
        else
            return true
        end
    end

    w:connect_signal("property::visible", function()
        if w.visible then
            -- we run mousegrabber now even if we didn't leave wibox
            -- this is because when a wibox is showed it is not always
            -- under the mouse so the mouse::leave signal is not fired
            if not _G.mousegrabber.isrunning() then
                just_launched = true
                _G.mousegrabber.run(grabber, "left_ptr")
            end
        else
            _G.mousegrabber.stop()
            if close_callback then close_callback() end
        end
    end)

    w:connect_signal("mouse::leave", function()
        if not _G.mousegrabber.isrunning() and w.visible then
            _G.mousegrabber.run(grabber, "left_ptr")
        end
    end)

    _G.awesome.connect_signal("lock", function()
        w.visible = false
    end)

    return w
end
