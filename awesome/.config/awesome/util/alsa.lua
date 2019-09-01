local p = require("dbus_proxy")

local proxy = p.Proxy:new(
    {
        bus = p.Bus.SESSION,
        name = "fr.mpostaire.awdctl",
        interface = "fr.mpostaire.awdctl.Volume",
        path = "/fr/mpostaire/awdctl/Volume"
    }
)

return proxy
