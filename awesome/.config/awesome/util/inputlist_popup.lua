local awful = require("awful")
local beautiful = require("beautiful")
local color = require("themes.util.color")
local wibox = require("wibox")
local helpers = require("util.helpers")
local prompt = require("util.prompt")
local autoclose_wibox = require("util.autoclose_wibox")

local function default_query_filter(query, items)
    if not query then query = "" end
    query = helpers.replace_special_chars(helpers.trim(query)):lower()
    
    local ret = {}
    
    for _,item in ipairs(items) do
        local comment = item.Comment and item.Comment or ""
        -- match when we find query in either one of the item Name or Comment
        local match = helpers.replace_special_chars(item.Name):lower():find(query) or
                      helpers.replace_special_chars(comment):lower():find(query)
        if match then
            table.insert(ret, item)
        end
    end

    return ret
end

return function(args)
    local items = args.items or {}
    args.items = nil

    local popup = autoclose_wibox {
        ontop = true,
        type = "normal",
        close_callback = prompt.stop
    }
    popup._private = {}
    
    local prompt_textbox = wibox.widget.textbox()
    prompt_textbox.forced_height = beautiful.get_font_height(beautiful.font)
    
    -- how many items scrolled per scroll
    local scrollbar_velocity = 1 -- FIXME this
    
    local function build_popup(args)
        if not args then args = {} end
        local prompt_spacing = args.prompt_spacing or 15
        local scrollbar_spacing = args.scrollbar_spacing or 10
        local width = args.width or 250
        local height = args.height or _G.mouse.screen.geometry.height
        local x = args.x or 0
        local y = args.y or 0
        local icon_size = args.icon_size or 32
        local margins = args.margins or 25
        local item_margins = args.item_margins or 2
        local icon_spacing = args.icon_spacing or 4
        local left_border = args.left_border or 2
        local right_border = args.right_border or 2
        local top_border = args.top_border or 2
        local bottom_border = args.bottom_border or 2
        local query_filter = args.query_filter or default_query_filter
        local exe_callback = args.exe_callback or nil
    
        local prompt_height = prompt_textbox.forced_height + prompt_spacing
        local item_height = icon_size + 2 * item_margins
        local max_showed_item_count = math.floor((height - 2 * margins - prompt_height) / item_height)
        local layout_height = icon_size * max_showed_item_count
    
        local scrollbar = wibox.widget {
            bar_color = color.bg,
            handle_color = beautiful.bg,
            value = 0,
            forced_height = 10,
            forced_width = 0,
            widget = wibox.widget.slider
        }
    
        local scrollbar_container = wibox.widget {
            scrollbar,
            direction = 'west',
            widget = wibox.container.rotate
        }
    
        local filtered_items, item_count = items, #items
        local icon_placeholder = wibox.container.margin()
        icon_placeholder.left = icon_size
        local icon_widgets = {}
    
        local items_container = wibox.layout.fixed.vertical()
        local selected_widget = 1
        local function select_widget(index)
            -- If index ~= 0 and there is no item at index position, it means this item just got cleared.
            -- We iterate backwards until we find the index of the last item.
            if index ~= 0 and not items_container.children[index].position_index then
                local temp = index
                index = 0
                for i = temp, 1, -1 do
                    if items_container.children[i].position_index then
                        index = i
                        break
                    end
                end
            end

            -- If selected_widget ~= 0 here, it means we have to render it has unselected (because it is the old selected widget
            -- as we didn't do selected_widget = index yet).
            if selected_widget ~= 0 then
                local item_background = items_container.children[selected_widget]
                item_background.bg = beautiful.bg_normal
                item_background.fg = beautiful.fg_normal
                local comment_textbox = items_container.children[selected_widget].widget.widget.second.children[2]
                comment_textbox.markup = '<i><span foreground="'..color.black_alt..'">'..comment_textbox.text..'</span></i>'
            end
    
            -- we mark the new selected_widget as the index
            selected_widget = index
    
            -- If selected_widget ~= 0 here, it means either the new index was a valid item, or we just got the last valid item index.
            -- We render it as selected.
            if selected_widget ~= 0 then
                local item_background = items_container.children[selected_widget]
                item_background.bg = beautiful.fg_normal
                item_background.fg = beautiful.bg_normal
                local comment_textbox = items_container.children[selected_widget].widget.widget.second.children[2]
                comment_textbox.markup = '<i><span foreground="'..beautiful.bg_normal..'">'..comment_textbox.text..'</span></i>'
            end
        end
    
        local comment_font = helpers.change_font_size(beautiful.font, 9)
        for i = 1, max_showed_item_count do
            table.insert(icon_widgets, wibox.widget.imagebox())
            local widget = wibox.widget {
                {
                    {
                        {
                            icon_widgets[i],
                            right = icon_spacing,
                            widget = wibox.container.margin
                        },
                        {
                            {
                                align = 'left',
                                widget = wibox.widget.textbox
                            },
                            {
                                align = 'left',
                                font = comment_font,
                                widget = wibox.widget.textbox
                            },
                            layout = wibox.layout.flex.vertical
                        },
                        nil,
                        forced_height = icon_size,
                        layout = wibox.layout.align.horizontal
                    },
                    margins = item_margins,
                    widget = wibox.container.margin
                },
                widget = wibox.container.background
            }
            widget:buttons({
                awful.button({}, 1, function()
                    if not widget.position_index then return end
                    if selected_widget ~= i then select_widget(i) return end
                    if popup._private.exe_callback then popup._private.exe_callback(popup._private.get_selected_item()) end
                    prompt.stop()
                    popup._private.hide()
                end)
            })
            widget:connect_signal("mouse::enter", function()
                if widget.position_index then select_widget(i) end
            end)
            items_container:add(widget)
        end
    
        local function scroll_layout_contents()
            if scrollbar.maximum == 1 then return end
    
            for i = 1, max_showed_item_count do
                local item = filtered_items[scrollbar.value + i]
                local item_widget_background = items_container.children[i]
                local item_widget = item_widget_background.widget.widget
                if item.Icon then
                    item_widget.first.widget = icon_widgets[i]
                    icon_widgets[i].image = item.Icon
                else
                    item_widget.first.widget = icon_placeholder
                end
                local name_comment_textboxes = item_widget.second
                name_comment_textboxes.children[1].text = item.Name
                local comment = item.Comment and item.Comment or ""
                if i == selected_widget then
                    name_comment_textboxes.children[2].markup = '<i><span foreground="'..beautiful.bg_normal..'">'..comment..'</span></i>'
                else
                    name_comment_textboxes.children[2].markup = '<i><span foreground="'..color.black_alt..'">'..comment..'</span></i>'
                end
                item_widget_background.position_index = scrollbar.value + i
            end
        end
   
        local old_query
        local function update_items(query)
            if not query then query = "" end
            if old_query and old_query == query then return end
            old_query = query
    
            item_count = 0
            local count = 1
            if query == "" then
                filtered_items = items
            else
                filtered_items = query_filter(query, items)
            end
    
            -- populate first widgets with filtered data
            for _,item in ipairs(filtered_items) do
                item_count = item_count + 1
                if count <= max_showed_item_count then
                    local item_widget_background = items_container.children[count]
                    local item_widget = item_widget_background.widget.widget
                    local item_widget_first = item_widget.first
                    if item.Icon then
                        item_widget_first.widget = icon_widgets[count]
                        item_widget_first.widget.image = item.Icon
                    else
                        item_widget_first.widget = icon_placeholder
                    end
                    local item_widget_second = item_widget.second
                    item_widget_second.children[1].text = item.Name
                    local comment = item.Comment and item.Comment or ""
                    if count == selected_widget then
                        item_widget_second.children[2].markup = '<i><span foreground="'..beautiful.bg_normal..'">'..comment..'</span></i>'
                    else
                        item_widget_second.children[2].markup = '<i><span foreground="'..color.black_alt..'">'..comment..'</span></i>'
                    end
                    item_widget_background.position_index = count
                    item_widget_background.item = item
                    count = count + 1
                end
            end
            
            -- then clear following widgets if needed
            for i = count, max_showed_item_count do
                local item_widget_background = items_container.children[i]
                local item_widget = item_widget_background.widget.widget
                item_widget.first.widget = nil
                item_widget.second.children[1].text = ""
                item_widget.second.children[2].markup = ""
                item_widget_background.item = nil
                item_widget_background.position_index = nil
            end
            
            -- if selected_widget was 0, attempt to select 1
            -- else if selected_widget was cleared, select the last showed instead or none
            if selected_widget == 0 then
                select_widget(1)
            elseif not items_container.children[selected_widget].position_index then
                select_widget(count - 1)
            end
    
            scrollbar.maximum = math.max((item_count - max_showed_item_count) / scrollbar_velocity, 1)
            scrollbar.handle_width = (max_showed_item_count / item_count) * layout_height
            scrollbar_container.widget.handle_color = scrollbar.maximum > 1 and color.fg or color.bg
            scrollbar_container.widget.bar_color = scrollbar.maximum > 1 and color.black or color.bg
        end
    
        scrollbar:connect_signal("property::value", scroll_layout_contents)
    
        prompt_textbox.ellipsize = "start"
        popup.widget = wibox.widget {
            {
                {
                    {
                        {
                            {
                                {
                                    markup = '<span foreground="'..color.green_alt..'">Lancer: </span>',
                                    widget = wibox.widget.textbox
                                },
                                prompt_textbox,
                                fill_space = true,
                                layout = wibox.layout.fixed.horizontal
                            },
                            bottom = prompt_spacing,
                            widget = wibox.container.margin
                        },
                        {
                            nil,
                            items_container,
                            {
                                scrollbar_container,
                                left = scrollbar_spacing,
                                widget = wibox.container.margin
                            },
                            buttons = {
                                awful.button({}, 4, function()
                                    if scrollbar.value == 0 then return end
                                    scrollbar.value = scrollbar.value - 1
                                    -- scrollbar:emit_signal("widget::redraw_needed")
                                end),
                                awful.button({}, 5, function()
                                    if scrollbar.value == scrollbar.maximum then return end
                                    scrollbar.value = scrollbar.value + 1
                                    -- scrollbar:emit_signal("widget::redraw_needed")
                                end)
                            },
                            -- forced_height = layout_height,
                            layout = wibox.layout.align.horizontal,
                        },
                        layout = wibox.layout.fixed.vertical
                    },
                    halign = "left",
                    content_fill_horizontal = true,
                    widget = wibox.container.place
                },
                margins = margins,
                widget = wibox.container.margin
            },
            left = left_border,
            right = right_border,
            top = top_border,
            bottom = bottom_border,
            color = beautiful.border_normal,
            widget = wibox.container.margin
        }
        popup.width = width
        popup.height = height
        popup.x = x
        popup.y = y
    
        function popup._private.show(query)
            scrollbar.value = 0
            update_items(query)
            select_widget(1)
            popup.visible = true
        end
        function popup._private.hide()
            popup.visible = false
        end
        function popup._private.get_selected_item()
            local item_widget_background = items_container.children[selected_widget]
            if item_widget_background then
                return item_widget_background.item
            end
        end
        function popup._private.select_up()
            local temp = selected_widget - 1
            if temp < 1 and selected_widget > 0 and items_container.children[selected_widget].position_index == 1 then
                scrollbar.value = scrollbar.maximum
                select_widget(max_showed_item_count)
            elseif temp < 1 then
                scrollbar.value = scrollbar.value - 1
            else
                select_widget(temp)
            end
        end
        function popup._private.select_down()
            local temp = selected_widget + 1
            if selected_widget > 0 and items_container.children[selected_widget].position_index == item_count then
                scrollbar.value = 0
                select_widget(1)
            elseif temp > max_showed_item_count then
                scrollbar.value = scrollbar.value + 1
            else
                select_widget(temp)
            end
        end
        function popup._private.set_items(new_items)
            items = new_items
        end
        popup._private.update_items = update_items
        popup._private.exe_callback = exe_callback
    end
    
    local function run_prompt(query)
        local no_changed_cb = false
        prompt.run {
            textbox = prompt_textbox,
            text = query,
            exe_callback = function()
                local item = popup._private.get_selected_item()
                if popup._private.exe_callback and item then popup._private.exe_callback(item) end
            end,
            keypressed_callback = function(_, key)
                if key == "Up" then
                    popup._private.select_up()
                    no_changed_cb = true
                elseif key == "Down" then
                    popup._private.select_down()
                    no_changed_cb = true
                end
            end,
            changed_callback = function(input)
                if no_changed_cb then no_changed_cb = false return end
                popup._private.update_items(input)
            end,
            done_callback = function(input)
                local item = popup._private.get_selected_item()
                if item then
                    popup._private.hide()
                else
                    popup.run(_, input)
                end
            end
        }
    end
    
    -- use new_items if to update the item list, query to start the inputlist with an initial query
    function popup.run(new_items, query)
        if not popup.widget then
            build_popup(args)
        end
        if new_items then
            popup._private.set_items(new_items)
        end
        popup._private.show(query)
        run_prompt(query)
    end
    
    return popup
end

