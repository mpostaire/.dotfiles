-- This is a popup that closes itself when a click outside is detected.

local awful = require("awful")

return function(args)
    local close_callback = args.close_callback
    local mouse_free_area = args.mouse_free_area
    args.close_callback = nil
    args.mouse_free_area = nil
    local popup = awful.popup(args)

    popup.root = args.parent and args.parent.root or popup
    if popup.root == popup then
        popup.children = {}
    else
        popup.root.children[#popup.root.children + 1] = popup
    end

    local just_launched = false

    local function is_mouse_in_popup(mouse, p)
        if p.visible and mouse.x > p.x and
            mouse.x < p.x + p.width and
            mouse.y > p.y and
            mouse.y < p.y + p.height
        then
            return true
        else
            return false
        end
    end

    local function is_mouse_in_popup_or_children(mouse)
        if is_mouse_in_popup(mouse, popup.root) then
            return true
        end
        for _,v in ipairs(popup.root.children) do
            if is_mouse_in_popup(mouse, v) then
                return true
            end
        end
    end

    local function grabber(mouse)
        local should_stop = (mouse_free_area and mouse.x > mouse_free_area.x and
            mouse.x < mouse_free_area.x + mouse_free_area.width and
            mouse.y > mouse_free_area.y and
            mouse.y < mouse_free_area.y + mouse_free_area.height) or is_mouse_in_popup_or_children(mouse)

        if not mouse.buttons[1] and not mouse.buttons[2] and not mouse.buttons[3] then
            just_launched = false
        elseif not should_stop and (mouse.buttons[1] or mouse.buttons[2] or mouse.buttons[3]) and just_launched then
            return true
        end

        if should_stop then
            return false
        elseif mouse.buttons[1] or mouse.buttons[2] or mouse.buttons[3] or mouse.buttons[4] or mouse.buttons[5] then
            popup.root.visible = false
            if popup.root.children then
                for _,v in ipairs(popup.root.children) do
                    v.visible = false
                end
            end
            return false
        else
            return true
        end
    end

    if popup.root == popup then
        popup:connect_signal("property::visible", function()
            if popup.visible then
                -- we run mousegrabber now even if we didn't leave popup
                -- this is because when a popup is showed it is not always
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
            if not popup.root.visible then return end
            popup.root.visible = false
            if popup.root.children then
                for _,v in ipairs(popup.root.children) do
                    v.visible = false
                end
            end
        end)
    end

    popup.widget:connect_signal("mouse::leave", function()
        if not _G.mousegrabber.isrunning() and popup.visible then
            _G.mousegrabber.run(grabber, "left_ptr")
        end
    end)
    popup:connect_signal("property::visible", function()
        if not popup.visible then
            if close_callback then close_callback() end
        end
    end)

    popup.start_mousegrabber = function()
        if not _G.mousegrabber.isrunning() and popup.visible then
            _G.mousegrabber.run(grabber, "left_ptr")
        end
    end

    return popup
end
