local _, addon = ...

local maxModifier = 0.4

local scorePerLevel  = {40, 45, 50, 55, 60, 75, 80, 85, 90, 97, 104, 111, 128, 135, 
142, 149, 156, 163, 170, 177, 184, 191, 198, 205, 212, 219, 226, 233, 240}

addon.scorePerLevel = scorePerLevel

function addon:GetPlayerSummary()
    local ratingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
    addon.playerSeasonScore = ratingSummary.currentSeasonScore
    local playerDungeonRatings = {}
    for i, value in ipairs(ratingSummary.runs) do
        playerDungeonRatings[value.challengeModeID] = {
            ["mapScore"] = value.mapScore
        }
    end
    addon.playerDungeonRatings = playerDungeonRatings
end


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
    GetGeneralDungeonInfo - Gets and stores the current mythic+ dungeons and their time limits.
--]]
function addon:GetGeneralDungeonInfo()
    local dungeonInfo = {}
    local mapChallengeModeIDs = C_ChallengeMode.GetMapTable()
    for i, map in ipairs(mapChallengeModeIDs) do
        local name, id, timeLimit, texture, backgroundTexture = C_ChallengeMode.GetMapUIInfo(map)
        dungeonInfo[map] = {
            ["timeLimit"] = timeLimit,
            ["name"] = name
        }
    end
    addon.dungeonInfo = dungeonInfo 
end

--[[
    GetGeneralDungeonInfo - Gets and stores the current characters best dungeon run per affix per dungeon.
--]]
function addon:GetPlayerDungeonBests()
    local playerBests = {
        ["tyrannical"] = {},
        ["fortified"] = {}
    }
    for key, value in pairs(addon.dungeonInfo) do
        local affixScores, bestOverAllScore = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(key)
        for i, affix in ipairs(affixScores) do
            dungeonBest = {
               ["level"] = affix.level,
               ["rating"] = scorePerLevel[affix.level - 1] + CalculateRating(affix.durationSec, key),
               ["time"] = affix.durationSec,
               ["name"] = value.name
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

--[[
    CalculateRating - Calculates the exact rating for a dungeon run based on timer.
    @param runTime - the runs time in seconds
    @param dungeonName - the dungeon name the run is from.
    @return rating - the score from the run
--]]
function CalculateRating(runTime, dungeonName)
    -- ((totaltime - runTime)/(totaltime * maxModifier)) * 5 = bonusScore
    -- Subtract 5 if overtime
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