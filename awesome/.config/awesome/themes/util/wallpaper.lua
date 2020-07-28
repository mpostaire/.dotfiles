local gears = require("gears")

local wallpaper = {}

local set_called = false

function wallpaper.set(wallpaper_path)
    -- if no argument, we take wapplaper.path if it exists or we take a black screen
    if not wallpaper_path then
        wallpaper_path = wallpaper.path and wallpaper.path or "#000000"
    end

    set_called = true

    -- convert '~' char as home folder
    if string.sub(wallpaper_path, 1, 1) == "~" then
        wallpaper_path = variables.home .. string.sub(wallpaper_path, 2)
    -- if first char is '#', wallpaper is a solid color
    elseif string.sub(wallpaper_path, 1, 1) == "#" then
        gears.wallpaper.set(wallpaper_path)
        wallpaper.path = wallpaper_path
        return
    end

    if not gfs.file_readable(wallpaper_path) then
        wallpaper_path = gfs.get_themes_dir().."default/background.png"
    end
    wallpaper.path = wallpaper

    -- sets it for each screen
    screen.connect_signal("request::wallpaper", function(s)
        if wallpaper_path then
            local w = wallpaper_path
            -- If wallpaper_path is a function, call it with the screen
            if type(w) == "function" then
                w = w(s)
            end
            gears.wallpaper.maximized(w, s, true)
        end
    end)
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
if set_called then 
    _G.screen.connect_signal("property::geometry", set_wallpaper)
end

return wallpaper
