local _, addon = ...

local maxModifier = 0.4

local scorePerLevel  = {0, 40, 45, 50, 55, 60, 75, 80, 85, 90, 97, 104, 111, 128, 135, 
142, 149, 156, 163, 170, 177, 184, 191, 198, 205, 212, 219, 226, 233, 240}

local affixLevels = {
    [2] = {"fortified", "tyrannical"},
    [7] = {"afflicted", "incorporeal", "volcanic", "entangling", "storming"},
    [14] = {"spiteful", "raging", "bolstering", "bursting", "sanguine"}
}

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
        total = addon:RoundToOneDecimal(seasonAffixScore1 * 1.5) + addon:RoundToOneDecimal(seasonAffixScore2 * 0.5)
    else
        total = addon:RoundToOneDecimal(seasonAffixScore1 * 0.5) + addon:RoundToOneDecimal(seasonAffixScore2 * 1.5)
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
    CalculateTotalRating()
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
                    ["rating"] = addon:CalculateRating(affix.durationSec, key, affix.level),
                    ["time"] = affix.durationSec,
                    ["overTime"]  = affix.overTime
                }
                if(string.lower(affix.name) == "tyrannical") then
                    playerBests.tyrannical[key] = dungeonBest
                    if(#affixScores == 1) then playerBests.fortified[key] = CreateNoRunsEntry(value.name) end
                else
                    playerBests.fortified[key] = dungeonBest
                    if(#affixScores == 1) then playerBests.tyrannical[key] = CreateNoRunsEntry(value.name) end
                end
            end
        else
            playerBests.tyrannical[key] = CreateNoRunsEntry(value.name)
            playerBests.fortified[key] = CreateNoRunsEntry(value.name)
        end
    end
    addon.playerBests = playerBests
end

--[[
    CreateNoRunsEntry - Creates a default table for use when a dungeon doens't have a run for an associated week.
    @return - the created default run table.
--]]
function CreateNoRunsEntry(name)
    local dungeonBest = {
        ["level"] = 1,
        ["rating"] = 0,
        ["time"] = 0,
        ["overTime"] = false
    }
    return dungeonBest
end

--[[
    GetWeeklyAffixInfo - Gets and stores the weekly affix info.
    @return - retuns the alternating weekly affix
--]]
function addon:GetWeeklyAffixInfo()
    local weeklyAffix = nil
    local affixInfo = {}
    C_MythicPlus.RequestCurrentAffixes()
    local affixIDs = C_MythicPlus.GetCurrentAffixes()
    if(affixIDs ~= nil) then
        for i, value in ipairs(affixIDs) do
            name, description, filedataid = C_ChallengeMode.GetAffixInfo(value.id)
            affixInfo[value.id] = {
                ["description"] = description,
                ["name"] = name,
                ["filedataid"] = filedataid,
                ["level"] = GetAffixLevel(name)
            }
            if(string.lower(name) == "tyrannical" or string.lower(name) == "fortified") then
                weeklyAffix = string.lower(name)
            end
                
        end 
        addon.affixInfo = affixInfo
    end
    return weeklyAffix
end

--[[
    CalculateTotalRating - Calculates the players overall score for mythic+
--]]
function CalculateTotalRating()
    local total = 0
    for key, value in pairs(addon.playerDungeonRatings) do
        total = total + value.mapScore
    end
    addon.totalRating = total
end

--[[
    CalculateRating - Calculates the exact rating for a dungeon run based on timer.
    @param runTime - the runs time in seconds
    @param dungeonID - the dungeonID the run is from.
    @param level - the level of the dungeon
    @return rating - the score from the run
--]]
function addon:CalculateRating(runTime, dungeonID, level)
    -- ((totaltime - runTime)/(totaltime * maxModifier)) * 5 = bonusScore
    -- Subtract 5 if overtime
    local bonusRating = 0
    local dungeonTimeLimit = addon.dungeonInfo[dungeonID].timeLimit
    -- Runs over time by 40% are a 0 score.
    if(runTime > (dungeonTimeLimit + (dungeonTimeLimit * maxModifier))) then
        return 0
    end
    local numerator = dungeonTimeLimit - runTime
    local denominator = dungeonTimeLimit * maxModifier
    local quotient = numerator/denominator
    
    if(quotient >= 1) then bonusRating = 5
    elseif(quotient <= -1) then bonusRating = -5
    else bonusRating = quotient * 5 end

    if(runTime > dungeonTimeLimit) then
        bonusRating  = bonusRating - 5
    end
    -- Untimed keys over 20 use the base score of a 20.
    if(level > 20 and runTime > dungeonTimeLimit) then
        level = 20
    end
    return scorePerLevel[level] + bonusRating
end

--[[
    CalculateChest - Calculates the dungeon runs performance based on its timer thresholds. 
    @param dungeonID - the id of the dungeon
    @param timeCompleted - the runs time in seconds
    @return - string of the performance
--]]
function addon:CalculateChest(dungeonID, timeCompleted)
    local timeLimit = addon.dungeonInfo[dungeonID].timeLimit
    if(timeCompleted <= (timeLimit * 0.6)) then return "+++" end
    if(timeCompleted <= (timeLimit * 0.8)) then return "++" end
    if(timeCompleted <= timeLimit) then return "+" end
    return ""
end

--[[
    SortDungeonByScore - Sorts the dungeons by their total contributing score.
    return - an array of dungeonIDs indexed by descending score.
--]]
function addon:SortDungeonsByScore()
    -- Put mapIDs into an array
    local array = {}
    for k, v in pairs(addon.dungeonInfo) do
        table.insert(array, k)
    end
    -- Sort the mapIDs by their mapScores
    table.sort(array, function(id1, id2)
        return addon.playerDungeonRatings[id1].mapScore > addon.playerDungeonRatings[id2].mapScore
        end)

    return array
end

--[[
    SortDungeonByLevl - Sorts the dungeons by their best completed levels
    @param weeklyAffix - the weekly affix for the runs being sorted.
    return - an array of dungeonIDs indexed by ascending completed level.
    Note: Ties are sorted by score.
--]]
function addon:SortDungeonsByLevel(weeklyAffix)
    -- Put mapIDs into an array
    local array = {}
    for k, v in pairs(addon.dungeonInfo) do
        table.insert(array, k)
    end
    -- Sort the mapIDs by their levels, ratings if ties, overall map rating if no run for both the dungeons
    table.sort(array, function(id1, id2)
        id1_level = addon.playerBests[weeklyAffix][id1].level
        id2_level = addon.playerBests[weeklyAffix][id2].level
        if(id1_level ~= 1 and id2_level ~= 1) then
            if(id1_level ~= id2_level) then
                return id1_level < id2_level
            end
            return addon.playerBests[weeklyAffix][id1].rating < addon.playerBests[weeklyAffix][id2].rating
        end
        return addon.playerDungeonRatings[id1].mapScore < addon.playerDungeonRatings[id2].mapScore
    end)
    return array
end

--[[
    GetAffixLevel - Gets the level an affix starts at given its name
    @param name - name of the affix
    @return - level the affix starts at.
--]]
function GetAffixLevel(name)
    for key, value in pairs(affixLevels) do
        for _, v in ipairs(value) do
            if(v == string.lower(name)) then
                return key
            end
        end
    end
    return 0
end

--[[
    SortAffixesByLevel - Sorts affixes by the level they are added to the keystone in ascending order.
--]]
function addon:SortAffixesByLevel()
    local array = {}
    for k, v in pairs(addon.affixInfo) do
        table.insert(array, k)
    end
    -- Sort the affixIds by their level
    table.sort(array, function(id1, id2)
        return addon.affixInfo[id1].level < addon.affixInfo[id2].level
        end)

    return array
end

--[[
    SetNewBest - Sets a dungeons best run to the given one.
    @param dungeonID - the dungeons ID
    @param level - the completed level
    @param time - the time completed in
    @param weeklyAffix - the weekly affix
    @param onTime - bool for if the key was completed on time
--]]
function addon:SetNewBest(dungeonID, level, time, weeklyAffix, onTime)
    local entry = addon.playerBests[weeklyAffix][dungeonID]
    entry.level = level
    entry.time = time/1000
    entry.rating = addon:CalculateRating(time/1000, dungeonID, level)
    entry.overTime = not onTime
end