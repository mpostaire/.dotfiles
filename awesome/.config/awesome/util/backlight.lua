local awful = require("awful")
local lgi = require("lgi")
local Gio = lgi.Gio
local GLib = lgi.GLib
local helpers = require("util.helpers")

local backlight = {}

-- TODO handle case where there is no brightness sysfs (ex: desktop computer)

local on_changed_callbacks = {}

local backlight_dir = Gio.File.new_for_path("/sys/class/backlight")
local enumerator = backlight_dir:enumerate_children(Gio.FILE_ATTRIBUTE_STANDARD_NAME, Gio.FileQueryInfoFlags.NONE)
local info = enumerator:next_file()
enumerator:close()

local max_backlight_file = Gio.File.new_for_path("/sys/class/backlight/"..info:get_name().."/max_brightness")
local max_backlight_contents = max_backlight_file:load_contents()
local max_brightness = tonumber(max_backlight_contents)

local backlight_file = Gio.File.new_for_path("/sys/class/backlight/"..info:get_name().."/brightness")
local backlight_contents = backlight_file:load_contents()
local true_brightness = tonumber(backlight_contents)
backlight.brightness = math.ceil(true_brightness / max_brightness * 100) or 50 -- in percent

backlight.read_only = not backlight_file:query_info("standard::type,access::can-write", Gio.FileQueryInfoFlags.NONE):get_attribute_boolean("access::can-write")

backlight.min_brightness = 10
local min_brightness = math.ceil(backlight.min_brightness / 100 * max_brightness)

-- used to prevent sending writes operations while there is a running read
local write_lock = false

local monitor = Gio.File.monitor_file(backlight_file, Gio.FileMonitorFlags.NONE)
function monitor:on_changed(file, other_file, event_type, user_data)
    assert(self == monitor)
    if event_type == "CHANGES_DONE_HINT" then
        write_lock = true
        file:load_contents_async(nil, function(source_object, result, user_data)
            local new_contents = source_object:load_contents_finish(result)
            true_brightness = tonumber(new_contents)
            backlight.brightness = math.ceil(true_brightness / max_brightness * 100) or 50 -- in percent
            for _,v in pairs(on_changed_callbacks) do v() end
            write_lock = false
        end, nil)
    end
end

function backlight.set(value)
    if not value or backlight.read_only then return end

    local ammount = math.ceil(value / 100 * max_brightness)
    if ammount > max_brightness then
        ammount = max_brightness
        backlight.brightness = 100
    elseif ammount < min_brightness then
        ammount = min_brightness
        backlight.brightness = backlight.min_brightness
    else
        backlight.brightness = value
    end
    backlight_file:replace_contents(ammount, nil, false, Gio.FileCreateFlags.NONE)
end

function backlight.increase(value)
    backlight.set(backlight.brightness + value)
end

function backlight.decrease(value)
    backlight.set(backlight.brightness - value)
end

function backlight.on_changed(func)
    table.insert(on_changed_callbacks, func)
end

if not backlight.read_only then
    awful.keyboard.append_global_keybindings {
        awful.key({}, "XF86MonBrightnessUp", function()
            backlight.increase(5)
        end,
        {description = "brightness up", group = "other"}),
        awful.key({}, "XF86MonBrightnessDown", function()
            backlight.decrease(5)
        end,
        {description = "brightness down", group = "other"})
    }
end

return backlight
