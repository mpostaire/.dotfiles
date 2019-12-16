local helpers = require("util.helpers")

local solar = {}

-- Compute the difference in seconds between local time and UTC.
local function get_timezone()
    local now = os.time()
    return os.difftime(now, os.time(os.date("!*t", now)))
end

local function is_leap_year(year)
    return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
end

local function get_days_in_month(month, year)
    return month == 2 and is_leap_year(year) and 29 or ("\31\28\31\30\31\30\31\31\30\31\30\31"):byte(month)
end

local function force_range(v, max)
    -- force v to be >= 0 and < max
    if v < 0 then
        return v + max
    elseif v >= max then
        return v - max
    end
    return v
end

-- Adapted from https://github.com/SatAgro/suntime
function solar.sun_time(args)
    if not args then args = {} end
    if not args.lat or not args.long then return nil end
    local lat = args.lat
    local long = args.long
    local sunrise = args.sunrise == nil and true or args.sunrise
    local zenith = args.zenith or 90.8
    local date = args.date or os.date("*t")

    local day = date.day
    local month = date.month
    local year = date.year

    local TO_RAD = math.pi / 180

    -- 1. first calculate the day of the year
    local N1 = math.floor(275 * month / 9)
    local N2 = math.floor((month + 9) / 12)
    local N3 = (1 + math.floor((year - 4 * math.floor(year / 4) + 2) / 3))
    local N = N1 - (N2 * N3) + day - 30

    -- 2. convert the longitude to hour value and calculate an approximate time
    local lngHour = long / 15

    local t
    if sunrise then
        t = N + ((6 - lngHour) / 24)
    else -- sunset
        t = N + ((18 - lngHour) / 24)
    end

    -- 3. calculate the Sun's mean anomaly
    local M = (0.9856 * t) - 3.289

    -- 4. calculate the Sun's true longitude
    local L = M + (1.916 * math.sin(TO_RAD*M)) + (0.020 * math.sin(TO_RAD * 2 * M)) + 282.634
    -- NOTE: L adjusted into the range [0,360)
    L = force_range(L, 360)

    -- 5a. calculate the Sun's right ascension
    local RA = (1 / TO_RAD) * math.atan(0.91764 * math.tan(TO_RAD * L))
    -- NOTE: RA adjusted into the range [0,360)
    RA = force_range(RA, 360)

    -- 5b. right ascension value needs to be in the same quadrant as L
    local Lquadrant = (math.floor(L/90)) * 90
    local RAquadrant = (math.floor(RA/90)) * 90
    RA = RA + (Lquadrant - RAquadrant)

    -- 5c. right ascension value needs to be converted into hours
    RA = RA / 15

    -- 6. calculate the Sun's declination
    local sinDec = 0.39782 * math.sin(TO_RAD * L)
    local cosDec = math.cos(math.asin(sinDec))

    -- 7a. calculate the Sun's local hour angle
    local cosH = (math.cos(TO_RAD*zenith) - (sinDec * math.sin(TO_RAD * lat))) / (cosDec * math.cos(TO_RAD * lat))

    -- The sun never rises on this location (on the specified date)
    if cosH > 1 then
        return nil
    end
    -- The sun never sets on this location (on the specified date)
    if cosH < -1 then
        return nil
    end

    -- 7b. finish calculating H and convert into hours
    local H
    if sunrise then
        H = 360 - (1 / TO_RAD) * math.acos(cosH)
    else -- setting
        H = (1 / TO_RAD) * math.acos(cosH)
    end
    H = H / 15

    -- 8. calculate local mean time of rising/setting
    local T = H + RA - (0.06571 * t) - 6.622

    -- 9a. adjust back to UTC
    local UT = T - lngHour
    -- 9b. adjust to current timezone
    UT = UT + get_timezone() / 3600
    -- time in decimal format in hours (e.g. 23.23)
    UT = force_range(UT, 24)

    -- 10. Return
    local hr = force_range(math.floor(UT), 24)
    local min = helpers.round_number((UT - math.floor(UT)) * 60, 0)
    if min == 60 then
        hr = hr + 1
        min = 0
    end

    -- 10. check corner case https://github.com/SatAgro/suntime/issues/1
    if hr == 24 then
        hr = 0
        day = day + 1

        if day > get_days_in_month(year) then
            day = 1
            month = month + 1

            if month > 12 then
                month = 1
                year = year + 1
            end
        end
    end

    return {day = day, month = month, year = year, hour = hr, min = math.floor(min)}
end

return solar
