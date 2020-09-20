local timer = require("gears.timer")
local awful = require("awful")
local gfs = require("gears.filesystem")
local gtable = require("gears.table")
local dbus = require("dbus_proxy")
local lgi = require("lgi")
local Gio = lgi.Gio
local success_gtk, Gtk = pcall(lgi.require, "Gtk")
local success_gdk, Gdk = pcall(lgi.require, "Gdk")

local helpers = {}

-- Convert encoded local URI to Unix paths.
function helpers.uri_to_unix_path(input)
    if type(input) ~= "string" then return nil end

    if input:sub(1,7) == "file://" then
        input = input:sub(8)
    end

    -- urldecode
    input = input:gsub("%%(%x%x)", function(x) return string.char(tonumber(x, 16)) end)

    return gfs.file_readable(input) and input or nil
end

function helpers.s_to_hms(seconds)
    if seconds <= 0 then
        return "00:00:00";
    else
        hours = string.format("%02.f", math.floor(seconds / 3600));
        mins = string.format("%02.f", math.floor(seconds / 60 - (hours * 60)));
        secs = string.format("%02.f", math.floor(seconds - hours * 3600 - mins * 60));
        return hours..":"..mins..":"..secs
    end
end

function helpers.truncate_number(number, decimals)
    local power = 10^decimals
    return math.floor(number * power) / power
end

function helpers.round_number(number, decimals)
    local power = 10^decimals
    return math.floor((number * power) + 0.5) / power
end

-- get a widget geometry under pointer
function helpers.get_widget_geometry(widget)
    local w, g = _G.mouse.current_widgets, _G.mouse.current_widget_geometries
    for k, v in ipairs(w) do
        if v == widget then
            return g[k]
        end
    end
end

-- change font size
function helpers.change_font_size(font, size)
    return string.gsub(font, "%d+", tostring(size))
end

function helpers.double_click()
    if double_click_timer then
        double_click_timer:stop()
        double_click_timer = nil
        return true
    end

    double_click_timer = timer.start_new(0.20, function()
        double_click_timer = nil
        return false
    end)
end

-- long click button action on click released
-- short_press_callback is the function called if the click is considered short (< long_press_timeout)
-- long_press_callback is the function called if the click is considered long (>= long_press_timeout)
-- long_press_timeout is the time used to define if a click is long or short
-- long_press_repeat is the time (in seconds) the long_press_callback is called after its first call (value of -1 = no repeats)
function helpers.long_press_click(mod, button, short_press_callback, long_press_callback, long_press_timeout, long_press_repeat)
    local long_press, long_press_timer = false, nil
    if not long_press_timeout then long_press_timeout = 1 end
    if not long_press_repeat then long_press_repeat = -1 end
    return awful.button({}, 1, function()
        long_press_timer = timer.start_new(long_press_timeout, function()
            long_press = true
            if long_press_repeat == -1 then
                long_press_callback()
            else
                long_press_timer = timer.start_new(long_press_repeat, function()
                    long_press_callback()
                    return true
                end)
            end
            return false
        end)
    end,
    function()
        if long_press_timer then
            long_press_timer:stop()
        end
        if long_press then
            long_press = false
        else
            short_press_callback()
        end
        return false
    end)
end

local tableAccents = {
    ["À"] = "A",
    ["Á"] = "A",
    ["Â"] = "A",
    ["Ã"] = "A",
    ["Ä"] = "A",
    ["Å"] = "A",
    ["Æ"] = "AE",
    ["Ç"] = "C",
    ["È"] = "E",
    ["É"] = "E",
    ["Ê"] = "E",
    ["Ë"] = "E",
    ["Ì"] = "I",
    ["Í"] = "I",
    ["Î"] = "I",
    ["Ï"] = "I",
    ["Ð"] = "D",
    ["Ñ"] = "N",
    ["Ò"] = "O",
    ["Ó"] = "O",
    ["Ô"] = "O",
    ["Õ"] = "O",
    ["Ö"] = "O",
    ["Ø"] = "O",
    ["Ù"] = "U",
    ["Ú"] = "U",
    ["Û"] = "U",
    ["Ü"] = "U",
    ["Ý"] = "Y",
    ["Þ"] = "P",
    ["ß"] = "s",
    ["à"] = "a",
    ["á"] = "a",
    ["â"] = "a",
    ["ã"] = "a",
    ["ä"] = "a",
    ["å"] = "a",
    ["æ"] = "ae",
    ["ç"] = "c",
    ["è"] = "e",
    ["é"] = "e",
    ["ê"] = "e",
    ["ë"] = "e",
    ["ì"] = "i",
    ["í"] = "i",
    ["î"] = "i",
    ["ï"] = "i",
    ["ð"] = "eth",
    ["ñ"] = "n",
    ["ò"] = "o",
    ["ó"] = "o",
    ["ô"] = "o",
    ["õ"] = "o",
    ["ö"] = "o",
    ["ø"] = "o",
    ["ù"] = "u",
    ["ú"] = "u",
    ["û"] = "u",
    ["ü"] = "u",
    ["ý"] = "y",
    ["þ"] = "p",
    ["ÿ"] = "y"
}

-- replace special chars by their normal counterpart
function helpers.replace_special_chars(str)
    return str:gsub("[%z\1-\127\194-\244][\128-\191]*", tableAccents)
end

-- removes leading and trailing whitespaces from str
function helpers.trim(str)
    return (str:gsub("^%s*(.-)%s*$", "%1"))
end

if success_gdk and success_gdk then
    local get_icon_cache = {}

    local function get_icon_uncached(name, theme_path)
        local icon_theme
        if theme_path then
            icon_theme = Gtk.IconTheme()
            local icon_search_path = icon_theme:get_default():get_search_path()
            for _,path in pairs(icon_search_path) do
                icon_theme:append_search_path(path)
            end
            icon_theme:append_search_path(theme_path)
            icon_theme:set_screen(Gdk.Screen.get_default())
        else
            icon_theme = Gtk.IconTheme.get_default()
        end
    
        local icon_info
        if icon_theme then
            icon_info = icon_theme:lookup_icon_for_scale(name, 22, 1, Gtk.IconLookupFlags.GENERIC_FALLBACK)
            if icon_info then
                return icon_info:get_filename()
            end
        end
    
        return nil
    end

    helpers.get_icon = function(name, theme_path)
        if not name then return nil end
        local key = name..theme_path
        if not get_icon_cache[key] and get_icon_cache[key] ~= false then
            get_icon_cache[key] = get_icon_uncached(name, theme_path)
        end
        return get_icon_cache[key]
    end
else
    helpers.get_icon = require("menubar.utils").lookup_icon
end

local dbus_watched_names = {}

local manager_proxy = dbus.Proxy:new {
    bus = dbus.Bus.SESSION,
    name = "org.freedesktop.DBus",
    interface = "org.freedesktop.DBus",
    path = "/org/freedesktop/DBus"
}

local function name_owner_changed_callback(conn, sender, object_path, interface_name, signal_name, parameters, user_data)
    local name = parameters[1]
    local new_owner = parameters[2]
    local old_owner = parameters[3]

    for _,v in pairs(dbus_watched_names) do
        if (v.is_prefix and name:sub(1, #v.name) == v.name) or (not v.is_prefix and v.name == name) then
            if old_owner == "" then -- lost name
                if v.name_lost_callback then v.name_lost_callback(name) end
            elseif new_owner == "" then -- added name
                if v.name_added_callback then v.name_added_callback(name) end
            end
        end
    end
end

dbus.Bus.SESSION:signal_subscribe('org.freedesktop.DBus', 'org.freedesktop.DBus',
                                    'NameOwnerChanged', "/org/freedesktop/DBus", nil, Gio.DBusSignalFlags.NONE, name_owner_changed_callback)

function helpers.dbus_watch_name_or_prefix(name, name_added_callback, name_lost_callback, is_prefix)
    if not name_added_callback and not name_lost_callback then return end

    local data = {
        name = name,
        name_lost_callback = name_lost_callback,
        name_added_callback = name_added_callback,
        is_prefix = is_prefix
    }

    -- check if the name is already available, so we can fire the name_added_callback
    if data.name_added_callback then
        local dbus_names = manager_proxy:ListNames()
        for _, name in pairs(dbus_names) do
            if (data.is_prefix and name:sub(1, #data.name) == data.name) or (not data.is_prefix and data.name == name) then
                data.name_added_callback(name)
            end
        end
    end

    table.insert(dbus_watched_names, data)
end

function helpers.change_cursor_on_hover(widget, cursor)
    local old_cursor, old_wibox
    widget:connect_signal("mouse::enter", function()
        -- Hm, no idea how to get the wibox from this signal's arguments...
        local w = _G.mouse.current_wibox
        old_cursor, old_wibox = w.cursor, w
        w.cursor = cursor or "hand2"
    end)
    widget:connect_signal("mouse::leave", function()
        if old_wibox then
            old_wibox.cursor = old_cursor
            old_wibox = nil
        end
    end)
end

return helpers
