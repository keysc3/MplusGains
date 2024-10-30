local _, addon = ...

local maxModifier = 0.4

local scorePerLevel = {0, 165, 180, 205, 220, 235, 265, 280, 295, 320, 335, 365, 380, 395, 410, 425,
 440, 455, 470, 485, 500, 515, 530, 545, 560, 575, 590, 605, 620, 635}

local affixLevels = {[1] = 2, [2] = 4, [3] = 7, [4] = 10, [5] = 12}

addon.scorePerLevel = scorePerLevel
addon.scoresSet = false

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
    GetPlayerDungeonBests - Gets and stores the current characters best dungeon run per dungeon.
--]]
function addon:GetPlayerDungeonBests()
    local playerBests = {}
    for key, value in pairs(addon.dungeonInfo) do
        local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(key)
        -- Check for nils before adding an entry.
        if(intimeInfo ~= nil or overtimeInfo ~= nil) then
            local bestInfo = intimeInfo
            if(intimeInfo ~= nil and overtimeInfo ~= nil) then
                local intimeScore = addon:CalculateRating(intimeInfo.durationSec, key, intimeInfo.level)
                local overtimeScore = addon:CalculateRating(overtimeInfo.durationSec, key, overtimeInfo.level)
                bestInfo = (intimeScore > overtimeScore) and intimeInfo or overtimeInfo
            else
                if(intimeInfo == nil) then 
                    bestInfo = overtimeInfo 
                end
            end
            dungeonBest = {
                ["level"] = bestInfo.level,
                ["rating"] = addon:CalculateRating(bestInfo.durationSec, key, bestInfo.level),
                ["time"] = bestInfo.durationSec
            }
            playerBests[key] = dungeonBest
            if(not addon.scoresSet) then 
                addon.scoresSet = true
            end
        else
            playerBests[key] = CreateNoRunsEntry()
        end
    end
    addon.playerBests = playerBests
    CalculateTotalRating()
end

--[[
    CreateNoRunsEntry - Creates a default table for use when a dungeon doens't have a run for an associated week.
    @return - the created default run table.
--]]
function CreateNoRunsEntry()
    local dungeonBest = {
        ["level"] = 1,
        ["rating"] = 0,
        ["time"] = 0
    }
    return dungeonBest
end

--[[
    GetWeeklyAffixInfo - Gets and stores the weekly affix info.
    @return - retuns the alternating weekly affix
--]]
function addon:GetWeeklyAffixInfo()
    local affixInfo = {}
    C_MythicPlus.RequestCurrentAffixes()
    local affixIDs = C_MythicPlus.GetCurrentAffixes()
    if(affixIDs ~= nil) then
        for i, value in ipairs(affixIDs) do
            local name, description, filedataid = C_ChallengeMode.GetAffixInfo(value.id)
            newArray = {
                ["id"] = value.id,
                ["description"] = description,
                ["name"] = name,
                ["filedataid"] = filedataid,
                ["level"] = affixLevels[i]
            }
            table.insert(affixInfo, newArray)  
        end
        addon.affixInfo = affixInfo
    end
end

--[[
    CalculateTotalRating - Calculates the players overall score for mythic+
--]]
function CalculateTotalRating()
    local total = 0
    for key, value in pairs(addon.playerBests) do
        total = total + value.rating
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
    local baseBonus = 15
    local untimedBase = 10
    -- ((totaltime - runTime)/(totaltime * maxModifier)) * baseBonuse = bonusScore
    -- Subtract baseBonuse if overtime
    local bonusRating = 0
    local dungeonTimeLimit = addon.dungeonInfo[dungeonID].timeLimit
    -- Runs over time by 40% are a 0 score.
    if(runTime > (dungeonTimeLimit + (dungeonTimeLimit * maxModifier))) then
        return 0
    end
    local numerator = dungeonTimeLimit - runTime
    local denominator = dungeonTimeLimit * maxModifier
    local quotient = numerator/denominator

    if(quotient >= 1) then bonusRating = baseBonus
    elseif(quotient <= -1) then bonusRating = -(baseBonus)
    else bonusRating = quotient * baseBonus end

    if(runTime > dungeonTimeLimit) then
        bonusRating  = bonusRating - baseBonus
    end
    -- Untimed keys base change
    if(level > untimedBase and runTime > dungeonTimeLimit) then
        level = untimedBase
    end
    return scorePerLevel[level] + addon:RoundToOneDecimal(bonusRating)
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
        return addon.playerBests[id1].rating > addon.playerBests[id2].rating
        end)

    return array
end

--[[
    GetStartingLevel - Gets the lowest dungeon level it is possible to get rating from and returns it.
    @param dungeonID - the ID of the dungeon to be checked.
    @return - the lowest key level the player can get rating from for the dungeon.
--]]
function addon:GetStartingLevel(dungeonID)
    local best = addon.playerBests[dungeonID]
    local baseLevel = best.level
    for i = best.level + 1, 2, -1 do
        -- Find lowest key that gives more min rating than best rating
        if(addon.scorePerLevel[i] >= best.rating) then
            if(addon.scorePerLevel[i] == best.rating) then
                baseLevel = i + 1
                break
            end
            baseLevel = i
        else
            break
        end
    end
    return baseLevel
end

--[[
    SortDungeonByLevel - Sorts the dungeons by their best completed levels
    return - an array of dungeonIDs indexed by ascending completed level.
--]]
function addon:SortDungeonsByLevel()
    -- Put mapIDs into an array
    local array = {}
    for k, v in pairs(addon.dungeonInfo) do
        table.insert(array, k)
    end
    -- Sort the mapIDs by their levels, ratings if ties, overall map rating if no run for both the dungeons
    table.sort(array, function(id1, id2)
        id1_level = addon:GetStartingLevel(id1)
        id2_level = addon:GetStartingLevel(id2)
        if(id1_level ~= 1 and id2_level ~= 1) then
            if(id1_level ~= id2_level) then
                return id1_level < id2_level
            end
        end
        return addon.playerBests[id1].rating < addon.playerBests[id2].rating
    end)
    return array
end

--[[
    SortAffixesByLevel - Sorts affixes by the level they are added to the keystone in ascending order.
--]]
--[[function addon:SortAffixesByLevel()
    local array = {}
    for k, v in pairs(addon.affixInfo) do
        table.insert(array, k)
    end
    -- Sort the affixIds by their level
    table.sort(array, function(id1, id2)
        return addon.affixInfo[id1].level < addon.affixInfo[id2].level
        end)

    return array
end--]]

--[[
    SetNewBest - Sets a dungeons best run to the given one.
    @param dungeonID - the dungeons ID
    @param level - the completed level
    @param time - the time completed in
--]]
function addon:SetNewBest(dungeonID, level, time)
    local entry = addon.playerBests[dungeonID]
    entry.level = level
    entry.time = time/1000
    entry.rating = addon:CalculateRating(time/1000, dungeonID, level)
    CalculateTotalRating()
end