local addonName, addon = ...

local myButtons = {}
local selected = { r = 63/255, g = 81/255, b = 181/255, a = 1 }
local hover = { r = 255, g = 255, b = 255, a = 0.1 }
local unselected = { r = 66/255, g = 66/255, b = 66/255, a = 1 }
local mouseDown = false
local currX, currY
local origX, origY
local maxScrollRange = 0
local maxLevel = 30

local myFont = CreateFont("Font")
myFont:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE, MONOCHROME")
myFont:SetTextColor(1, 1, 1, 1)

local function CreateNewTexture(red, green, blue, alpha, parent)
    local texture = parent:CreateTexture()
    texture:SetAllPoints()
    texture:SetTexture("Interface\\buttons\\white8x8")
    texture:SetVertexColor(red/255, green/255, blue/255, alpha)
    return texture
end

local function CreateMainFrame()
    local frame = CreateFrame("Frame", "Main", UIParent)
    frame:SetPoint("CENTER", nil, 0, 100)
    frame:SetSize(1000, 600)
    frame.texture = CreateNewTexture(0, 0, 0, 0.5, frame)
    return frame
end

local mainFrame = CreateMainFrame()

local function CreateDungeonRow(name)
    local frame = CreateFrame("Frame", name .. "_ROW", mainFrame)
    frame:SetPoint("TOPLEFT")
    frame:SetSize(600, 60)
    frame.texture = CreateNewTexture(40, 40, 40, 1, frame)
    return frame
end

local row1 = CreateDungeonRow("ULD")

local function CreateDungeonNameFrame(name, parentRow)
    local frame = CreateFrame("Frame", name .. "_TEXT", parentRow)
    frame:SetPoint("LEFT")
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT")
    text:SetText(name)
    frame:SetSize(text:GetStringWidth(), parentRow:GetHeight())
    return frame
end

local dungeonNameFrame = CreateDungeonNameFrame("ULDAMAN", row1)

local function CreateCurrentScoreFrame(score, parentRow, anchorFrame)
    local frame = CreateFrame("Frame", "Test", parentRow)
    frame:SetPoint("LEFT", anchorFrame, "RIGHT")
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetText(score)
    frame:SetSize(text:GetStringWidth(), row1:GetHeight())
    return frame
end

local currentScoreFrame = CreateCurrentScoreFrame(100, row1, dungeonNameFrame)

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
    btn:SetSize(48, parentFrame:GetHeight())
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

local function CreateKeystoneLevelButton(keyLevel, btn, parentScroll, parentFrame)
    local keystoneButtonObject = addon.CreateKeystoneButton(keyLevel, 260)
    btn:SetScript("OnMouseUp", function(self, btn)
        mouseDown = false
        local x, y = GetCursorPosition()
        if(math.ceil(origX) == math.ceil(x)) then 
            if(keystoneButtonObject.isSelected) then
                self:SetBackdropColor(unselected.r, unselected.g, unselected.b, unselected.a)
            else
                self:SetBackdropColor(selected.r, selected.g, selected.b, selected.a)
            end
            keystoneButtonObject.isSelected = not keystoneButtonObject.isSelected
            print("Selected: " .. tostring(keystoneButtonObject.isSelected))
        end
    end)
    btn:SetScript("OnMouseDown", function(self, btn)
        mouseDown = true
        origX, origY = GetCursorPosition()
        currX, currY = GetCursorPosition()
    end)
    btn:SetScript("OnUpdate", function(self, btn, down)
        local x, y = GetCursorPosition()
        if(mouseDown) then
            local diff = math.abs(currX - x)*1.36
            if(currX < x and parentScroll:GetHorizontalScroll() > 0) then
                newPos = parentScroll:GetHorizontalScroll() - diff
                parentScroll:SetHorizontalScroll(( newPos < 0) and 0 or newPos)
            elseif(currX > x and parentScroll:GetHorizontalScroll() < parentFrame.maxScrollRange) then
                newPos = parentScroll:GetHorizontalScroll() + diff
                parentScroll:SetHorizontalScroll(( newPos > parentFrame.maxScrollRange) and parentFrame.maxScrollRange or newPos)
            end
        end
        currX, currY = GetCursorPosition()
    end)
    return keystoneButtonObject
end

local function CreateButtonRow(parentFrame, startingLevel)
    local totalRowWidth = ((maxLevel + 1) - startingLevel) * 48
    local diff = totalRowWidth - 300
    parentFrame.maxScrollRange = (diff > 0) and diff or 0
    parentFrame:SetWidth(totalRowWidth)
    local xOffset = startingOffset
    for i = 1, maxLevel - 1 do
        local button = CreateButton(startingLevel, xOffset, parentFrame)
        button.keystoneButton = CreateKeystoneLevelButton(startingLevel, button, parentFrame:GetParent(), parentFrame)
        xOffset = xOffset  + 48
        startingLevel = startingLevel + 1
    end
end

local scrollHolder = CreateFrame("Frame", nil, row1)
scrollHolder:SetPoint("LEFT", currentScoreFrame, "RIGHT")
scrollHolder:SetSize(300, row1:GetHeight())

local rowFrame = CreateFrame("Frame", "Row1")
rowFrame:SetPoint("LEFT", currentScoreFrame, "RIGHT")
rowFrame:SetSize(0, 60)

local scrollFrame = CreateFrame("ScrollFrame", "testScrollFrame", scrollHolder, "UIPanelScrollFrameCodeTemplate")
local scrollbarName = scrollFrame:GetName();
--local scrollbar =  _G[scrollBarName.."ScrollBar"];
scrollFrame:SetPoint("TOPLEFT")
scrollFrame:SetPoint("BOTTOMRIGHT")
--scrollbar:SetMinMaxValues(0, 100)
scrollFrame:SetScrollChild(rowFrame)

CreateButtonRow(rowFrame, 2)

local frame4 = CreateFrame("Frame", "Test", row1)
frame4:SetPoint("LEFT", scrollHolder, "RIGHT")
local text = frame4:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("LEFT")
text:SetText("HELLO")
frame4:SetSize(text:GetStringWidth(), row1:GetHeight())


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