local addonName, addon = ...

local myButtons = {}
local selected = { r = 63/255, g = 81/255, b = 181/255, a = 1 }
local hover = { r = 255, g = 255, b = 255, a = 0.1 }
local unselected = { r = 66/255, g = 66/255, b = 66/255, a = 1 }
local mouseDown = false
local cursorX, cursorY
local maxScrollRange = 0
local maxLevel = 10

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

local frame2 = CreateFrame("Frame", "Test", frame1)
frame2:SetPoint("LEFT")
local text = frame2:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("Left")
text:SetText("Test")
frame2:SetSize(text:GetStringWidth(), frame1:GetHeight())

local frame3 = CreateFrame("Frame", "Test", frame1)
frame3:SetPoint("LEFT", frame2, "RIGHT")
local text = frame3:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("Left")
text:SetText("238")
frame3:SetSize(text:GetStringWidth(), frame1:GetHeight())

print("TEXT WIDTH: " .. text:GetStringWidth())

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
    btn:SetScript("OnMouseUp", function(self, btn, down)
        mouseDown = false
        if(keystoneButtonObject.isSelected) then
            self:SetBackdropColor(unselected.r, unselected.g, unselected.b, unselected.a)
        else
            self:SetBackdropColor(selected.r, selected.g, selected.b, selected.a)
        end
        keystoneButtonObject.isSelected = not keystoneButtonObject.isSelected
        print("Selected: " .. tostring(keystoneButtonObject.isSelected))
    end)
    btn:SetScript("OnMouseDown", function(self, btn, down)
        mouseDown = true
        cursorX, cursorY = GetCursorPosition()
        print("HOR SCROLL: " .. parentScroll:GetHorizontalScroll() .. "MAX: " .. parentFrame.maxScrollRange)
    end)
    btn:SetScript("OnUpdate", function(self, btn, down)
        local x, y = GetCursorPosition()
        --print("HOR SCROLL: " .. parentScroll:GetHorizontalScroll() .. "MAX: " .. btn:GetParent().maxScrollRange)
        if(mouseDown) then
            local diff = math.abs(cursorX - x)*1.36
            if(cursorX < x and parentScroll:GetHorizontalScroll() > 0) then
                newPos = parentScroll:GetHorizontalScroll() - diff
                parentScroll:SetHorizontalScroll(( newPos < 0) and 0 or newPos)
            elseif(cursorX > x and parentScroll:GetHorizontalScroll() < parentFrame.maxScrollRange) then
                newPos = parentScroll:GetHorizontalScroll() + diff
                parentScroll:SetHorizontalScroll(( newPos > parentFrame.maxScrollRange) and parentFrame.maxScrollRange or newPos)
            end
        end
        cursorX, cursorY = GetCursorPosition()
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

local scrollHolder = CreateFrame("Frame", nil, frame1)
scrollHolder:SetPoint("LEFT", frame3, "RIGHT")
scrollHolder:SetSize(300, frame1:GetHeight())

local rowFrame = CreateFrame("Frame", "Row1")
rowFrame:SetPoint("LEFT", frame3, "RIGHT")
rowFrame:SetSize(0, 60)

local scrollFrame = CreateFrame("ScrollFrame", "testScrollFrame", scrollHolder, "UIPanelScrollFrameCodeTemplate")
local scrollbarName = scrollFrame:GetName();
--local scrollbar =  _G[scrollBarName.."ScrollBar"];
scrollFrame:SetPoint("TOPLEFT")
scrollFrame:SetPoint("BOTTOMRIGHT")
--scrollbar:SetMinMaxValues(0, 100)
scrollFrame:SetScrollChild(rowFrame)

--[[local scrollFrame = CreateFrame("ScrollFrame", "myScrollFrame", scrollHolder, "UIPanelScrollFrameTemplate")
local scrollbarName = scrollFrame:GetName()
scrollFrame.scrollbar = _G[scrollbarName.."ScrollBar"];
scrollFrame.scrollupbutton = _G[scrollbarName.."ScrollBarScrollUpButton"];
scrollFrame.scrolldownbutton = _G[scrollbarName.."ScrollBarScrollDownButton"];
scrollFrame.scrollbar:SetOrientation('HORIZONTAL')
scrollFrame.scrollbar:SetPoint("TOPLEFT", scrollHolder, "BOTTOMLEFT")
scrollFrame.scrolldownbutton:ClearAllPoints()
scrollFrame.scrolldownbutton:SetPoint("TOPLEFT", scrollHolder, "BOTTOMLEFT")
scrollFrame.scrollupbutton:ClearAllPoints()
scrollFrame.scrollupbutton:SetPoint("TOPRIGHT", scrollHolder, "BOTTOMRIGHT")
scrollFrame.scrollbar:ClearAllPoints()
scrollFrame.scrollbar:SetPoint("TOP", scrollFrame.scrollupbutton, "BOTTOM", 0, -2);
scrollFrame.scrollbar:SetPoint("BOTTOM", scrollFrame.scrolldownbutton, "TOP", 0, 2);
--scrollFrame.scrollbar:SetPoint("LEFT", scrollFrame.scrolldownbutton, "RIGHT", -2, 0);
scrollFrame:SetPoint("TOPLEFT")
scrollFrame:SetPoint("BOTTOMRIGHT")
scrollFrame:SetScrollChild(rowFrame)
print("RANGE: " .. scrollFrame:GetVerticalScrollRange())--]]

CreateButtonRow(rowFrame, 2)
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