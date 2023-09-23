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

-- Undertime
-- ((totaltime - runTime)/(totaltime - totaltime*0.6)) * 5 = bonusScore
-- Overtime
-- (abs(((totaltime - runTime))/(totaltime - totaltime*0.6)) * 5) + 5 = lostScore
local addonName, addon = ...
print(string.format("Welcome to %s.", addonName))
addon:GetGeneralDungeonInfo()
addon:GetPlayerDungeonBests()

for key, value in pairs(addon.dungeonInfo) do
    print(string.format("MapInfo: %s %s!", key, addon:FormatTimer(value.timeLimit)))
end

for key, value in pairs(addon.playerBests) do
    print(string.format("Best for %s:", key))
    for k, v in pairs(value) do
        rating = v.rating
        if(not string.match(rating, "%.")) then
            rating = rating .. ".0"
        end
        print(k, v.level, rating, v.time)
    end
end