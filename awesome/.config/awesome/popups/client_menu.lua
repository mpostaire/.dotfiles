local beautiful = require("beautiful")
local awful = require("awful")
local popup_menu = require("util.popup_menu")

local client_menu = {}

client_menu.target_client = nil

local function make_tag_menu()
    local tags = awful.screen.focused().tags
    local menu = {}

    local layouts_icons = {}
    for _,v in ipairs(awful.layout.layouts) do
        layouts_icons[v.name] = beautiful["layout_".. v.name]
    end

    for k,v in ipairs(tags) do
        menu[k] = {
            icons = layouts_icons,
            current_icon = v.layout.name,
            text = v.name,
            cmd = function() client_menu.target_client:move_to_tag(v) end,
            create_callback = function() end
        }
    end
    return menu
end

-- update tag layout icon in 'move to tag' submenu on tag layout change
tag.connect_signal("property::layout", function(t)
    local tagmenu = client_menu.menu.items[#client_menu.menu.items].cmd
    tagmenu.items[t.index].current_icon = t.layout.name
    tagmenu:update_item(t.index, false)
end)

client_menu.menu = popup_menu:new(
    {
        {
            icons = {beautiful.titlebar_close_button_normal},
            text = "close",
            cmd = function() client_menu.target_client:kill() end
        },
        {
            icons = {
                inactive = beautiful.titlebar_maximized_button_normal_inactive,
                active = beautiful.titlebar_maximized_button_normal_active,
            },
            text = "maximized",
            cmd = function() client_menu.target_client.maximized = not client_menu.target_client.maximized end
        },
        {
            icons = {beautiful.titlebar_minimize_button_normal},
            text = "minimize",
            cmd = function() client_menu.target_client.minimized = not client_menu.target_client.minimized end
        },
        {
            icons = {
                inactive = beautiful.titlebar_floating_button_normal_inactive,
                active = beautiful.titlebar_floating_button_normal_active
            },
            text = "floating",
            cmd = function() client_menu.target_client.floating = not client_menu.target_client.floating end
        },
        {
            icons = {
                inactive = beautiful.titlebar_ontop_button_normal_inactive,
                active = beautiful.titlebar_ontop_button_normal_active
            },
            text = "ontop",
            cmd = function() client_menu.target_client.ontop = not client_menu.target_client.ontop end
        },
        {
            icons = {
                inactive = beautiful.titlebar_sticky_button_normal_inactive,
                active = beautiful.titlebar_sticky_button_normal_active
            },
            text = "sticky",
            cmd = function() client_menu.target_client.sticky = not client_menu.target_client.sticky end
        },
        {
            text = "move to tag",
            cmd = make_tag_menu()
        }
    }
)

function client_menu.hide()
    client_menu.menu:hide()
end

function client_menu.show(client)
    client_menu.menu:hide()
    client_menu.target_client = client
    client_menu.update_items()
    client_menu.menu:show()
end

function client_menu.update_items()
    for k,v in ipairs(client_menu.menu.items) do
        if v.text_widget.text == 'maximized' or v.text_widget.text == 'not maximized' then
            if client_menu.target_client.maximized then
                v.text_widget.text = 'maximized'
                v.current_icon = 'active'
            else
                v.text_widget.text = 'not maximized'
                v.current_icon = 'inactive'
            end
        elseif v.text_widget.text == 'floating' or v.text_widget.text == 'tiled' then
            if client_menu.target_client.floating then
                v.text_widget.text = 'floating'
                v.current_icon = 'active'
            else
                v.text_widget.text = 'tiled'
                v.current_icon = 'inactive'
            end
        elseif v.text_widget.text == 'ontop' or v.text_widget.text == 'not ontop' then
            if client_menu.target_client.ontop then
                v.text_widget.text = 'ontop'
                v.current_icon = 'active'
            else
                v.text_widget.text = 'not ontop'
                v.current_icon = 'inactive'
            end
        elseif v.text_widget.text == 'sticky' or v.text_widget.text == 'not sticky' then
            if client_menu.target_client.sticky then
                v.text_widget.text = 'sticky'
                v.current_icon = 'active'
            else
                v.text_widget.text = 'not sticky'
                v.current_icon = 'inactive'
            end
        end
        client_menu.menu:update_item(k, false)
    end
end

return client_menu
