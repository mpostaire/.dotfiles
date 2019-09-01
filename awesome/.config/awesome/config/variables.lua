local variables = {}

-- This is used later as the default terminal and editor to run.
variables.terminal = os.getenv("TERMINAL") or "urxvt"
variables.editor = os.getenv("EDITOR") or "nano"
variables.editor_cmd = variables.terminal .. " -e " .. variables.editor
variables.home = os.getenv("HOME") .. "/"

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
variables.modkey = "Mod4"

variables.altkey = "Mod1"

return variables
