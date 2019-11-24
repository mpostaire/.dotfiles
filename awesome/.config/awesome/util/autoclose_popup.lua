-- This is a popup that closes itself when a click outside is detected.
-- The 'spawn_button' argument is mandatory if a popup is to be launched via a mouse button (on click).
-- Do not specify 'spawn_button' if a popup is lauched without a mouse button.
-- You can change on the fly 'spawn_button' depending on the situation but you must follow these rules.

-- TODO: test variant with a transparent wibox that takes the entire screen behind the popup to capture mouse click on that wibox
--       should be a better, smarter solution (and with less bugs and strange behaviours) but maybe slower ?

local awful = require("awful")
local capi = {mousegrabber = mousegrabber}

return function(args)
    local popup = awful.popup(args)

    local just_launched = false

    local function is_mouse_in_popup(mouse)
        if mouse.x > popup.x and
            mouse.x < popup.x + popup.width and
            mouse.y > popup.y and
            mouse.y < popup.y + popup.height
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

        if is_mouse_in_popup(mouse) then
            capi.mousegrabber.stop()
            return false
        elseif mouse.buttons[1] or mouse.buttons[2] or mouse.buttons[3] then
            popup.visible = false
            capi.mousegrabber.stop()
            return false
        else
            return true
        end
    end

    popup:connect_signal("property::visible", function()
        if popup.visible then
            -- we run mousegrabber now even if we didn't leave popup
            -- this is because when a popup is showed it is not always
            -- under the mouse so the mouse::leave signal is not fired
            if not capi.mousegrabber.isrunning() then
                just_launched = true
                capi.mousegrabber.run(grabber, "left_ptr")
            end
        else
            capi.mousegrabber.stop()
        end
    end)

    popup.widget:connect_signal("mouse::leave", function()
        if not capi.mousegrabber.isrunning() and popup.visible then
            capi.mousegrabber.run(grabber, "left_ptr")
        end
    end)

    return popup
end