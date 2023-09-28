local _, addon = ...

--[[
    FormatTimer - Formats a dungeon timer to be in mm:ss
    @param totalSeconds - the dungeon time limit in seconds
    @return - the formated string in mm:ss
--]]
function addon:FormatTimer(totalSeconds)
    minutes = totalSeconds / 60
    seconds = 60 * (minutes%1)
    -- Add leading zero
    if seconds < 10 then
        seconds = "0" .. seconds
    end
    return math.floor(minutes) .. ":" .. seconds
end

--[[
    RoundToOneDecimal - Rounds a given number to one decimal place.
    @param number - the number to round
    @return - the rounded number
--]]
function addon:RoundToOneDecimal(number)
    return math.floor((number * 10) + 0.5) * 0.1
end

--[[
    FormatDecimal - Formats a string of a number to have a .0 if it is a whole number.
    @param number - the string to format
    @return - the formatted string
--]]
function addon:FormatDecimal(number)
    return (string.match(number, "%.")) and number or number .. ".0"
end