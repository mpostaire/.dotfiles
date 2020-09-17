local menu_utils = require("menubar.utils")
local gears = require("gears")
local gfs = require("gears.filesystem")
local helpers = require("util.helpers")
local variables = require("config.variables")

local desktopapps = {}

-- Expecting a wm_name of awesome omits too many applications and tools
menu_utils.wm_name = ""

menu_utils.terminal = variables.terminal

--- Get the path to the directories where XDG menu applications are installed.
local function get_xdg_menu_dirs()
    local dirs = gfs.get_xdg_data_dirs()
    table.insert(dirs, 1, gfs.get_xdg_data_home())
    return gears.table.map(function(dir)
        local apps_dir = dir .. 'applications/'
        if gears.filesystem.dir_readable(apps_dir) then
            return apps_dir
        else
            return nil
        end
    end, dirs)
end

--- Specifies all directories where menubar should look for .desktop
-- files. The search is recursive.
desktopapps.all_menu_dirs = get_xdg_menu_dirs()

-- Add support for NixOS systems too
table.insert(desktopapps.all_menu_dirs, string.format("%s/.nix-profile/share/applications", os.getenv("HOME")))

desktopapps.entries = {}
local frequency_table

-- returns all entries matching query
function desktopapps.search(query, apps)
    if not query then query = "" end
    query = helpers.replace_special_chars(helpers.trim(query)):lower()

    local ret = {}

    for k,v in ipairs(apps) do
        -- match when we find query in either one of the entry name, comment, generic name, keywords or categories
        local match = helpers.replace_special_chars(v.title):lower():find(query) or
                      helpers.replace_special_chars(v.description):lower():find(query) or
                      helpers.replace_special_chars(v._generic_name):lower():find(query)
        if not match and v._keywords then
            for _,keyword in pairs(v._keywords) do
                match = helpers.replace_special_chars(keyword):lower():find(query)
                if match then break end
            end
        end
        if not match and v._categories then
            for _,category in pairs(v._categories) do
                match = helpers.replace_special_chars(category):lower():find(query)
                if match then break end
            end
        end
        if match then
            table.insert(ret, v)
        end
    end

    return ret
end

local function load_frequency_table()
    if frequency_table then
        return frequency_table
    end
    frequency_table = {}
    local count_file_name = gfs.get_cache_dir() .. "/menu_count_file"
    local count_file = assert(io.open(count_file_name, "r"))
    if count_file then
        for line in count_file:lines() do
            local name, count = string.match(line, "([^;]+);([^;]+)")
            if name ~= nil and count ~= nil then
                frequency_table[name] = tonumber(count)
            end
        end
        count_file:close()
    end
    return frequency_table
end

local function write_frequency_table()
    local count_file_name = gfs.get_cache_dir() .. "/menu_count_file"
    local count_file = assert(io.open(count_file_name, "w"))
    for name, count in pairs(frequency_table) do
        local str = string.format("%s;%d\n", name, count)
        count_file:write(str)
    end
    count_file:close()
end

_G.awesome.connect_signal("startup", load_frequency_table)
_G.awesome.connect_signal("exit", write_frequency_table)

function desktopapps.inc_frequency(name)
    if not frequency_table[name] then
        frequency_table[name] = 1
    else
        frequency_table[name] = frequency_table[name] + 1
    end
end

--- Generate an array of all visible menu entries.
-- @tparam function callback Will be fired when all menu entries were parsed
-- with the resulting list of menu entries as argument.
-- @tparam table callback.entries All menu entries.
function desktopapps.build_list(callback)
    local result = {}
    local unique_entries = {}
    local dirs_parsed = 0
    local short_locale = string.sub(variables.locale, 1, 2)

    for _, dir in ipairs(desktopapps.all_menu_dirs) do
        menu_utils.parse_dir(dir, function(entries)
            entries = entries or {}
            for _, entry in ipairs(entries) do
                -- Check whether to include program in the menu
                if entry.show and entry.Name and entry.cmdline then
                    local unique_key = entry.Name .. '\0' .. entry.cmdline
                    if not unique_entries[unique_key] then
                        local name = menu_utils.rtrim(entry.Name) or ""
                        local cmdline = menu_utils.rtrim(entry.cmdline) or ""
                        local icon = entry.icon_path or nil
                        local comment = menu_utils.rtrim(entry.Comment) or ""
                        local generic_name = entry['GenericName'] or ""
                        local keywords = entry['Keywords['..short_locale..']'] or nil
                        if keywords then
                            keywords = gears.string.split(keywords, ";")
                        end
                        local categories = entry.categories or nil
                        local frequency = frequency_table[name] or 0
                        table.insert(result, { title = name, cmd = cmdline, icon = icon, description = comment, _generic_name = generic_name, _keywords = keywords, _categories = categories, _frequency = frequency })
                        unique_entries[unique_key] = true
                    end
                end
            end
            dirs_parsed = dirs_parsed + 1

            if dirs_parsed == #desktopapps.all_menu_dirs then
                -- Sort entries by frequency and alphabetically (by name)
                table.sort(result, function(a, b)
                    if a._frequency == b._frequency then
                        return helpers.replace_special_chars(a.title):lower() < helpers.replace_special_chars(b.title):lower()
                    end
                    return a._frequency > b._frequency
                end)

                desktopapps.entries = result
                if callback then callback(desktopapps.entries) end
            end
        end)
    end
end

return desktopapps
