-- This is a wibox that closes itself when a click outside is detected.

local wibox = require("wibox")

return function(args)
    local close_callback = args.close_callback
    args.close_callback = nil
    local w = wibox(args)

    w.root = args.parent and args.parent.root or w
    if w.root == w then
        w.children = {}
    else
        w.root.children[#w.root.children + 1] = w
    end

    local just_launched = false

    local function is_mouse_in_wibox(mouse, wb)
        if wb.visible and mouse.x > wb.x and
            mouse.x < wb.x + wb.width and
            mouse.y > wb.y and
            mouse.y < wb.y + wb.height
        then
            return true
        else
            return false
        end
    end

    local function is_mouse_in_wibox_or_children(mouse)
        if is_mouse_in_wibox(mouse, w.root) then
            return true
        end
        for _,v in ipairs(w.root.children) do
            if is_mouse_in_wibox(mouse, v) then
                return true
            end
        end
    end

    local function grabber(mouse)
        local should_stop = is_mouse_in_wibox_or_children(mouse)

        if not mouse.buttons[1] and not mouse.buttons[2] and not mouse.buttons[3] then
            just_launched = false
        elseif not should_stop and (mouse.buttons[1] or mouse.buttons[2] or mouse.buttons[3]) and just_launched then
            return true
        end

        if should_stop then
            return false
        elseif mouse.buttons[1] or mouse.buttons[2] or mouse.buttons[3] or mouse.buttons[4] or mouse.buttons[5] then
            w.root.visible = false
            if w.root.children then
                for _,v in ipairs(w.root.children) do
                    v.visible = false
                end
            end
            return false
        else
            return true
        end
    end

    if w.root == w then
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
            end
        end)

        _G.awesome.connect_signal("lock", function()
            if not w.root.visible then return end
            w.root.visible = false
            if w.root.children then
                for _,v in ipairs(w.root.children) do
                    v.visible = false
                end
            end
        end)
    end

    w:connect_signal("mouse::leave", function()
        if not _G.mousegrabber.isrunning() and w.visible then
            _G.mousegrabber.run(grabber, "left_ptr")
        end
    end)
    w:connect_signal("property::visible", function()
        if not w.visible then
            if close_callback then close_callback() end
        end
    end)

    return w
end
