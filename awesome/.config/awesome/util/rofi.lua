-- replace this by an awesome implementation using popups later

local spawn = require("awful.spawn")

local rofi = {}

-- TODO: replace with a popup widget ? (may be complicated)
function rofi.network_menu()
    spawn.easy_async("networkmanager_dmenu", function() end)
end

return rofi
