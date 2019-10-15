local capi = {mouse = mouse}

local helpers = {}

function helpers.get_widget_geometry(widget)
    local w, g = capi.mouse.current_widgets, capi.mouse.current_widget_geometries
    for k,v in ipairs(w) do
        if v == widget then
            return g[k]
        end
    end
end

return helpers
