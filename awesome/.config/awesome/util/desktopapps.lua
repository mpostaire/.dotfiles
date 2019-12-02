local menu_gen   = require("menubar.menu_gen")
local menu_utils = require("menubar.utils")
local gears = require("gears")

local desktopapps = {}

-- // TODO get correct icon theme

-- Expecting a wm_name of awesome omits too many applications and tools
menu_utils.wm_name = ""

-- Add support for NixOS systems too
table.insert(menu_gen.all_menu_dirs, string.format("%s/.nix-profile/share/applications", os.getenv("HOME")))

-- Remove non existent paths in order to avoid issues
local existent_paths = {}
for _,v in pairs(menu_gen.all_menu_dirs) do
    if gears.filesystem.is_dir(v) then
        table.insert(existent_paths, v)
    end
end
menu_gen.all_menu_dirs = existent_paths

-- removes leading and trailing whitespaces from s
local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

desktopapps.entries = {}

-- returns all entries matching query
function desktopapps.search(query, iteration_callback)
    if not desktopapps.entries then return end
    if not query then query = "" end
    query = trim(query):lower()

    local ret = {}

    for k,v in ipairs(desktopapps.entries) do
        local match = v[1]:lower():find(query)
        if match then
            table.insert(ret, v)
        end
        if iteration_callback then iteration_callback(k, match ~= nil, v) end
    end

    return ret
end

-- Use MenuBar parsing utils to generate list of apps
-- // TODO add the comment to each entry
function desktopapps.build_list(callback)
    menu_gen.generate(function(entries)
        desktopapps.entries = {}

        -- Get items table
        for _, v in pairs(entries) do
            table.insert(desktopapps.entries, { v.name, v.cmdline, v.icon, v.category })
        end

        -- Sort entries alphabetically (by name)
        table.sort(desktopapps.entries, function (a, b) return a[1] < b[1] end)

        if callback then callback(desktopapps.entries) end
    end)
end

return desktopapps
