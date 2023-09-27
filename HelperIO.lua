local addonName, addon = ...

local myButtons = {}
local selected = { r = 63/255, g = 81/255, b = 181/255, a = 1 }
local hover = { r = 255, g = 255, b = 255, a = 0.1 }
local unselected = { r = 66/255, g = 66/255, b = 66/255, a = 1 }
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

local function CreateDungeonRow(name, anchorFrame)
    local frame = CreateFrame("Frame", name .. "_ROW", mainFrame)
    if(anchorFrame == nil) then
        frame:SetPoint("TOPLEFT")
    else
        frame:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT")
    end
    frame:SetSize(600, 60)
    frame.texture = CreateNewTexture(40, 40, 40, 1, frame)
    return frame
end

local function CreateDungeonNameFrame(name, parentRow)
    local frame = CreateFrame("Frame", name .. "_TEXT", parentRow)
    frame:SetPoint("LEFT")
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT")
    text:SetText(name)
    frame:SetSize(150, parentRow:GetHeight())
    return frame
end

local function CreateCurrentScoreFrame(score, parentRow, anchorFrame)
    local frame = CreateFrame("Frame", "Test", parentRow)
    frame:SetPoint("LEFT", anchorFrame, "RIGHT")
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT")
    if(not string.match(score, "%.")) then
        score = score .. ".0"
    end
    text:SetText(score)
    frame:SetSize(40, parentRow:GetHeight())
    return frame
end

local function CreateNewTexture(red, green, blue, alpha, parent)
    local texture = parent:CreateTexture()
    texture:SetAllPoints()
    texture:SetTexture("Interface\\buttons\\white8x8")
    texture:SetVertexColor(red/255, green/255, blue/255, alpha)
    return texture
end

local function CreateButton(keyLevel, anchorButton, parentFrame)
    print("KEYLEVEL: " .. keyLevel)
    local btn = CreateFrame("Button", parentFrame:GetName() .. "Button" .. "+" .. tostring(keyLevel), nil, "BackdropTemplate")
    btn:SetParent(parentFrame)
    if(anchorButton ~= nil) then 
        btn:SetPoint("LEFT", anchorButton, "RIGHT")
    else
        btn:SetPoint("LEFT", parentFrame, "LEFT")
    end
    btn:SetSize(48, parentFrame:GetHeight())
    btn:SetBackdrop({
        bgFile = "Interface\\buttons\\white8x8",
        edgeFile = "Interface\\buttons\\white8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    if(keyLevel ~= parentFrame.startingLevel) then
        btn:SetBackdropColor(unselected.r, unselected.g, unselected.b, unselected.a)
    else
        btn:SetBackdropColor(selected.r, selected.g, selected.b, selected.a)
    end
    btn:SetText("+" .. keyLevel)
    btn:SetHighlightTexture(CreateNewTexture(hover.r, hover.g, hover.b, hover.a, btn))
    btn:SetNormalFontObject(myFont)
    return btn
end

local function SelectButtons(parentFrame, keystoneButton)
    if(keystoneButton.index > parentFrame.selectedIndex) then
        for i = parentFrame.selectedIndex + 1, keystoneButton.index do
            parentFrame.buttons[i]:SetBackdropColor(selected.r, selected.g, selected.b, selected.a)
        end
    end
    if(keystoneButton.index < parentFrame.selectedIndex) then
        for i = parentFrame.selectedIndex, keystoneButton.index + 1, - 1 do
            parentFrame.buttons[i]:SetBackdropColor(unselected.r, unselected.g, unselected.b, unselected.a)
        end
    end
    parentFrame.selectedIndex = keystoneButton.index
end

local function SetKeystoneButtonScripts(keystoneButton, parentFrame, parentScroll)
    keystoneButton.button:SetScript("OnMouseUp", function(self, btn)
        keystoneButton.mouseDown = false
        local x, y = GetCursorPosition()
        if(math.ceil(origX) == math.ceil(x)) then 
            if(keystoneButton.index ~= parentFrame.selectedIndex) then
                SelectButtons(parentFrame, keystoneButton)
            end
        end
    end)
    keystoneButton.button:SetScript("OnMouseDown", function(self, btn)
        keystoneButton.mouseDown = true
        origX, origY = GetCursorPosition()
        currX, currY = origX, origY
    end)
    keystoneButton.button:SetScript("OnUpdate", function(self, btn, down)
        if(keystoneButton.mouseDown) then
            local x, y = GetCursorPosition()
            local diff = math.abs(currX - x)*1.36
            if(currX < x and parentScroll:GetHorizontalScroll() > 0) then
                newPos = parentScroll:GetHorizontalScroll() - diff
                parentScroll:SetHorizontalScroll(( newPos < 0) and 0 or newPos)
            elseif(currX > x and parentScroll:GetHorizontalScroll() < parentFrame.maxScrollRange) then
                newPos = parentScroll:GetHorizontalScroll() + diff
                parentScroll:SetHorizontalScroll(( newPos > parentFrame.maxScrollRange) and parentFrame.maxScrollRange or newPos)
            end
            currX, currY = GetCursorPosition()
        end
    end)
end

local function CreateButtonRow(parentFrame, startingLevel)
    parentFrame.startingLevel = startingLevel
    parentFrame.selectedIndex = 0
    local totalRowWidth = ((maxLevel + 1) - startingLevel) * 48
    local diff = totalRowWidth - 300
    parentFrame.maxScrollRange = (diff > 0) and diff or 0
    parentFrame:SetWidth(totalRowWidth)
    parentFrame.buttons = {}
    local button = nil
    for i = 0, maxLevel  - startingLevel do
        button = CreateButton(startingLevel, button, parentFrame)
        keystoneButton = addon.CreateKeystoneButton(startingLevel, 260, button, i)
        SetKeystoneButtonScripts(keystoneButton, parentFrame, parentFrame:GetParent())
        parentFrame.buttons[i] = button
        startingLevel = startingLevel + 1
    end
end

local function CreateScrollFrame(scrollHolderFrame, scrollChildFrame)
    local scrollFrame = CreateFrame("ScrollFrame", "SCROLLHOLDER_SCROLLFRAME", scrollHolderFrame, "UIPanelScrollFrameCodeTemplate")
    scrollFrame:SetPoint("TOPLEFT")
    scrollFrame:SetPoint("BOTTOMRIGHT")
    scrollFrame:SetScrollChild(scrollChildFrame)
    return scrollFrame
end

local function CreateScrollChildFrame(scrollHolderFrame)
    local scrollChildFrame = CreateFrame("Frame", "SCROLLHOLDER_SCROLLCHILD")
    scrollChildFrame:SetPoint("LEFT", scrollHolderFrame, "RIGHT")
    scrollChildFrame:SetSize(0, scrollHolderFrame:GetHeight())
    return scrollChildFrame
end

local function CreateScrollHolderFrame(parentRow, anchorFrame)
    local scrollHolderFrame = CreateFrame("Frame", parentRow:GetName() .. "_SCROLLHOLDER", parentRow)  
    scrollHolderFrame:SetPoint("LEFT", anchorFrame, "RIGHT")
    scrollHolderFrame:SetSize(300, parentRow:GetHeight())
    local scrollChildFrame = CreateScrollChildFrame(scrollHolderFrame)
    scrollHolderFrame.scrollFrame = CreateScrollFrame(scrollHolderFrame, scrollChildFrame)
    return scrollHolderFrame
end

local function CreateGainedScoreFrame(parentRow, anchorFrame)
    local frame = CreateFrame("Frame", "Test", parentRow)
    frame:SetPoint("LEFT", anchorFrame, "RIGHT")
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT")
    text:SetText("+0")
    frame:SetSize(text:GetStringWidth(), parentRow:GetHeight())
    return frame
end

local function CreateAllDungeonRows()
    local row = nil
    for key, value in pairs(addon.dungeonInfo) do
        row = CreateDungeonRow(key, row)
        local dungeonNameFrame = CreateDungeonNameFrame(key, row)
        local currentScoreFrame = CreateCurrentScoreFrame(addon.playerBests["tyrannical"][key].rating, row, dungeonNameFrame)
        local scrollHolderFrame = CreateScrollHolderFrame(row, currentScoreFrame)
        CreateButtonRow(scrollHolderFrame.scrollFrame:GetScrollChild(), 5)
        local gainedScoreFrame = CreateGainedScoreFrame(row, scrollHolderFrame)
    end
end

addon:GetGeneralDungeonInfo()
addon:GetPlayerDungeonBests()
CreateAllDungeonRows()

print(string.format("Welcome to %s.", addonName))

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