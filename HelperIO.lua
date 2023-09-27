local addonName, addon = ...

local myButtons = {}
local selected = { r = 63/255, g = 81/255, b = 181/255, a = 1 }
local hover = { r = 255, g = 255, b = 255, a = 0.1 }
local unselected = { r = 66/255, g = 66/255, b = 66/255, a = 1 }
local lastX, lastY
local origX, origY
local maxScrollRange = 0
local maxLevel = 30

-- Create keystone button font
local myFont = CreateFont("Font")
myFont:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE, MONOCHROME")
myFont:SetTextColor(1, 1, 1, 1)

--[[
    CreateNewTexture - Creates a new rgb texture for the given frame.
    @param red - red value
    @param blue - blue value
    @param green - green value
    @param alpha - alpha value
    @param parent - frame using the texture
    @return texture - the created texture
--]]
local function CreateNewTexture(red, green, blue, alpha, parent)
    local texture = parent:CreateTexture()
    texture:SetAllPoints()
    texture:SetTexture("Interface\\buttons\\white8x8")
    texture:SetVertexColor(red/255, green/255, blue/255, alpha)
    return texture
end

--[[
    CreateMainFrame- Creates the main frame for the addon.
    @return frame - the created frame
--]]
local function CreateMainFrame()
    local frame = CreateFrame("Frame", "Main", UIParent)
    frame:SetPoint("CENTER", nil, 0, 100)
    frame:SetSize(1000, 600)
    frame.texture = CreateNewTexture(0, 0, 0, 0.5, frame)
    return frame
end

--[[
    CreateDungeonRowFrame - Creates a frame for a new dungeon row.
    @param name - name of the dungeon
    @param anchorFrame - frame to anchor the new row to
    @param parentFrame - parent frame of the new row
    @return frame - the created frame
--]]
local function CreateDungeonRowFrame(name, anchorFrame, parentFrame)
    local frame = CreateFrame("Frame", name .. "_ROW", parentFrame)
    -- If nil then it is the first created row, parent it to the top left of its parent.
    if(anchorFrame == nil) then
        frame:SetPoint("TOPLEFT")
    else
        frame:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT")
    end
    frame:SetSize(600, 60)
    frame.texture = CreateNewTexture(40, 40, 40, 1, frame)
    return frame
end

--[[
    CreateDungeonNameFrame- Creates a frame for displaying a rows dungeon name.
    @param name - name of the dungeon
    @param parentRow - the frames parent row frame
    @return frame - the created frame
--]]
local function CreateDungeonNameFrame(name, parentRow)
    local frame = CreateFrame("Frame", name .. "_TEXT", parentRow)
    frame:SetPoint("LEFT")
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT")
    text:SetText(name)
    frame:SetSize(150, parentRow:GetHeight())
    return frame
end

--[[
    CreateCurrentScoreFrame- Creates a frame for displaying the players top score for the rows dungeon.
    @param parentRow - the frames parent row frame
    @param anchorFrame - frame to anchor the score frame to
    @return frame - the created frame
--]]
local function CreateCurrentScoreFrame(score, parentRow, anchorFrame)
    local frame = CreateFrame("Frame", "Test", parentRow)
    frame:SetPoint("LEFT", anchorFrame, "RIGHT")
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT")
    -- If the score does not contain a decimal then add a .0 to follow formatting.
    if(not string.match(score, "%.")) then
        score = score .. ".0"
    end
    text:SetText(score)
    frame:SetSize(40, parentRow:GetHeight())
    return frame
end

--[[
    CreateButton - Creates a button frame for a keylevel for a dungeon.
    @param keyLevel - the key level the button is for
    @param anchorButton - the button to anchor the new button frame to
    @param parentFrame - the buttons parentFrame
    @return btn - the created button frame
--]]
local function CreateButton(keyLevel, anchorButton, parentFrame)
    local btn = CreateFrame("Button", parentFrame:GetName() .. "Button" .. "+" .. tostring(keyLevel), nil, "BackdropTemplate")
    btn:SetParent(parentFrame)
    -- If anchorButton is nil then it is the first in its parent frame, so set anchoring appropriately.
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
    -- If the button being created is the first/highest key level button for the dungeon it is for. Set it to the selected color.
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

--[[
    SelectButtons - Sets button colors to selected or unselected based on clicked button.
    @param parentFrame - the parent frame containing the relevant buttons
    @param keystoneButton - the keystonebutton object that was clicked.
--]]
local function SelectButtons(parentFrame, keystoneButton)
    -- If the clicked button is a higher keystone level than the currently selected button.
    if(keystoneButton.index > parentFrame.selectedIndex) then
        -- Set buttons from the currently selected to the new selected (inclusive) to the selected color.
        for i = parentFrame.selectedIndex + 1, keystoneButton.index do
            parentFrame.buttons[i]:SetBackdropColor(selected.r, selected.g, selected.b, selected.a)
        end
    end
    -- If the clicked button is a lower keystone level than the currently selected button.
    if(keystoneButton.index < parentFrame.selectedIndex) then
        -- Set buttons from the currently selected to the new selected (exclusive) to the unselected color.
        for i = parentFrame.selectedIndex, keystoneButton.index + 1, - 1 do
            parentFrame.buttons[i]:SetBackdropColor(unselected.r, unselected.g, unselected.b, unselected.a)
        end
    end
    parentFrame.selectedIndex = keystoneButton.index
end

--[[
    SetKeystoneButtonScripts - Sets a keystone buttons event scripts.
--]]
local function SetKeystoneButtonScripts(keystoneButton, parentFrame, parentScroll)
    -- OnMouseUp
    keystoneButton.button:SetScript("OnMouseUp", function(self, btn)
        keystoneButton.mouseDown = false
        local currX, currY = GetCursorPosition()
        -- If the cursor was not used for scrolling.
        if(math.ceil(origX) == math.ceil(currX)) then 
            -- If the clicked button is not the currently selected button then select necessary buttons.
            if(keystoneButton.index ~= parentFrame.selectedIndex) then
                SelectButtons(parentFrame, keystoneButton)
            end
        end
    end)
    -- OnMouseDown
    keystoneButton.button:SetScript("OnMouseDown", function(self, btn)
        keystoneButton.mouseDown = true
        -- Store the mouse position on function call for use with other events.
        origX, origY = GetCursorPosition()
        lastX, lastY = origX, origY
    end)
    -- OnUpdate
    keystoneButton.button:SetScript("OnUpdate", function(self, btn, down)
        -- If the button is being held down.
        if(keystoneButton.mouseDown) then
            local currX, currY = GetCursorPosition()
            -- Get the difference between the last frames mouse position and the current frames, multiply it by a scrolling speed coefficient.
            local diff = math.abs(lastX - currX) * 1.36
            -- If attempting to scroll left and haven't reached the minimum scroll range yet set the value.
            if(lastX < currX and parentScroll:GetHorizontalScroll() > 0) then
                newPos = parentScroll:GetHorizontalScroll() - diff
                parentScroll:SetHorizontalScroll((newPos < 0) and 0 or newPos)
            -- If attempting to scroll right and haven't reached the moximum scroll range yet set the value.
            elseif(lastX > currX and parentScroll:GetHorizontalScroll() < parentFrame.maxScrollRange) then
                newPos = parentScroll:GetHorizontalScroll() + diff
                parentScroll:SetHorizontalScroll((newPos > parentFrame.maxScrollRange) and parentFrame.maxScrollRange or newPos)
            end
            lastX = currX
        end
    end)
end

--[[
    CreateButtonRow - Creates the buttons for a row frame.
    @param parentFrame - the parent frame of the buttons
    @param startingLevel - the keystone level to start creating buttons at.
--]]
local function CreateButtonRow(parentFrame, startingLevel)
    parentFrame.startingLevel = startingLevel
    parentFrame.selectedIndex = 0
    -- Calculate the row width and max scroll range based on number of buttons being created.
    local totalRowWidth = ((maxLevel + 1) - startingLevel) * 48
    local diff = totalRowWidth - 300
    parentFrame.maxScrollRange = (diff > 0) and diff or 0
    parentFrame:SetWidth(totalRowWidth)
    parentFrame.buttons = {}
    local button = nil
    -- Create the buttons and add them to the parent frames buttons table
    for i = 0, maxLevel  - startingLevel do
        button = CreateButton(startingLevel, button, parentFrame)
        keystoneButton = addon.CreateKeystoneButton(startingLevel, button, i)
        SetKeystoneButtonScripts(keystoneButton, parentFrame, parentFrame:GetParent())
        parentFrame.buttons[i] = button
        startingLevel = startingLevel + 1
    end
end

--[[
    CreateScrollFrame - Creates a scroll frame for holding a scroll child to scroll.
    @param scrollHolderFrame - the parent frame.
    @param scrollChild - the scroll child frame.
    @return scrollFrame - the created scroll frame
--]]
local function CreateScrollFrame(scrollHolderFrame, scrollChildFrame)
    local scrollFrame = CreateFrame("ScrollFrame", "SCROLLHOLDER_SCROLLFRAME", scrollHolderFrame, "UIPanelScrollFrameCodeTemplate")
    scrollFrame:SetPoint("TOPLEFT")
    scrollFrame:SetPoint("BOTTOMRIGHT")
    scrollFrame:SetScrollChild(scrollChildFrame)
    return scrollFrame
end

--[[
    CreateScrollChildFrame - Creates a scroll child frame for use inside a scroll frame.
    @param scrollHolderFrame - the scroll holder frame to anchor to
    @return scrollChildFrame - the created frame
--]]
local function CreateScrollChildFrame(scrollHolderFrame)
    local scrollChildFrame = CreateFrame("Frame", "SCROLLHOLDER_SCROLLCHILD")
    scrollChildFrame:SetPoint("LEFT", scrollHolderFrame, "RIGHT")
    scrollChildFrame:SetSize(0, scrollHolderFrame:GetHeight())
    return scrollChildFrame
end

--[[
    CreateScrollHolderFrame - Creates a scroll holder frame for a scroll frame.
    @param parentRow - the parent row frame
    @param anchorFrame - the frame used for anchoring the frame
    @return scrollHolderFrame - the created frame
--]]
local function CreateScrollHolderFrame(parentRow, anchorFrame)
    local scrollHolderFrame = CreateFrame("Frame", parentRow:GetName() .. "_SCROLLHOLDER", parentRow)  
    scrollHolderFrame:SetPoint("LEFT", anchorFrame, "RIGHT")
    scrollHolderFrame:SetSize(300, parentRow:GetHeight())
    local scrollChildFrame = CreateScrollChildFrame(scrollHolderFrame)
    scrollHolderFrame.scrollFrame = CreateScrollFrame(scrollHolderFrame, scrollChildFrame)
    return scrollHolderFrame
end

--[[
    CreateGainedScoreFrame - Creates a frame to show the gained score of a selected keystone level.
    @param parentRow - the parent row frame
    @param anchorFrame - the frame used for anchoring the frame
    @return frame - the created frame
--]]
-- TODO: TEXT BASED ON SELECTED KEYSTONE LEVEL
local function CreateGainedScoreFrame(parentRow, anchorFrame)
    local frame = CreateFrame("Frame", "Test", parentRow)
    frame:SetPoint("LEFT", anchorFrame, "RIGHT")
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT")
    text:SetText("+0")
    frame:SetSize(text:GetStringWidth(), parentRow:GetHeight())
    return frame
end

--[[
    CreateAllDungeonRows - Creates a row frame for each mythic+ dungeon.
    @param parentFrame - the parent frame for the rows
--]]
-- TODO: DATA BASED ON WEEKLY AFFIX 
local function CreateAllDungeonRows(parentFrame)
    local row = nil
    for key, value in pairs(addon.dungeonInfo) do
        row = CreateDungeonRowFrame(key, row, parentFrame)
        local dungeonNameFrame = CreateDungeonNameFrame(key, row)
        local currentScoreFrame = CreateCurrentScoreFrame(addon.playerBests["tyrannical"][key].rating, row, dungeonNameFrame)
        local scrollHolderFrame = CreateScrollHolderFrame(row, currentScoreFrame)
        CreateButtonRow(scrollHolderFrame.scrollFrame:GetScrollChild(), addon.playerBests["tyrannical"][key].level)
        local gainedScoreFrame = CreateGainedScoreFrame(row, scrollHolderFrame)
    end
end

-- Addon startup.
addon:GetGeneralDungeonInfo()
addon:GetPlayerDungeonBests()
local mainFrame = CreateMainFrame()
CreateAllDungeonRows(mainFrame)

-- Debug prints
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