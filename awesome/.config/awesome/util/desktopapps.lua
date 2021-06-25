local menu_utils = require("menubar.utils")
local gears = require("gears")
local gfs = require("gears.filesystem")
local helpers = require("util.helpers")
local variables = require("config.variables")
local lgi = require("lgi")
local Gio = lgi.Gio
local GLib = lgi.GLib

local desktopapps = {}

-- Expecting a wm_name of awesome omits too many applications and tools
menu_utils.wm_name = ""

menu_utils.terminal = variables.terminal

desktopapps.entries = {}
local frequency_table

local on_entries_updated_callbacks = {}
function desktopapps.on_entries_updated(func)
    table.insert(on_entries_updated_callbacks, func)
end

local protected_call = require("gears.protected_call")
local gdebug = require("gears.debug")
local do_protected_call, call_callback
do
    -- Lua 5.1 cannot yield across a protected call. Instead of hardcoding a
    -- check, we check for this problem: The following coroutine yields true on
    -- success (so resume() returns true, true). On failure, pcall returns
    -- false and a message, so resume() returns true, false, message.
    local _, has_yieldable_pcall = coroutine.resume(coroutine.create(function()
        return pcall(coroutine.yield, true)
    end))
    if has_yieldable_pcall then
        do_protected_call = protected_call.call
        call_callback = function(callback, ...)
            return callback(...)
        end
    else
        do_protected_call = function(f, ...)
            return f(...)
        end
        call_callback = protected_call.call
    end
end

-- Maps keys in desktop entries to suitable getter function.
-- The order of entries is as in the spec.
-- https://standards.freedesktop.org/desktop-entry-spec/latest/ar01s05.html
local keys_getters
do
    local ok = 1
    local function get_string(kf, key, group)
        return menu_utils.rtrim(kf:get_string(group, key))
    end
    local function get_strings(kf, key, group)
        return kf:get_string_list(group, key, nil)
    end
    local function get_localestring(kf, key, group)
        return menu_utils.rtrim(kf:get_locale_string(group, key, nil))
    end
    local function get_localestrings(kf, key, group)
        return kf:get_locale_string_list(group, key, nil, nil)
    end
    local function get_boolean(kf, key, group)
        return kf:get_boolean(group, key)
    end

    keys_getters = {
        Type = get_string,
        Version = get_string,
        Name = get_localestring,
        GenericName = get_localestring,
        NoDisplay = get_boolean,
        Comment = get_localestring,
        Icon = get_localestring,
        Hidden = get_boolean,
        OnlyShowIn = get_strings,
        NotShowIn = get_strings,
        DBusActivatable = get_boolean,
        TryExec = get_string,
        Exec = get_string,
        Path = get_string,
        Terminal = get_boolean,
        Actions = get_strings,
        MimeType = get_strings,
        Categories = get_strings,
        Implements = get_strings,
        Keywords = get_localestrings,
        StartupNotify = get_boolean,
        StartupWMClass = get_string,
        URL = get_string,
    }
end

local function sort_func(a, b)
    if a.frequency == b.frequency then
        return helpers.replace_special_chars(a.Name):lower() < helpers.replace_special_chars(b.Name):lower()
    end
    return a.frequency > b.frequency
end

--- Parse a .desktop file.
-- @param file The .desktop file.
-- @return A table with file entries.
local function parse_desktop_file(file)
    local program = { show = true, file = file }

    -- Parse the .desktop file.
    -- We are interested in [Desktop Entry] group only.
    local keyfile = GLib.KeyFile()
    if not keyfile:load_from_file(file, GLib.KeyFileFlags.NONE) then
        return nil
    end

    -- In case [Desktop Entry] was not found
    if not keyfile:has_group("Desktop Entry") then
        return nil
    end

    for _, key in pairs(keyfile:get_keys("Desktop Entry")) do
        local getter = keys_getters[key] or function(kf, k, group)
            return kf:get_string(group, k)
        end
        program[key] = getter(keyfile, key, "Desktop Entry")
    end

    -- In case the (required) 'Name' entry was not found
    if not program.Name or program.Name == '' then return nil end

    -- Don't show program if NoDisplay attribute is true
    if program.NoDisplay then
        program.show = false
    else
        -- Only check these values is NoDisplay is true (or non-existent)

        -- Only show the program if there is no OnlyShowIn attribute
        -- or if it contains wm_name or wm_name is empty
        if menu_utils.wm_name ~= "" then
            if program.OnlyShowIn then
                program.show = false -- Assume false until found
                for _, wm in ipairs(program.OnlyShowIn) do
                    if wm == menu_utils.wm_name then
                        program.show = true
                        break
                    end
                end
            else
                program.show = true
            end
        end

        -- Only need to check NotShowIn if the program is being shown
        if program.show and program.NotShowIn then
            for _, wm in ipairs(program.NotShowIn) do
                if wm == menu_utils.wm_name then
                    program.show = false
                    break
                end
            end
        end
    end

    program.frequency = frequency_table[program.Name] or 0

    -- Look up for a icon.
    if program.Icon then
        program.Icon = helpers.get_icon(program.Icon, _, 64) or menu_utils.lookup_icon(program.Icon)
    end

    if program.Exec then
        -- Substitute Exec special codes as specified in
        -- http://standards.freedesktop.org/desktop-entry-spec/1.1/ar01s06.html
        if program.Name == nil then
            program.Name = '['.. file:match("([^/]+)%.desktop$") ..']'
        end
        local cmdline = program.Exec:gsub('%%c', program.Name)
        cmdline = cmdline:gsub('%%[fuFU]', '')
        cmdline = cmdline:gsub('%%k', program.file)
        if program.Icon then
            cmdline = cmdline:gsub('%%i', '--icon ' .. program.Icon)
        else
            cmdline = cmdline:gsub('%%i', '')
        end
        if program.Terminal == true then
            cmdline = menu_utils.terminal .. ' -e ' .. cmdline
        end
        program.cmdline = cmdline
    end

    program.id = file:match("^.+/(.+).desktop$") -- remove path and keep filename without extension

    if program.Actions then
        local actions = program.Actions
        program.Actions = {}
        local count = 1
        for k,v in ipairs(actions) do
            local action = "Desktop Action "..v
            if keyfile:has_group(action) then
                -- -- This is a standard parse
                -- program.Actions[v] = {}
                -- for _,key in pairs(keyfile:get_keys(action)) do
                --     local getter = keys_getters[key] or function(kf, k, group)
                --         return kf:get_string(group, key)
                --     end
                --     program.Actions[v][key] = getter(keyfile, key, action)
                -- end
                
                -- This is an awful.menu parse
                program.Actions[count] = {}
                local keys = keyfile:get_keys(action)
                for _,key in pairs(keyfile:get_keys(action)) do
                    local getter = keys_getters[key] or function(kf, k, group)
                        return kf:get_string(group, key)
                    end

                    local value = getter(keyfile, key, action)
                    if key == "Name" then
                        program.Actions[count][1] = value
                    elseif key == "Exec" then
                        -- Substitute Exec special codes as specified in
                        -- http://standards.freedesktop.org/desktop-entry-spec/1.1/ar01s06.html
                        local cmdline = value:gsub('%%c', program.Name)
                        cmdline = cmdline:gsub('%%[fuFU]', '')
                        cmdline = cmdline:gsub('%%k', program.file)
                        if program.Icon then
                            cmdline = cmdline:gsub('%%i', '--icon ' .. program.Icon)
                        else
                            cmdline = cmdline:gsub('%%i', '')
                        end
                        if program.Terminal == true then
                            cmdline = menu_utils.terminal .. ' -e ' .. cmdline
                        end
                        program.Actions[count][2] = cmdline
                    elseif key == "Icon" then
                        program.Actions[count][3] = helpers.get_icon(value, _, 64) or menu_utils.lookup_icon(value)
                    end
                end
                
                count = count + 1
            end
        end
    end

    return program
end

--- Parse a directory with .desktop files recursively.
-- @tparam string dir_path The directory path.
-- @tparam function callback Will be fired when all the files were parsed
-- with the resulting list of menu entries as argument.
-- @tparam table callback.programs Paths of found .desktop files.
local function parse_dir(dir_path, callback)

    local function get_readable_path(file)
        return file:get_path() or file:get_uri()
    end

    local function parser(file, programs)
        -- Except for "NONE" there is also NOFOLLOW_SYMLINKS
        local query = Gio.FILE_ATTRIBUTE_STANDARD_NAME .. "," .. Gio.FILE_ATTRIBUTE_STANDARD_TYPE
        local enum, err = file:async_enumerate_children(query, Gio.FileQueryInfoFlags.NONE)
        if not enum then
            gdebug.print_warning(get_readable_path(file) .. ": " .. tostring(err))
            return
        end
        local files_per_call = 100 -- Actual value is not that important
        while true do
            local list, enum_err = enum:async_next_files(files_per_call)
            if enum_err then
                gdebug.print_error(get_readable_path(file) .. ": " .. tostring(enum_err))
                return
            end
            for _, info in ipairs(list) do
                local file_type = info:get_file_type()
                local file_child = enum:get_child(info)
                if file_type == 'REGULAR' then
                    local path = file_child:get_path()
                    if path then
                        local success, program = pcall(parse_desktop_file, path)
                        if not success then
                            gdebug.print_error("Error while reading '" .. path .. "': " .. program)
                        elseif program then
                            table.insert(programs, program)
                        end
                    end
                elseif file_type == 'DIRECTORY' then
                    parser(file_child, programs)
                end
            end
            if #list == 0 then
                break
            end
        end
        enum:async_close()
    end

    Gio.Async.start(do_protected_call)(function()
        local result = {}
        parser(Gio.File.new_for_path(dir_path), result)
        call_callback(callback, result)
    end)
end

--- Get the path to the directories where XDG menu applications are installed.
local function get_xdg_menu_dirs()
    local dirs = gfs.get_xdg_data_dirs()
    table.insert(dirs, 1, gfs.get_xdg_data_home())
    return gears.table.map(function(dir)
        local apps_dir = dir .. 'applications/'
        if gears.filesystem.dir_readable(apps_dir) then
            local to_monitor = Gio.File.new_for_path(apps_dir)
            local monitor = Gio.File.monitor_directory(to_monitor, Gio.FileMonitorFlags.NONE, nil, nil)
            monitor.on_changed = function(m, file, other_file, event_type, user_data)
                assert(m == monitor)
                local path = file:get_path() or file:get_uri()
                local file_ext = path:match("^.+(%..+)$")
                if file_ext ~= ".desktop" then return end
                if event_type == "CHANGES_DONE_HINT" then
                    Gio.Async.start(do_protected_call)(function()
                        local found = false
                        for k,v in ipairs(desktopapps.entries) do
                            if v.file == path then
                                found = true
                                local success, program = pcall(parse_desktop_file, path)
                                if not success then
                                    gdebug.print_error("Error while reading '" .. path .. "': " .. program)
                                elseif program then
                                    desktopapps.entries[k] = program
                                    for _,v in ipairs(on_entries_updated_callbacks) do
                                        v()
                                    end
                                end
                            end
                        end
                        if not found then
                            local success, program = pcall(parse_desktop_file, path)
                            if not success then
                                gdebug.print_error("Error while reading '" .. path .. "': " .. program)
                            elseif program then
                                helpers.table_bininsert(desktopapps.entries, program, sort_func)
                                for _,v in ipairs(on_entries_updated_callbacks) do
                                    v()
                                end
                            end
                        end
                    end)
                elseif event_type == "DELETED" then
                    Gio.Async.start(do_protected_call)(function()
                        for k,v in ipairs(desktopapps.entries) do
                            if v.file == path then
                                table.remove(desktopapps.entries, k)
                                for _,v in ipairs(on_entries_updated_callbacks) do
                                    v()
                                end
                            end
                        end
                    end)
                end
            end
            return apps_dir
        else
            return nil
        end
    end, dirs)
end

--- Specifies all directories where menubar should look for .desktop
-- files. The search is recursive. Also adds GFile monitors for created/removed .desktop file handling.
desktopapps.all_menu_dirs = get_xdg_menu_dirs()

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

local function read_all_entries()
    local result = {}
    local unique_entries = {}
    local dirs_parsed = 0

    for _, dir in ipairs(desktopapps.all_menu_dirs) do
        parse_dir(dir, function(entries)
            entries = entries or {}
            for _, entry in ipairs(entries) do
                -- Check whether to include program in the menu
                if entry.show and entry.Name and entry.cmdline then
                    if not unique_entries[entry.id] then
                        unique_entries[entry.id] = entry
                        table.insert(result, entry)
                    end
                end
            end
            dirs_parsed = dirs_parsed + 1

            if dirs_parsed == #desktopapps.all_menu_dirs then
                -- Sort entries by frequency and alphabetically (by name)
                table.sort(result, sort_func)

                desktopapps.entries = result
                for _,v in ipairs(on_entries_updated_callbacks) do
                    v()
                end
            end
        end)
    end
end

function desktopapps.inc_frequency(name)
    if not frequency_table[name] then
        frequency_table[name] = 1
    else
        frequency_table[name] = frequency_table[name] + 1
    end
end

-- returns all entries matching query
function desktopapps.search(query)
    if not query then query = "" end
    query = helpers.replace_special_chars(helpers.trim(query)):lower()

    local ret = {}

    for k,v in ipairs(desktopapps.entries) do
        -- match when we find query in either one of the entry name, comment, generic name, keywords or categories
        local match = helpers.replace_special_chars(v.Name):lower():find(query) or
                      (v.Comment and helpers.replace_special_chars(v.Comment):lower():find(query)) or
                      (v.GenericName and helpers.replace_special_chars(v.GenericName):lower():find(query)) or
                      (helpers.replace_special_chars(v.Exec):lower():match("%w+"):find(query))
        if not match and v.Keywords then
            for _,keyword in pairs(v.Keywords) do
                match = helpers.replace_special_chars(keyword):lower():find(query)
                if match then break end
            end
        end
        if not match and v.Categories then
            for _,category in pairs(v.Categories) do
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

-- TODO other cases (this works in most cases already)...
--      use Bamf ?
function desktopapps.get_desktopapp_from_client(c)
    if not c.class then return end
    
    local class = c.class:lower()
    local class_dotless = class:gsub("%.", "")
    local class_dashless = class:gsub("%-", "")
    local instance = c.instance:lower()
    local instance_dotless = instance:gsub("%.", "")
    local instance_dashless = instance:gsub("%-", "")

    for k, entry in ipairs(desktopapps.entries) do
        
        -- TODO recheck all combination of cases
        local StartupWMClass = entry.StartupWMClass and entry.StartupWMClass:lower() or ""
        if class == StartupWMClass or instance == StartupWMClass then
            return entry
        end
        
        local id = entry.id:lower()
        if class == id or instance == id then
            return entry
        end
        
        if class_dotless == id or instance_dotless == id then
            return entry
        end
        
        local id_last_part = id:match("[^.]+$") -- ex: if id is 'org.gnome.maps', id_last_part will be 'maps'
        if class == id_last_part or instance == id_last_part then
            return entry
        end
        
        if class_dashless == id_last_part or instance_dashless == id_last_part then
            return entry
        end

        local exec_first_word = entry.Exec:match("%w+")
        if class == exec_first_word or instance == exec_first_word then
            return entry
        end
    end
end

load_frequency_table()
_G.awesome.connect_signal("exit", write_frequency_table)
read_all_entries()

return desktopapps
