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

function addon:GetPlayerDungeonBests()
    local playerBests = {
        ["tyrannical"] = {},
        ["fortified"] = {}
    }
    for key, value in pairs(addon.dungeonInfo) do
        local affixScores, bestOverAllScore = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(value.mythicID)
        for i, affix in ipairs(affixScores) do
            dungeonBest = {
               ["level"] = affix.level,
               ["rating"] = affix.score,
               ["time"] = affix.durationSec,
            }
            if(string.lower(affix.name) == "tyrannical") then
                playerBests.tyrannical[key] = dungeonBest
            else
                playerBests.fortified[key] = dungeonBest
            end
        end
    end
    addon.playerBests = playerBests
end