-- replace this by an awesome implementation using popups later

local spawn = require("awful.spawn")

local rofi = {}

-- mode = drun|window
function rofi.launcher_menu(mode)
    local cmd = "rofi -modi drun,window -show " .. mode .. " -theme launchermenu"
    spawn.easy_async(cmd, function() end)
end

-- TODO: replace with a popup widget ? (may be complicated)
function rofi.network_menu()
    spawn.easy_async("networkmanager_dmenu", function() end)
end

return rofi
