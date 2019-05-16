local spawn = require("awful.spawn")
local naughty = require("naughty")
local beautiful = require("beautiful")

local rofi = {}

-- easy_async may() be sufficient instead of easy_async_with_shell()

function rofi.launcher_menu(mode)
    local cmd = "rofi -modi drun,window -show " .. mode .. " -theme launchermenu"
    spawn.easy_async_with_shell(cmd, function() end)
end

function rofi.power_menu()
    local opts = " Verrouiller\n Déconnexion\n Mettre en veille\n Redémarrer\n Éteindre"
    local cmd = "echo -e \"" ..opts.. "\" | rofi -dmenu -i -theme powermenu -p 'System'"

    spawn.easy_async_with_shell(cmd,
        function(stdout)
            local output = string.sub(stdout, 5, -2)
            if output == "Verrouiller" then
                spawn.easy_async_with_shell("~/.scripts/lock.sh")
            elseif output == "Déconnexion" then
                awesome.quit()
            elseif output == "Mettre en veille" then
                spawn.easy_async_with_shell("systemctl suspend", function() end)
            elseif output == "Redémarrer" then
                spawn.easy_async_with_shell("systemctl reboot", function() end)
            elseif output == "Éteindre" then
                spawn.easy_async_with_shell("systemctl -i poweroff", function() end)
            end
        end
    )
end

-- TODO: replace with a popup widget ? (if not, rewrite script to remove lines used for polybar)
function rofi.calendar_menu()
    spawn.easy_async_with_shell("~/.config/polybar/modules/calendarmenu.sh", function() end)
end

-- TODO: replace with a popup widget ? (if not, rewrite script to remove lines used for polybar)
function rofi.music_menu()
    spawn.easy_async_with_shell("~/.config/polybar/modules/musicmenu.sh", function() end)
end

-- TODO: replace with a popup widget ? (may be complicated)
function rofi.network_menu()
    spawn.easy_async_with_shell("networkmanager_dmenu", function() end)
end

return rofi