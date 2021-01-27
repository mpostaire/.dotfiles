local lgi = require("lgi")
local Gio = lgi.Gio
local GLib = lgi.GLib
local success_geoclue, Geoclue = pcall(lgi.require, "Geoclue", "2.0")
local success_geocode, GeocodeGlib = pcall(lgi.require, "GeocodeGlib", "1.0")

local geoclue = {}

local on_location_found_callbacks = {}

if success_geoclue then
    geoclue.enabled = true
else
    geoclue.enabled = false
    return geoclue
end

Geoclue.Simple.new('awesome', Geoclue.AccuracyLevel.CITY, nil, function(source_object, result, user_data)
    local ret = Geoclue.Simple.new_finish(result)    
    local loc = ret:get_location()
    
    geoclue.latitude = loc.latitude
    geoclue.longitude = loc.longitude

    if not success_geocode then
        geoclue.string_location = geoclue.coords_to_string(geoclue.latitude, geoclue.longitude)
        for _,callback in pairs(on_location_found_callbacks) do callback() end
        return
    end

    local loc = GeocodeGlib.Location.new(geoclue.latitude, geoclue.longitude, 0)
    local rev = GeocodeGlib.Reverse.new_for_location(loc)
    rev:resolve_async(nil, function(source_object, result, user_data)
        local ret = source_object:resolve_finish(result)
        geoclue.string_location = ret:get_town() or ret:get_county() or ret:get_state() or ret:get_country()
        if not geoclue.string_location then
            geoclue.string_location = geoclue.coords_to_string(geoclue.latitude, geoclue.longitude)
        end
        for _,callback in pairs(on_location_found_callbacks) do callback() end
    end, nil)

end, nil)

local function dd_to_dms(dd)
    local deg = math.floor(dd)
    local min = math.floor((dd - deg) * 60)
    local sec = (dd - deg - min / 60) * 3600
    return deg, min, sec
end

function geoclue.coords_to_string(latitude, longitude)
    local location

    -- latitude
    local deg, min, _ = dd_to_dms(latitude)
    if deg < 0 then
        location = -deg.."°"..min.."'S "
    else
        location = deg.."°"..min.."'N "
    end

    -- latitude
    deg, min, _ = dd_to_dms(longitude)
    if deg < 0 then
        location = location..-deg.."°"..min.."'W"
    else
        location = location..deg.."°"..min.."'E"
    end
    return location
end

function geoclue.on_location_found(func)
    table.insert(on_location_found_callbacks, func)
end

return geoclue
