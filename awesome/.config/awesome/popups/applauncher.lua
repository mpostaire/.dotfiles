local awful = require("awful")
local prompt = require("util.prompt")
local beautiful = require("beautiful")
local wibox = require("wibox")
local gears = require("gears")
local desktopapps = require("util.desktopapps")
local helpers = require("util.helpers")
local capi = {mouse = mouse, awesome = awesome}

local applauncher = {}

local popup = wibox {
    ontop = true,
    type = "normal",
    border_color = beautiful.black_alt,
    placement = awful.placement.bottom_left
}

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

background:connect_signal("button::press", prompt.stop)
capi.awesome.connect_signal("lock", prompt.stop)

local prompt_textbox = wibox.widget.textbox()
prompt_textbox.forced_height = beautiful.get_font_height(beautiful.font)

-- how many items scrolled per scroll
local scrollbar_velocity = 1 -- // FIXME this

local function build_popup(args)
    if not args then args = {} end
    local prompt_spacing = args.prompt_spacing or 15
    local scrollbar_spacing = args.scrollbar_spacing or 10
    local width = args.width or 250
    local height = args.height or capi.mouse.screen.geometry.height - beautiful.wibar_height + beautiful.wibar_bottom_border_width
    local icon_size = args.icon_size or 32
    local margins = args.margins or 25
    local item_margins = args.item_margins or 2
    local icon_spacing = args.icon_spacing or 4

    local prompt_height = prompt_textbox.forced_height + prompt_spacing
    local item_height = icon_size + 2 * item_margins
    local max_showed_item_count = math.floor((height - 2 * margins - prompt_height) / item_height)
    local layout_height = icon_size * max_showed_item_count

    local scrollbar = wibox.widget {
        bar_color = beautiful.black_alt,
        handle_color = beautiful.fg_normal,
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

    local filtered_items, item_count = desktopapps.entries, #desktopapps.entries
    local icon_placeholder = wibox.container.margin()
    icon_placeholder.left = icon_size
    local icon_widgets = {}

    local items_container = wibox.layout.fixed.vertical()
    local selected_widget = 1
    local function select_widget(index)
        if index ~= 0 and not items_container.children[index].position_index then
            for i = index, 1, -1 do
                if items_container.children[i].position_index then
                    index = i
                    break
                end
            end
        end

        if selected_widget ~= 0 then
            local item_background = items_container.children[selected_widget]
            item_background.bg = beautiful.bg_normal
            item_background.fg = beautiful.fg_normal
            local comment_textbox = items_container.children[selected_widget].widget.widget.second.children[2]
            comment_textbox.markup = '<i><span foreground="'..beautiful.white_alt..'">'..comment_textbox.text..'</span></i>'
        end

        selected_widget = index

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
        widget:buttons(gears.table.join(
            awful.button({}, 1, function()
                if not items_container.children[i].position_index then return end
                if selected_widget ~= i then select_widget(i) return end
                local name, cmd = popup.get_selected_item()
                if name and cmd then
                    awful.spawn.easy_async_with_shell(cmd, function() end)
                    desktopapps.inc_frequency(name)
                    prompt.stop()
                    popup.hide()
                end
            end)
        ))
        widget:connect_signal("mouse::enter", function()
            select_widget(i)
        end)
        items_container:add(widget)
    end

    local function scroll_layout_contents()
        if scrollbar.maximum == 1 then return end

        for i = 1, max_showed_item_count do
            local item = filtered_items[scrollbar.value + i]
            local item_widget_background = items_container.children[i]
            local item_widget = item_widget_background.widget.widget
            if item[3] then
                item_widget.first.widget = icon_widgets[i]
                icon_widgets[i].image = item[3]
            else
                item_widget.first.widget = icon_placeholder
            end
            local name_comment_textboxes = item_widget.second
            name_comment_textboxes.children[1].text = item[1]
            local comment = item[4] ~= "" and item[4] or item[5]
            if i == selected_widget then
                name_comment_textboxes.children[2].markup = '<i><span foreground="'..beautiful.bg_normal..'">'..comment..'</span></i>'
            else
                name_comment_textboxes.children[2].markup = '<i><span foreground="'..beautiful.white_alt..'">'..comment..'</span></i>'
            end
            item_widget_background.cmd = item[2]
            item_widget_background.position_index = scrollbar.value + i
        end
    end

    local old_query
    local function update_items(query)
        if old_query and old_query == query then return end
        old_query = query

        item_count = 0
        local count = 1
        desktopapps.search(query, function(_, match, entry)
            if match then
                item_count = item_count + 1
                if count <= max_showed_item_count then
                    local item_widget_background = items_container.children[count]
                    local item_widget = item_widget_background.widget.widget
                    local item_widget_first = item_widget.first
                    if entry[3] then
                        item_widget_first.widget = icon_widgets[count]
                        item_widget_first.widget.image = entry[3]
                    else
                        item_widget_first.widget = icon_placeholder
                    end
                    local item_widget_second = item_widget.second
                    item_widget_second.children[1].text = entry[1]
                    local comment = entry[4] ~= "" and entry[4] or entry[5]
                    if count == selected_widget then
                        item_widget_second.children[2].markup = '<i><span foreground="'..beautiful.bg_normal..'">'..comment..'</span></i>'
                    else
                        item_widget_second.children[2].markup = '<i><span foreground="'..beautiful.white_alt..'">'..comment..'</span></i>'
                    end
                    item_widget_background.cmd = entry[2]
                    item_widget_background.position_index = count
                    count = count + 1
                end
            end
        end)

        -- then clear following widgets if needed
        for i = count, max_showed_item_count do
            local item_widget_background = items_container.children[i]
            local item_widget = item_widget_background.widget.widget
            item_widget.first.widget = nil
            item_widget.second.children[1].text = ""
            item_widget.second.children[2].markup = ""
            item_widget_background.cmd = nil
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
        scrollbar_container.widget.handle_color = scrollbar.maximum > 1 and beautiful.white or beautiful.black
        scrollbar_container.widget.bar_color = scrollbar.maximum > 1 and beautiful.black_alt or beautiful.black
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
                                markup = '<span foreground="'..beautiful.green..'">Lancer: </span>',
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
                        buttons = gears.table.join(
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
                        ),
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
        right = 2,
        color = beautiful.border_normal,
        widget = wibox.container.margin
    }
    popup.width = width
    popup.height = height
    popup.x = 0
    popup.y = beautiful.wibar_height - beautiful.wibar_bottom_border_width

    function popup.show()
        scrollbar.value = 0
        update_items()
        select_widget(1)
        background.visible = true
        popup.visible = true
    end
    function popup.hide()
        background.visible = false
        popup.visible = false
    end
    function popup.get_selected_item()
        local item_widget_background = items_container.children[selected_widget]
        if item_widget_background then
            return item_widget_background.widget.widget.second.children[1].text, item_widget_background.cmd
        end
    end
    function popup.select_up()
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
    function popup.select_down()
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
    popup.update_items = update_items
end

local function run_prompt()
    local no_changed_cb = false
    prompt.run {
        textbox      = prompt_textbox,
        exe_callback = function()
            local name, cmd = popup.get_selected_item()
            if name and cmd then
                awful.spawn.easy_async_with_shell(cmd, function() end)
                desktopapps.inc_frequency(name)
            end
        end,
        keypressed_callback = function(_, key)
            if key == "Up" then
                popup.select_up()
                no_changed_cb = true
            elseif key == "Down" then
                popup.select_down()
                no_changed_cb = true
            end
        end,
        changed_callback = function(input)
            if no_changed_cb then no_changed_cb = false return end
            popup.update_items(input)
        end,
        done_callback = function()
            popup.hide()
        end
    }
end

-- launch appmenu if generated
-- if not generated wait for it
-- if reload specified, wait for new menu before showing it (it's faster after first generation)
function applauncher.run(reload)
    if not popup.widget then
        desktopapps.build_list(function()
            build_popup{width = 500, icon_spacing = 8, icon_size = 36}
            popup.show()
            run_prompt()
        end)
    elseif reload then
        desktopapps.build_list(function()
            popup.show()
            run_prompt()
        end)
    else
        popup.show()
        run_prompt()
    end
end

return applauncher
