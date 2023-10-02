local _, addon = ...

local maxModifier = 0.4

local scorePerLevel  = {0, 40, 45, 50, 55, 60, 75, 80, 85, 90, 97, 104, 111, 128, 135, 
142, 149, 156, 163, 170, 177, 184, 191, 198, 205, 212, 219, 226, 233, 240}

addon.scorePerLevel = scorePerLevel

--[[
    CalculateDungeonTotal - Calculates a dungeons overall score contributing to a players rating.
    @param seasonAffixScore1 - best score for dungeon for a weekly affix
    @param seasonAffixScore2 - best score for dungeon for a weekly affix
    @return - the total rating for the dungeons scores
--]]
function addon:CalculateDungeonTotal(seasonAffixScore1, seasonAffixScore2)
    local total
    if(seasonAffixScore1 > seasonAffixScore2) then
        total = (seasonAffixScore1 * 1.5) + (seasonAffixScore2 * 0.5)
    else
        total = (seasonAffixScore1 * 0.5) + (seasonAffixScore2 * 1.5)
    end
    return addon:RoundToOneDecimal(total)
end

--[[
    CalculateDungeonRatings - Calculates and stores the total rating a dungeon is giving the player.
--]]
function addon:CalculateDungeonRatings()
    local playerDungeonRatings = {}
    for key, value in pairs(addon.playerBests["tyrannical"]) do
        local bestTyran = value.rating
        local bestFort = addon.playerBests["fortified"][key].rating
        playerDungeonRatings[key] = {
            ["mapScore"] = addon:CalculateDungeonTotal(bestTyran, bestFort)
        }
    end
    addon.playerDungeonRatings = playerDungeonRatings
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
        if(affixScores ~= nil) then
            for i, affix in ipairs(affixScores) do
                dungeonBest = {
                ["level"] = affix.level,
                ["rating"] = scorePerLevel[affix.level] + CalculateRating(affix.durationSec, key),
                ["time"] = affix.durationSec,
                ["name"] = value.name
                }
                if(string.lower(affix.name) == "tyrannical") then
                    playerBests.tyrannical[key] = dungeonBest
                else
                    playerBests.fortified[key] = dungeonBest
                end
            end
        else
            playerBests.tyrannical[key] = CreateNoRunsEntry(value.name)
            playerBests.fortified[key] = CreateNoRunsEntry(value.name)
        end
    end
    addon.playerBests = playerBests
end

function CreateNoRunsEntry(name)
    local dungeonBest = {
        ["level"] = 1,
        ["rating"] = 0,
        ["time"] = 0,
        ["name"] = name
    }
    return dungeonBest
end

--[[
    GetWeeklyAffixInfo - Gets and stores the weekly affix info.
    @return - retuns the alternating weekly affix
--]]
function addon:GetWeeklyAffixInfo()
    local weeklyAffix = ""
    local affixInfo = {}
    C_MythicPlus.RequestMapInfo()
    local affixIDs = C_MythicPlus.GetCurrentAffixes()
    for i, value in ipairs(affixIDs) do
        name, description, filedataid = C_ChallengeMode.GetAffixInfo(value.id)
        affixInfo[name] = {
            ["description"] = description,
            ["id"] = id
        }
        if(string.lower(name) == "tyrannical" or string.lower(name) == "fortified") then
            weeklyAffix = string.lower(name)
        end
            
    end 
    addon.affixInfo = affixInfo
    return weeklyAffix
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
    return addon:RoundToOneDecimal(rating)
end