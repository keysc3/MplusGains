--[[local frame = CreateFrame("Frame", nil, UIParent)
frame:SetPoint("CENTER")
frame:SetSize(200, 150)

frame.texture = frame:CreateTexture()
frame.texture:SetAllPoints()
frame.texture:SetColorTexture(0, 0, 0, 0.5)

frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetScript("OnHide", frame.StopMovingOrSizing)--]]

--[[local affixScores, bestOverAllScore = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(438)

for i, affix in ipairs(affixScores) do
    print(affix.name .. " " .. affix.score .. " " .. affix.level .. " " .. affix.durationSec)
    --print(affix.name)
end

print(bestOverAllScore)--]]

local function FormatTimer(totalSeconds)
    minutes = totalSeconds / 60
    seconds = 60 * (minutes%1)
    if seconds < 10 then
        seconds = "0" .. seconds
    end
    return math.floor(minutes) .. ":" .. seconds
end

local function GetGeneralDungeonInfo()
    local mapChallengeModeIDs = C_ChallengeMode.GetMapTable()
    for i, map in ipairs(mapChallengeModeIDs) do
        local name, id, timeLimit, texture, backgroundTexture = C_ChallengeMode.GetMapUIInfo(map)
        print("MapInfo: " .. name ..  " " .. FormatTimer(timeLimit) .. "!")
    end
end


GetGeneralDungeonInfo()