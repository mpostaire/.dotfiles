local spawn = require("awful.spawn")

-- because easy_async_with_shell is used, the & char may be not necessary
local cmds = {
    "mpd", -- maybe put this in xinitrc instead
    "awdctl -d", -- maybe put this in xinitrc instead
    "mpdctl -d", -- maybe put this in xinitrc instead
    "compton -b", -- maybe put this in xinitrc instead
    "redshift" -- maybe put this in xinitrc instead
}

local function autostart(cmd)
    local findme = cmd
    local firstspace = cmd:find(" ")
    if firstspace then
        findme = cmd:sub(0, firstspace - 1)
    end
    spawn.easy_async_with_shell(string.format("pgrep -u $USER -x %s > /dev/null || (%s)", findme, cmd), function() end)
end

for _,v in ipairs(cmds) do
    autostart(v)
end
