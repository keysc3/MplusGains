local addonName, addon = ...
local frame = CreateFrame("Frame", nil, UIParent)
frame:SetPoint("CENTER", nil, 0, 100)
frame:SetSize(800, 600)

local function CreateNewTexture(red, green, blue, alpha, parent)
    texture = parent:CreateTexture()
    texture:SetAllPoints()
    texture:SetColorTexture(red/255, green/255, blue/255, alpha)
    return texture
end

frame.texture = CreateNewTexture(0, 0, 0, 0.5, frame)

local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
btn:SetPoint("CENTER")
btn:SetSize(50, 60)
btn:SetText("+10")

local font = btn:GetNormalFontObject()
font:SetTextColor(1, 1, 1 , 1)

local isSelected = false
local unselected = CreateNewTexture(66, 66, 66, 1, btn)
local selected = CreateNewTexture(63, 81, 181, 1, btn)
local selectedHighlight = CreateNewTexture(255, 255, 255, 0.1, btn)
btn:SetNormalTexture(unselected)
btn:SetHighlightTexture(selectedHighlight)

btn:SetScript("OnClick", function(self, btn, down)
    if(isSelected) then
        self:SetNormalTexture(unselected)
    else
        self:SetNormalTexture(selected)
    end
    isSelected = not isSelected
end)


--[[local function ToggleButton(widget, button, down)
    widget:SetNormalTexture(selected)
end--]]
--btn:SetText("Click me")


--[[frame:EnableMouse(true)
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