-- replace this by an awesome implementation using popups later

local spawn = require("awful.spawn")

local rofi = {}

-- mode = drun|window
function rofi.launcher_menu(mode)
    local cmd = "rofi -modi drun,window -show " .. mode .. " -theme launchermenu"
    spawn.easy_async(cmd, function() end)
end

-- deprecated
function rofi.power_menu()
    local opts = " Verrouiller\n Déconnexion\n Mettre en veille\n Redémarrer\n Éteindre"
    local cmd = "echo -e \"" ..opts.. "\" | rofi -dmenu -i -theme powermenu -p 'Système'"

    spawn.easy_async_with_shell(cmd,
        function(stdout)
            local output = string.sub(stdout, 5, -2)
            if output == "Verrouiller" then
                spawn.easy_async_with_shell("~/.scripts/lock.sh", function() end)
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

-- TODO: replace with a popup widget ? (may be complicated)
function rofi.network_menu()
    spawn.easy_async("networkmanager_dmenu", function() end)
end

return rofi
