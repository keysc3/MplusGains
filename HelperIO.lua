local addonName, addon = ...

local myButtons = {}
local selected = { r = 63/255, g = 81/255, b = 181/255, a = 1 }
local hover = { r = 255, g = 255, b = 255, a = 0.1 }
local unselected = { r = 66/255, g = 66/255, b = 66/255, a = 1 }

local myFont = CreateFont("Font")
myFont:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE, MONOCHROME")
myFont:SetTextColor(1, 1, 1, 1)

local frame = CreateFrame("Frame", "Main", UIParent)
frame:SetPoint("CENTER", nil, 0, 100)
frame:SetSize(800, 600)
--frame:Hide()

local frame1 = CreateFrame("Frame", "Row", frame)
frame1:SetPoint("TOPLEFT")
frame1:SetSize(600, 60)

local function CreateNewTexture(red, green, blue, alpha, parent)
    local texture = parent:CreateTexture()
    texture:SetAllPoints()
    texture:SetTexture("Interface\\buttons\\white8x8")
    texture:SetVertexColor(red/255, green/255, blue/255, alpha)
    return texture
end

local startingOffset = 0

local function CreateButton(keyLevel, xOffset, parentFrame)
    local btn = CreateFrame("Button", parentFrame:GetName() .. "Button" .. "+" .. tostring(keyLevel), nil, "BackdropTemplate")
    btn:SetParent(parentFrame)
    btn:SetPoint("LEFT", xOffset, 0)
    btn:SetSize(48, 58)
    btn:SetBackdrop({
        bgFile = "Interface\\buttons\\white8x8",
        edgeFile = "Interface\\buttons\\white8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    btn:SetBackdropColor(unselected.r, unselected.g, unselected.b, unselected.a)
    btn:SetText("+" .. keyLevel)
    btn:SetHighlightTexture(CreateNewTexture(hover.r, hover.g, hover.b, hover.a, btn))
    btn:SetNormalFontObject(myFont)
    return btn
end

local function CreateKeystoneLevelButton(keyLevel, btn)
    local keystoneButtonObject = addon.CreateKeystoneButton(keyLevel, 260)
    btn:SetScript("OnClick", function(self, btn, down)
        if(keystoneButtonObject.isSelected) then
            self:SetBackdropColor(unselected.r, unselected.g, unselected.b, unselected.a)
        else
            self:SetBackdropColor(selected.r, selected.g, selected.b, selected.a)
        end
        keystoneButtonObject.isSelected = not keystoneButtonObject.isSelected
        print("Selected: " .. tostring(keystoneButtonObject.isSelected))
    end)
    return keystoneButtonObject
end

local function CreateButtonRow(parentFrame, startingLevel, numButtons)
    local xOffset = startingOffset
    for i = 1, numButtons - 1 do
        local button = CreateButton(startingLevel, xOffset, parentFrame)
        button.keystoneButton = CreateKeystoneLevelButton(startingLevel, button)
        xOffset = xOffset  + 48
        startingLevel = startingLevel + 1
    end
    local children = {parentFrame:GetChildren()}

    for i, child in ipairs(children) do
        print(i, child:GetObjectType(), child:GetDebugName())
    end
end

CreateButtonRow(frame1, 2, 10)
frame1.texture = CreateNewTexture(40, 40, 40, 1, frame1)
frame.texture = CreateNewTexture(0, 0, 0, 0.5, frame)


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