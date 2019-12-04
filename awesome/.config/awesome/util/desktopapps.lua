local menu_utils = require("menubar.utils")
local gears = require("gears")
local utils = require("menubar.utils")
local helpers = require("util.helpers")
local variables = require("config.variables")

local desktopapps = {}

-- // TODO get correct icon theme

-- Expecting a wm_name of awesome omits too many applications and tools
menu_utils.wm_name = ""

menu_utils.terminal = variables.terminal

--- Get the path to the directories where XDG menu applications are installed.
local function get_xdg_menu_dirs()
    local dirs = gears.filesystem.get_xdg_data_dirs()
    table.insert(dirs, 1, gears.filesystem.get_xdg_data_home())
    return gears.table.map(function(dir) return dir .. 'applications/' end, dirs)
end

--- Specifies all directories where menubar should look for .desktop
-- files. The search is recursive.
desktopapps.all_menu_dirs = get_xdg_menu_dirs()

-- Add support for NixOS systems too
table.insert(desktopapps.all_menu_dirs, string.format("%s/.nix-profile/share/applications", os.getenv("HOME")))

-- Remove non existent paths in order to avoid issues
local existent_paths = {}
for _,v in pairs(desktopapps.all_menu_dirs) do
    if gears.filesystem.is_dir(v) then
        table.insert(existent_paths, v)
    end
end
desktopapps.all_menu_dirs = existent_paths

-- removes leading and trailing whitespaces from s
local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

desktopapps.entries = {}

-- returns all entries matching query
function desktopapps.search(query, iteration_callback)
    if not desktopapps.entries then return end
    if not query then query = "" end
    query = helpers.replace_special_chars(trim(query)):lower()

    local ret = {}

    for k,v in ipairs(desktopapps.entries) do
        -- match when we find query in either one of the entry name, comment, generic name, keywords or categories
        local match = helpers.replace_special_chars(v[1]):lower():find(query) or
                      helpers.replace_special_chars(v[4]):lower():find(query) or
                      helpers.replace_special_chars(v[5]):lower():find(query)
        if not match and v[6] then
            for _,keyword in pairs(v[6]) do
                match = helpers.replace_special_chars(keyword):lower():find(query)
                if match then break end
            end
        end
        if not match and v[7] then
            for _,category in pairs(v[7]) do
                match = helpers.replace_special_chars(category):lower():find(query)
                if match then break end
            end
        end
        if match then
            table.insert(ret, v)
        end
        if iteration_callback then iteration_callback(k, match ~= nil, v) end
    end

    return ret
end

--- Generate an array of all visible menu entries.
-- @tparam function callback Will be fired when all menu entries were parsed
-- with the resulting list of menu entries as argument.
-- @tparam table callback.entries All menu entries.
-- // TODO add history based sort option
--    each time an entry is launched, we save its name followed by the number of times it has been launched
--    we sort them like this: (change sort function in desktopapps.lua)
--    a < b if a.frequency > b. frequency or a.name < b.name
--    to make this faster connect to awesome reload/quit signals and save frequencies only then
--    (in the meantime it is saved in entries table)
function desktopapps.build_list(callback)
    local result = {}
    local unique_entries = {}
    local dirs_parsed = 0
    local short_locale = string.sub(variables.locale, 1, 2)

    for _, dir in ipairs(desktopapps.all_menu_dirs) do
        utils.parse_dir(dir, function(entries)
            entries = entries or {}
            for _, entry in ipairs(entries) do
                -- Check whether to include program in the menu
                if entry.show and entry.Name and entry.cmdline then
                    local unique_key = entry.Name .. '\0' .. entry.cmdline
                    if not unique_entries[unique_key] then
                        local name = utils.rtrim(entry.Name) or ""
                        local cmdline = utils.rtrim(entry.cmdline) or ""
                        local icon = entry.icon_path or nil
                        local comment = utils.rtrim(entry.Comment) or ""
                        local generic_name = entry['GenericName'] or ""
                        local keywords = entry['Keywords['..short_locale..']'] or nil
                        if keywords then
                            keywords = gears.string.split(keywords, ";")
                        end
                        local categories = entry.categories or nil
                        table.insert(result, { name, cmdline, icon, comment, generic_name, keywords, categories })
                        unique_entries[unique_key] = true

                        -- if entry.Name == "Firefox" then
                        --     -- require("naughty").notify{text=generic_name}
                        --     -- for k,v in pairs(entry) do
                        --     --     require("naughty").notify{text=tostring(k).."="..tostring(v)}
                        --     -- end
                        --     -- for k,v in pairs(keywords) do
                        --     --     require("naughty").notify{text=tostring(k).."="..tostring(v)}
                        --     -- end
                        -- end
                    end
                end
            end
            dirs_parsed = dirs_parsed + 1

            if dirs_parsed == #desktopapps.all_menu_dirs then
                -- Sort entries alphabetically (by name)
                table.sort(result, function(a, b)
                    return helpers.replace_special_chars(a[1]):lower() < helpers.replace_special_chars(b[1]):lower()
                end)

                desktopapps.entries = result
                if callback then callback(desktopapps.entries) end
            end
        end)
    end
end

return desktopapps
