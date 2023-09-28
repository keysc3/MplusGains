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

function addon:RoundToOneDecimal(number)
    return math.floor((number* 10) + 0.5) * 0.1
end

function addon:FormateDecimal(number)
    -- Add ending 0 if no decimal
    return (string.match(number, "%.")) and number or number .. ".0"
end