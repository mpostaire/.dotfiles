local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local capi = {mouse = mouse}

local target_client

-- TODO edit entries text based on context + move/enable to tag ? + .desktop actions

local funcs = {
    close = function() target_client:kill() end,
    toggle_maximized = function() target_client.maximized = not target_client.maximized end,
    toggle_minimized = function() target_client.minimized = not target_client.minimized end,
    toggle_floating = function() target_client.floating = not target_client.floating end,
    toggle_ontop = function() target_client.ontop = not target_client.ontop end,
    toggle_sticky = function() target_client.sticky = not target_client.sticky end
}

local mainmenu = awful.menu(
    {
        items = {
            { "close", funcs.close },
            { "maximized", funcs.toggle_maximized },
            { "minimize", funcs.toggle_minimized },
            { "floating", funcs.toggle_floating },
            { "ontop", funcs.toggle_ontop },
            { "sicky", funcs.toggle_sticky }
        }
    }
)

local function update_entries()
    mainmenu:delete(2)
    mainmenu:add({target_client.maximized and "unmaximize" or "maximize", funcs.toggle_maximized}, 2)

    mainmenu:delete(3)
    mainmenu:add({target_client.minimized and "restore" or "minimize", funcs.toggle_minimized}, 3)

    mainmenu:delete(4)
    mainmenu:add({target_client.floating and "to tiled" or "to floating", funcs.toggle_floating}, 4)

    mainmenu:delete(5)
    mainmenu:add({target_client.ontop and "don't stay ontop" or "stay ontop", funcs.toggle_ontop}, 5)

    mainmenu:delete(6)
    mainmenu:add({target_client.sticky and "make not sticky" or "make sticky", funcs.toggle_sticky}, 6)

    -- We can add custom widgets to an awful.menu !!!
    -- mainmenu:delete(7)
    -- mainmenu:add({new = function(parent, args)
    --     return {
    --         widget = wibox.widget {
    --             span_ratio = 0.8,
    --             widget = wibox.widget.separator
    --         },
    --         theme = {
    --             bg_focus = beautiful.menu_bg_normal,
    --             fg_normal = beautiful.border_normal,
    --             fg_focus = beautiful.border_normal
    --         }
    --     }
    -- end}, 7)

    -- mainmenu:delete(8)
    -- mainmenu:add({"test", function() require("naughty").notify{text = 'test'} end}, 8)
end

local background = wibox {
    x = 0,
    y = 0,
    width = capi.mouse.screen.geometry.width,
    height = capi.mouse.screen.geometry.height,
    opacity = 0,
    visible = false,
    ontop = true,
    type = 'normal'
}

background:connect_signal("button::press", function()
    background.visible = false
    mainmenu:hide()
end)

mainmenu:get_root().wibox:connect_signal("property::visible", function()
    background.visible = mainmenu:get_root().wibox.visible
end)

-- this function can't be named 'show' or 'toggle' or it causes stack overflow
function mainmenu.launch(client, shortcut)
    target_client = client
    background.visible = true

    update_entries()

    if shortcut then
        if client.titlebar_showed then
            mainmenu:show({
                coords = {
                    x = client.x + client.border_width,
                    y = client.y + beautiful.titlebar_height + client.border_width
                }
            })
        else
            mainmenu:show({
                coords = {
                    x = client.x + client.border_width,
                    y = client.y + client.border_width
                }
            })
        end
    else
        mainmenu:show()
    end
end

return mainmenu
