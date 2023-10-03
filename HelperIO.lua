local addonName, addon = ...

local myButtons = {}
local selected = { r = 212/255, g = 99/255, b = 0/255, a = 1 }
local hover = { r = 255, g = 255, b = 255, a = 0.1 }
local unselected = { r = 66/255, g = 66/255, b = 66/255, a = 1 }
local outline = { r = 0, g = 0, b = 0, a = 1 }
local lastX, lastY
local origX, origY
local maxLevel = 30
local weeklyAffix
local buttonWidth = 48
local xPadding = 20
local rowEdgePadding = 4

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
    local frame = CreateFrame("Frame", "Main", UIParent, "BackdropTemplate")
    frame:SetPoint("CENTER", nil, 0, 100)
    frame:SetSize(1000, 600)
    frame:SetBackdrop({
        bgFile = "Interface\\buttons\\white8x8",
        edgeFile = "Interface\\buttons\\white8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(26/255, 26/255, 27/255, 0.9)
    frame:SetBackdropBorderColor(outline.r, outline.g, outline.b, outline.a)
    return frame
end

--[[
    CreateHeaderFrame- Creates the header frame for the addon.
    @param parentFrame - the parent frame to use
    @return frame - the created frame
--]]
local function CreateHeaderFrame(parentFrame)
    local frame = CreateFrame("Frame", "Header", parentFrame, "BackdropTemplate")
    frame:SetPoint("TOP", parentFrame, "TOP", 0, -4)
    frame:SetSize(parentFrame:GetWidth() - 8, 40)
    frame:SetBackdrop({
        bgFile = "Interface\\buttons\\white8x8",
        edgeFile = "Interface\\buttons\\white8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(0, 0, 0, 0)
    frame:SetBackdropBorderColor(outline.r, outline.g, outline.b, outline.a)
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetText(addonName)
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
    local frame = CreateFrame("Frame", name .. "_ROW", parentFrame, "BackdropTemplate")
    frame:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -2)
    frame:SetSize(600, 60)
    frame:SetBackdrop({
        bgFile = "Interface\\buttons\\white8x8",
        edgeFile = "Interface\\buttons\\white8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(0, 0, 0, 0)
    frame:SetBackdropBorderColor(outline.r, outline.g, outline.b, outline.a)
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
    frame:SetPoint("LEFT", rowEdgePadding, 0)
    frame:SetSize(150, parentRow:GetHeight())
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetText(name)
    text:ClearAllPoints()
    text:SetPoint("LEFT", frame, "LEFT")
    text:SetPoint("RIGHT", frame, "RIGHT")
    text:SetJustifyH("LEFT")

    return frame
end

--[[
    CreateDungeonTimerFrame- Creates a frame for displaying the dungeons timer for the row.
    @param parentRow - the frames parent row frame
    @return frame - the created frame
--]]
local function CreateDungeonTimerFrame(dungeonTimeLimit, parentRow)
    local plusTwo = addon:FormatTimer(dungeonTimeLimit * 0.8)
    local plusThree = addon:FormatTimer(dungeonTimeLimit * 0.6)
    local frame = CreateFrame("Frame", nil, parentRow)
    frame:SetPoint("LEFT", parentRow.dungeonNameFrame, "RIGHT", xPadding, 0)
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT")
    text:SetText(addon:FormatTimer(dungeonTimeLimit))
    frame:SetSize(40, parentRow:GetHeight())

    frame:SetScript("OnEnter", function(self, motion)
        GameTooltip:SetOwner(parentRow, "ANCHOR_NONE")
        GameTooltip:SetPoint("RIGHT", parentRow, "LEFT", -3, 0)
        GameTooltip:SetText(string.format("+2: %s\n+3: %s", plusTwo, plusThree))
    end)
    frame:SetScript("OnLeave", function(self, motion)
        GameTooltip:Hide()
    end)

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
        btn:SetPoint("LEFT", anchorButton, "RIGHT", -1, 0)
    else
        btn:SetPoint("LEFT", parentFrame, "LEFT")
    end
    btn:SetSize(buttonWidth, parentFrame:GetHeight())
    btn:SetBackdrop({
        bgFile = "Interface\\buttons\\white8x8",
        edgeFile = "Interface\\buttons\\white8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    btn:SetBackdropBorderColor(outline.r, outline.g, outline.b, outline.a)
    -- If the button being created is the first/highest key level button for the dungeon it is for. Set it to the selected color.
    if(keyLevel ~= parentFrame.startingLevel) then
        btn:SetBackdropColor(unselected.r, unselected.g, unselected.b, unselected.a)
    else
        btn:SetBackdropColor(selected.r, selected.g, selected.b, selected.a)
    end
    btn:SetText((keyLevel > 1) and ("+" .. keyLevel) or "-")
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
            parentFrame.keystoneButtons[i].button:SetBackdropColor(selected.r, selected.g, selected.b, selected.a)
        end
    end
    -- If the clicked button is a lower keystone level than the currently selected button.
    if(keystoneButton.index < parentFrame.selectedIndex) then
        -- Set buttons from the currently selected to the new selected (exclusive) to the unselected color.
        for i = parentFrame.selectedIndex, keystoneButton.index + 1, -1 do
            parentFrame.keystoneButtons[i].button:SetBackdropColor(unselected.r, unselected.g, unselected.b, unselected.a)
        end
    end
    parentFrame.selectedIndex = keystoneButton.index
end

--[[
    CalculateGainedRating - Calculates the rating gained given a keystone level and a dungeon.
    @param keystoneLevel - the level of the keystone completed
    @param dungeonID - the dungeon ID for the dungeon being completed.
    @return - the amount of score gained from the completed keystone
--]]
local function CalculateGainedRating(keystoneLevel, dungeonID)
    local oppositeAffix = (weeklyAffix == "tyrannical") and "fortified" or "tyrannical"
    local oppositeBest = addon.playerBests[oppositeAffix][dungeonID].rating
    local newScore = addon.scorePerLevel[keystoneLevel]
    local gainedScore = addon:CalculateDungeonTotal(newScore, oppositeBest) - addon.playerDungeonRatings[dungeonID].mapScore
    return (gainedScore > 0) and gainedScore or 0
end

--[[
    SetKeystoneButtonScripts - Sets a keystone buttons event scripts.
    @param keystoneButton - the keystoneButton object to use
    @param parentFrame - the parent frame of the keystoneButton
    @param parentScroll - the scroll frame the button is a part of
    @param rowGainedScoreFrame - the rows gained score frame
--]]
local function SetKeystoneButtonScripts(keystoneButton, parentFrame, parentScroll, rowGainedScoreFrame)
    -- OnMouseUp
    keystoneButton.button:SetScript("OnMouseUp", function(self, btn)
        keystoneButton.mouseDown = false
        local currX, currY = GetCursorPosition()
        -- If the cursor was not used for scrolling.
        if(math.ceil(origX) == math.ceil(currX)) then 
            -- If the clicked button is not the currently selected button then select necessary buttons.
            if(keystoneButton.index ~= parentFrame.selectedIndex) then
                SelectButtons(parentFrame, keystoneButton)
                -- Set gained from selected key completion
                local gained = CalculateGainedRating(keystoneButton.level, parentFrame.dungeonID)
                rowGainedScoreFrame.text:SetText("+" .. addon:FormatDecimal(gained))
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
            if(lastX < currX and parentScroll:GetHorizontalScroll() > parentScroll.minScrollRange) then
                newPos = parentScroll:GetHorizontalScroll() - diff
                parentScroll:SetHorizontalScroll((newPos < parentScroll.minScrollRange) and parentScroll.minScrollRange or newPos)
            -- If attempting to scroll right and haven't reached the moximum scroll range yet set the value.
            elseif(lastX > currX and parentScroll:GetHorizontalScroll() < parentScroll.maxScrollRange) then
                newPos = parentScroll:GetHorizontalScroll() + diff
                parentScroll:SetHorizontalScroll((newPos > parentScroll.maxScrollRange) and parentScroll.maxScrollRange or newPos)
            end
            lastX = currX
        end
    end)
end

--[[
    CreateButtonRow - Creates the buttons for a row frame.
    @param scrollHolderFrame - the scroll holder frame for the buttons.
    @param gainedScoreFrame - the gained score frame for the buttons respective row.
    @param startingLevel - the keystone level to start creating buttons at.
    @param dungeonID - the dungeonID the row is for.
--]]
local function CreateButtonRow(scrollHolderFrame, gainedScoreFrame, startingLevel, dungeonID)
    scrollHolderFrame.scrollChild.dungeonID = dungeonID
    scrollHolderFrame.scrollChild.startingLevel = startingLevel
    scrollHolderFrame.scrollChild.selectedIndex = 0
    -- Calculate the row width and max scroll range.
    -- (Number of buttons * button width) - (number of buttons - 1) to account for button anchor offset.
    local totalRowWidth = (((maxLevel + 1) - startingLevel) * buttonWidth) - (maxLevel - startingLevel)
    local diff = totalRowWidth - scrollHolderFrame:GetWidth()
    scrollHolderFrame.scrollFrame.maxScrollRange = (diff > scrollHolderFrame.scrollFrame.minScrollRange) and diff or scrollHolderFrame.scrollFrame.minScrollRange
    scrollHolderFrame.scrollChild:SetWidth(totalRowWidth)
    scrollHolderFrame.scrollChild.keystoneButtons = {}
    local button = nil
    -- Create the buttons and add them to the parent frames buttons table
    for i = 0, maxLevel  - startingLevel do
        button = CreateButton(startingLevel, button, scrollHolderFrame.scrollChild)
        keystoneButton = addon:CreateKeystoneButton(startingLevel, button, i)
        SetKeystoneButtonScripts(keystoneButton, scrollHolderFrame.scrollChild, scrollHolderFrame.scrollFrame, gainedScoreFrame)
        scrollHolderFrame.scrollChild.keystoneButtons[i] = keystoneButton
        startingLevel = startingLevel + 1
    end
end

--[[
    CreateScrollFrame - Creates a scroll frame for holding a scroll child to scroll.
    @param scrollHolderFrame - the parent frame.
    @return scrollFrame - the created scroll frame
--]]
local function CreateScrollFrame(scrollHolderFrame)
    local scrollFrame = CreateFrame("ScrollFrame", "SCROLLHOLDER_SCROLLFRAME", scrollHolderFrame, "UIPanelScrollFrameCodeTemplate")
    scrollFrame:SetPoint("LEFT", scrollHolderFrame, "LEFT", 1, 0)
    scrollFrame:SetSize(scrollHolderFrame:GetWidth() - 2, scrollHolderFrame:GetHeight())
    scrollFrame:SetHorizontalScroll(1)
    return scrollFrame
end

--[[
    CreateScrollChildFrame - Creates a scroll child frame for use inside a scroll frame.
    @param scrollHolderFrame - the scroll holder frame to anchor to
    @return scrollChildFrame - the created frame
--]]
local function CreateScrollChildFrame(scrollHolderFrame)
    local scrollChildFrame = CreateFrame("Frame", "SCROLLHOLDER_SCROLLCHILD")
    return scrollChildFrame
end

--[[
    CreateScrollHolderFrame - Creates a scroll holder frame for a scroll frame.
    @param parentRow - the parent row frame
    @return scrollHolderFrame - the created frame
--]]
local function CreateScrollHolderFrame(parentRow)
    local widthMulti = 6
    local scrollHolderFrame = CreateFrame("Frame", parentRow:GetName() .. "_SCROLLHOLDER", parentRow, "BackdropTemplate")  
    scrollHolderFrame:SetPoint("LEFT", parentRow.dungeonTimerFrame, "RIGHT", xPadding, 0)
    -- Width is multiple of button size minus thee same multiple so button border doesn't overlap/combine with frame border.
    scrollHolderFrame:SetSize((widthMulti * buttonWidth) - widthMulti, parentRow:GetHeight())
    scrollHolderFrame:SetBackdrop({
        bgFile = "Interface\\buttons\\white8x8",
        edgeFile = "Interface\\buttons\\white8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    scrollHolderFrame:SetBackdropColor(0, 0, 0, 0)
    scrollHolderFrame:SetBackdropBorderColor(0, 0, 0, 1)
    scrollHolderFrame.scrollFrame = CreateScrollFrame(scrollHolderFrame)
    scrollHolderFrame.scrollChild = CreateScrollChildFrame(scrollHolderFrame)
    scrollHolderFrame.scrollFrame:SetScrollChild(scrollHolderFrame.scrollChild)
    scrollHolderFrame.scrollFrame.minScrollRange = 1
    scrollHolderFrame.scrollChild:SetSize(0, scrollHolderFrame.scrollFrame:GetHeight())
    return scrollHolderFrame
end

--[[
    CreateGainedScoreFrame - Creates a frame to show the gained score of a selected keystone level.
    @param parentRow - the parent row frame
    @return frame - the created frame
--]]
local function CreateGainedScoreFrame(parentRow)
    local frame = CreateFrame("Frame", nil, parentRow)
    frame:SetPoint("LEFT", parentRow.scrollHolderFrame, "RIGHT", xPadding, 0)
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.text:SetPoint("LEFT")
    frame.text:SetText("+0.0")
    frame:SetSize(40, parentRow:GetHeight())
    return frame
end

--[[
    CreateAllDungeonRows - Creates a row frame for each mythic+ dungeon.
    @param parentFrame - the parent frame for the rows
--]]
local function CreateAllDungeonRows(parentFrame, anchorFrame)
    local row = anchorFrame
    for key, value in pairs(addon.dungeonInfo) do
        row = CreateDungeonRowFrame(value.name, row, parentFrame)
        row.dungeonNameFrame = CreateDungeonNameFrame(value.name, row)
        row.dungeonTimerFrame = CreateDungeonTimerFrame(value.timeLimit, row)
        row.scrollHolderFrame = CreateScrollHolderFrame(row)
        row.gainedScoreFrame = CreateGainedScoreFrame(row)
        CreateButtonRow(row.scrollHolderFrame, row.gainedScoreFrame, addon.playerBests[weeklyAffix][key].level, key)
        -- Set total row width
        local totalWidth = 0
        local children = { row:GetChildren() }
        print(#children)
        for _, child in ipairs(children) do
            totalWidth = totalWidth + child:GetWidth() + xPadding
        end
        row:SetWidth(totalWidth)
    end
end

-- Addon startup.
addon:GetGeneralDungeonInfo()
addon:GetPlayerDungeonBests()
addon:CalculateDungeonRatings()
weeklyAffix = addon:GetWeeklyAffixInfo()
local mainFrame = CreateMainFrame()
local headerFrame = CreateHeaderFrame(mainFrame)
CreateAllDungeonRows(mainFrame, headerFrame)

for key, value in pairs(addon.playerDungeonRatings) do
    print("Totals: " .. addon.dungeonInfo[key].name .. " " .. value.mapScore)
end

-- Debug prints
print(string.format("Welcome to %s.", addonName))

for key, value in pairs(addon.dungeonInfo) do
    print(string.format("MapInfo: %s %s!", value.name, addon:FormatTimer(value.timeLimit)))
end

for key, value in pairs(addon.playerBests) do
    print(string.format("Best for %s:", key))
    for k, v in pairs(value) do
        rating = v.rating
        if(not string.match(rating, "%.")) then
            rating = rating .. ".0"
        end
        print(v.name , v.level, rating, v.time)
    end
end