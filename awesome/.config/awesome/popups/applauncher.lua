local awful = require("awful")
local desktopapps = require("util.desktopapps")
local inputlist_popup = require("util.inputlist_popup")
local beautiful = require("beautiful")

local applauncher = {}

local inputlist = inputlist_popup {
    height = _G.mouse.screen.geometry.height - beautiful.wibar_height + beautiful.border_width,
    width = 500, icon_spacing = 8, icon_size = 36, y = beautiful.wibar_height - beautiful.border_width,
    left_border = 0, top_border = 0, bottom_border = 0,
    exe_callback = function(item)
        if item.Name and item.cmdline then
            awful.spawn.easy_async_with_shell(item.cmdline, function() end)
            desktopapps.inc_frequency(item.Name)
        end
    end,
    query_filter = desktopapps.search
}

local enabled = false
desktopapps.on_entries_updated(function()
    enabled = true
end)

function applauncher.run()
    if enabled then
        inputlist.run(desktopapps.entries)
    end
end

return applauncher
