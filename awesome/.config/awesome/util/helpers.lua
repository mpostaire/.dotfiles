local timer = require("gears.timer")

local helpers = {}

function helpers.s_to_hms(seconds)
    if seconds <= 0 then
        return "00:00:00";
    else
        hours = string.format("%02.f", math.floor(seconds / 3600));
        mins = string.format("%02.f", math.floor(seconds / 60 - (hours * 60)));
        secs = string.format("%02.f", math.floor(seconds - hours * 3600 - mins * 60));
        return hours..":"..mins..":"..secs
    end
end

function helpers.truncate_number(number, decimals)
    local power = 10^decimals
    return math.floor(number * power) / power
end

function helpers.round_number(number, decimals)
    local power = 10^decimals
    return math.floor((number * power) + 0.5) / power
end

-- get a widget geometry under pointer
function helpers.get_widget_geometry(widget)
    local w, g = _G.mouse.current_widgets, _G.mouse.current_widget_geometries
    for k, v in ipairs(w) do
        if v == widget then
            return g[k]
        end
    end
end

-- change font size
function helpers.change_font_size(font, size)
    return string.gsub(font, "%d+", tostring(size))
end

function helpers.double_click()
    if double_click_timer then
        double_click_timer:stop()
        double_click_timer = nil
        return true
    end

    double_click_timer = timer.start_new(0.20, function()
        double_click_timer = nil
        return false
    end)
end

local tableAccents = {
    ["À"] = "A",
    ["Á"] = "A",
    ["Â"] = "A",
    ["Ã"] = "A",
    ["Ä"] = "A",
    ["Å"] = "A",
    ["Æ"] = "AE",
    ["Ç"] = "C",
    ["È"] = "E",
    ["É"] = "E",
    ["Ê"] = "E",
    ["Ë"] = "E",
    ["Ì"] = "I",
    ["Í"] = "I",
    ["Î"] = "I",
    ["Ï"] = "I",
    ["Ð"] = "D",
    ["Ñ"] = "N",
    ["Ò"] = "O",
    ["Ó"] = "O",
    ["Ô"] = "O",
    ["Õ"] = "O",
    ["Ö"] = "O",
    ["Ø"] = "O",
    ["Ù"] = "U",
    ["Ú"] = "U",
    ["Û"] = "U",
    ["Ü"] = "U",
    ["Ý"] = "Y",
    ["Þ"] = "P",
    ["ß"] = "s",
    ["à"] = "a",
    ["á"] = "a",
    ["â"] = "a",
    ["ã"] = "a",
    ["ä"] = "a",
    ["å"] = "a",
    ["æ"] = "ae",
    ["ç"] = "c",
    ["è"] = "e",
    ["é"] = "e",
    ["ê"] = "e",
    ["ë"] = "e",
    ["ì"] = "i",
    ["í"] = "i",
    ["î"] = "i",
    ["ï"] = "i",
    ["ð"] = "eth",
    ["ñ"] = "n",
    ["ò"] = "o",
    ["ó"] = "o",
    ["ô"] = "o",
    ["õ"] = "o",
    ["ö"] = "o",
    ["ø"] = "o",
    ["ù"] = "u",
    ["ú"] = "u",
    ["û"] = "u",
    ["ü"] = "u",
    ["ý"] = "y",
    ["þ"] = "p",
    ["ÿ"] = "y"
}

-- replace special chars by their normal counterpart
function helpers.replace_special_chars(str)
    local normalisedString = str:gsub("[%z\1-\127\194-\244][\128-\191]*", tableAccents)

    return normalisedString
end

return helpers
