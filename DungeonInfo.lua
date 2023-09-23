local _, addon = ...

local scorePerLevel  = {40, 45, 50, 55, 60, 75, 80, 85, 90, 97, 104, 111, 128, 135, 
142, 149, 156, 163, 170, 177, 184, 191, 198, 205, 212, 219, 226, 233, 240}

local maxModifier = 0.4

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
               ["rating"] = scorePerLevel[affix.level - 1] + CalculateRating(affix.durationSec, key),
               ["time"] = affix.durationSec
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

-- Bonus score calculation
-- ((totaltime - runTime)/(totaltime * maxModifier)) * 5 = bonusScore
-- Subtract 5 if overtime
function CalculateRating(runTime, dungeonName)
    dungeonTimeLimit = addon.dungeonInfo[dungeonName].timeLimit
    numerator = dungeonTimeLimit - runTime
    denominator = dungeonTimeLimit * maxModifier
    rating = (numerator/denominator) * 5
    if(runTime > dungeonTimeLimit) then
        rating = rating - 5
    end
    rating = tonumber(string.format("%.1f", rating))
    return rating
end