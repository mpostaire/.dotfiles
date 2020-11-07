local gfs = require("gears.filesystem")
local gtable = require("gears.table")
local gstring = require("gears.string")
local menu_utils = require("menubar.utils")
local variables = require("config.variables")
local spawn = require("awful.spawn")

-- Expecting a wm_name of awesome omits too many applications and tools
menu_utils.wm_name = ""

menu_utils.terminal = variables.terminal

local PATH = gtable.map(function(dir) return dir .. "/" end, gstring.split(os.getenv("PATH"), ":"))

local function get_xdg_config_dirs()
    local xdg_config_dirs = os.getenv("XDG_CONFIG_DIRS") or "/etc/xdg"
    return gtable.map(function(dir) return dir .. "/" end, gstring.split(xdg_config_dirs, ":"))
end

local function get_xdg_autostart_dirs()
    local dirs = get_xdg_config_dirs()
    table.insert(dirs, 1, gfs.get_xdg_config_home())
    return gtable.map(function(dir)
        local autostart_dir = dir .. 'autostart/'
        if gfs.dir_readable(autostart_dir) then
            return autostart_dir
        else
            return nil
        end
    end, dirs)
end

local function autostart_apps(autostart_dirs)
    local result = {}
    local unique_entries = {}
    local dirs_parsed = 0

    for _, dir in ipairs(autostart_dirs) do
        menu_utils.parse_dir(dir, function(entries)
            entries = entries or {}
            for _, entry in ipairs(entries) do
                -- Check whether to include program in the menu
                if not entry.Hidden and entry.cmdline then
                    local unique_key = entry.cmdline
                    local only_start_in = entry.OnlyShowIn or nil
                    local not_start_in = entry.NotShowIn or nil

                    local allowed
                    if only_start_in then
                        allowed = false
                        for _, wm in ipairs(only_start_in) do
                            if wm == "awesome" then
                                allowed = true
                                break
                            end
                        end
                    else
                        allowed = true
                    end

                    if allowed and not_start_in then
                        for _, wm in ipairs(not_start_in) do
                            if wm == "awesome" then
                                allowed = false
                                break
                            end
                        end
                    end

                    if allowed and entry.TryExec then
                        if entry.TryExec == "" then
                            allowed = true
                        elseif entry.TryExec:sub(1, 1) == "/" and gfs.file_executable(entry.TryExec) then
                            allowed = true
                        else
                            allowed = false
                            for _, dir in ipairs(PATH) do
                                if gfs.file_executable(dir..entry.TryExec) then
                                    allowed = true
                                end
                            end
                        end
                    end

                    if allowed and not unique_entries[unique_key] then
                        local cmdline = menu_utils.rtrim(entry.cmdline) or ""
                        table.insert(result, cmdline)
                        unique_entries[unique_key] = true
                    end
                end
            end
            dirs_parsed = dirs_parsed + 1
            
            if dirs_parsed == #autostart_dirs then
                for _, cmd in pairs(result) do
                    -- redirect output to prevents crashes when awesome is restarting (picom crashes wihout this)
                    spawn.easy_async_with_shell(cmd.." > /dev/null 2> /dev/null", function() end)
                end
            end
        end)
    end
end

local autostart_dirs = get_xdg_autostart_dirs()

local xresource_name = "awesome.started"
spawn.easy_async_with_shell("xrdb -query", function(stdout, _, _, exitcode)
    if stdout and exitcode == 0 and not stdout:match(xresource_name) then
        spawn.easy_async_with_shell("xrdb -merge <<< ".."'"..xresource_name..":true'", function(_, _, _, exitcode)
            if exitcode == 0 then
                autostart_apps(autostart_dirs)
            end
        end)
    end
end)
