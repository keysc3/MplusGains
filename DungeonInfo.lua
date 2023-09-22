local _, addon = ...

function addon:FormatTimer(totalSeconds)
    minutes = totalSeconds / 60
    seconds = 60 * (minutes%1)
    if seconds < 10 then
        seconds = "0" .. seconds
    end
    return math.floor(minutes) .. ":" .. seconds
end

function addon:GetGeneralDungeonInfo()
    local dungeonInfo = {}
    local mapChallengeModeIDs = C_ChallengeMode.GetMapTable()
    for i, map in ipairs(mapChallengeModeIDs) do
        local name, id, timeLimit, texture, backgroundTexture = C_ChallengeMode.GetMapUIInfo(map)
        dungeonInfo[name] = {
            ["timeLimit"] = timeLimit,
            ["mythicID"] = map
        }
    end
    addon.dungeonInfo = dungeonInfo 
end