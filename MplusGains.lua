local addonName, addon = ...

local myButtons = {}
local selected = { r = 212/255, g = 99/255, b = 0/255, a = 1 }
local hover = { r = 255, g = 255, b = 255, a = 0.1 }
local unselected = { r = 66/255, g = 66/255, b = 66/255, a = 1 }
local outline = { r = 0, g = 0, b = 0, a = 1 }
local maxLevel = 30
local weeklyAffix
local buttonWidth = 48
local xColPadding = 20
local xPadding = 2
local yPadding = -2
local rowEdgePadding = 4
local dungeonRowHeight = 64
local scrollButtonPadding = 4
local totalGained = 0
local mainFrame = nil
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
    CreateFrameWithBackdrop - Creates a frame using the backdrop template.
    @param parentFrame - the parent frame
    @param name - the name of the frame
    @return - the created frame
--]]
local function CreateFrameWithBackdrop(parentFrame, name)
    local frame = CreateFrame("Frame", ((name ~= nil) and name or nil), parentFrame, "BackdropTemplate")
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
    CreateMainFrame - Creates the main frame for the addon.
    @return frame - the created frame
--]]
local function CreateMainFrame()
    local frame = CreateFrameWithBackdrop(UIParent, "MainMplusGainsFrame")
    frame:SetPoint("CENTER", nil, 0, 100)
    frame:SetSize(1000, 600)
    frame:SetBackdropColor(26/255, 26/255, 27/255, 0.9)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    _G["MainMplusGainsFrame"] = frame
    tinsert(UISpecialFrames, frame:GetName())
    frame:SetFrameStrata("HIGH")
    return frame
end

--[[
    CreateHeaderFrame- Creates the header frame for the addon.
    @param parentFrame - the parent frame to use
    @return frame - the created frame
--]]
local function CreateHeaderFrame(parentFrame)
    local headerWidthDiff = 8
    local headerHeight = 40
    local frame = CreateFrameWithBackdrop(parentFrame, "Header")
    frame:SetPoint("TOP", parentFrame, "TOP", 0, -(headerWidthDiff/2))
    frame:SetSize(parentFrame:GetWidth() - headerWidthDiff, headerHeight)
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLargeOUTLINE")
    frame.text:SetPoint("CENTER")
    frame.text:SetText(GetAddOnMetadata(addonName, "Title"))
    -- Exit button
    local exitButton = CreateFrame("Button", "CLOSE_BUTTON", frame)
    local r, g, b, a = 207/255, 170/255, 0, 1
    exitButton:SetPoint("RIGHT", frame, "RIGHT")
    exitButton:SetSize(headerHeight, headerHeight)
    exitButton.text = exitButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLargeOUTLINE")
    exitButton.text:ClearAllPoints()
    exitButton.text:SetPoint("CENTER")
    exitButton.text:SetText("x")
    exitButton.text:SetTextScale(1.4)
    local _r, _g, _b, _a = exitButton.text:GetTextColor()
    exitButton.text:SetTextColor(r, g, b, a)
    exitButton:SetScript("OnMouseUp", function(self, btn)
        if(btn == "LeftButton") then parentFrame:Hide() end
    end)
    exitButton:SetScript("OnEnter", function(self, motion)
        self.text:SetTextColor(_r, _g, _b, _a)
    end)
    exitButton:SetScript("OnLeave", function(self, motion)
        self.text:SetTextColor(r, g, b, a)
    end)
    return frame
end

--[[
    CreateDungeonHolderFrame - Creates the parent frame for all dungeons rows.
    @param anchorFrame - the frame to anchor to
    @param parentFrame- the frames parent
    @return - the created frame
--]]
local function CreateDungeonHolderFrame(anchorFrame, parentFrame)
    local frame = CreateFrame("Frame", "DungeonHolder", parentFrame)
    frame:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, yPadding)
    frame:SetSize(1, 1)
    return frame
end

--[[
    CreateDungeonRowFrame - Creates a frame for a new dungeon row.
    @param anchorFrame - frame to anchor the new row to
    @param parentFrame - parent frame of the new row
    @return frame - the created frame
--]]
local function CreateDungeonRowFrame(anchorFrame, parentFrame)
    local frame = CreateFrameWithBackdrop(parentFrame, nil)
    local yOffset = yPadding
    local anchorPoint = "BOTTOMLEFT"
    if(anchorFrame == parentFrame) then
        yOffset = 0
        anchorPoint = "TOPLEFT"
    end
    frame:SetPoint("TOPLEFT", anchorFrame, anchorPoint, 0, yOffset)
    frame:SetSize(600, dungeonRowHeight)
    return frame
end

--[[
    CreateDungeonNameFrame - Creates a frame for displaying a rows dungeon name.
    @param parentRow - the frames parent row frame
    @return frame - the created frame
--]]
local function CreateDungeonNameFrame(parentRow)
    local frame = CreateFrame("Frame", string.upper(name), parentRow)
    frame:SetPoint("LEFT", rowEdgePadding, 0)
    frame:SetSize(150, parentRow:GetHeight())
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.text:SetText("Default Dungeon")
    frame.text:ClearAllPoints()
    frame.text:SetPoint("LEFT", frame, "LEFT")
    frame.text:SetPoint("RIGHT", frame, "RIGHT")
    frame.text:SetJustifyH("LEFT")
    return frame
end

--[[
    CreateDungeonTimerFrame - Creates a frame for displaying the dungeons timer for the row.
    @param parentRow - the frames parent row frame
    @return frame - the created frame
--]]
local function CreateDungeonTimerFrame(parentRow)
    local frame = CreateFrame("Frame", "DUNGEON_TIMER", parentRow)
    frame:SetPoint("LEFT", parentRow.dungeonNameFrame, "RIGHT", xColPadding, 0)
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.text:SetPoint("LEFT")
    frame.text:SetText("xx:xx")
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
    if(keyLevel ~= parentFrame.startingLevel or (keyLevel == parentFrame.startingLevel and parentFrame.overTime)) then
        btn:SetBackdropColor(unselected.r, unselected.g, unselected.b, unselected.a)
    else
        btn:SetBackdropColor(selected.r, selected.g, selected.b, selected.a)
    end
    btn:SetText((keyLevel > 1) and ("+" .. keyLevel) or "-")
    btn:SetHighlightTexture(CreateNewTexture(hover.r, hover.g, hover.b, hover.a, btn))
    -- Create keystone button font
    local myFont = CreateFont("Font")
    myFont:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE, MONOCHROME")
    myFont:SetTextColor(1, 1, 1, 1)
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
    if(keystoneButton.level > parentFrame.selectedLevel) then 
        -- Set buttons from the currently selected to the new selected (inclusive) to the selected color.
        for i = parentFrame.selectedLevel + 1, keystoneButton.level do
            parentFrame.keystoneButtons[i].button:SetBackdropColor(selected.r, selected.g, selected.b, selected.a)
        end
    -- If the clicked button is a lower keystone level than the currently selected button.
    elseif(keystoneButton.level < parentFrame.selectedLevel) then
        -- Set buttons from the currently selected to the new selected (exclusive) to the unselected color.
        for i = parentFrame.selectedLevel, keystoneButton.level + 1, -1 do
            parentFrame.keystoneButtons[i].button:SetBackdropColor(unselected.r, unselected.g, unselected.b, unselected.a)
        end
    else
        if(parentFrame.overTime) then
            parentFrame.keystoneButtons[keystoneButton.level].button:SetBackdropColor(unselected.r, unselected.g, unselected.b, unselected.a)
            parentFrame.selectedLevel = keystoneButton.level - 1
            return
        end
    end
    parentFrame.selectedLevel = keystoneButton.level
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
    local lastX, lastY = 0, 0
    -- OnMouseUp
    keystoneButton.button:SetScript("OnMouseUp", function(self, btn)
        if(btn == "RightButton") then keystoneButton.mouseDown = false end
        if(btn == "LeftButton") then
            -- If the clicked button is not the currently selected button then select necessary buttons.
            if(keystoneButton.level ~= parentFrame.selectedLevel or (keystoneButton.level == parentFrame.startingLevel and keystoneButton.level == parentFrame.selectedLevel and parentFrame.overTime)) then
                -- Set gained from selected key completion
                local gained = 0
                if(keystoneButton.level ~= parentFrame.selectedLevel) then
                    if(keystoneButton.level ~= parentFrame.startingLevel or parentFrame.overTime) then
                        --parentFrame:GetParent():GetParent():GetParent().summaryFrame.scoreHeader.gainText
                        gained = addon:RoundToOneDecimal(CalculateGainedRating(keystoneButton.level, parentFrame.dungeonID))
                    end
                end
                totalGained = totalGained + (gained - tonumber(string.sub(rowGainedScoreFrame.text:GetText(), 2, -1)))
                mainFrame.summaryFrame.header.scoreHeader.gainText:SetText(((totalGained + addon.totalRating) == addon.totalRating) and "" or ("(" .. totalGained + addon.totalRating .. ")"))
                rowGainedScoreFrame.text:SetText("+" .. addon:FormatDecimal(gained))
                SelectButtons(parentFrame, keystoneButton)
            end
        end
    end)
    -- OnMouseDown
    keystoneButton.button:SetScript("OnMouseDown", function(self, btn)
        if(btn == "RightButton") then
            keystoneButton.mouseDown = true
            -- Store the mouse position on function call for use with other events.
            lastX, lastY = GetCursorPosition()
        end
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
                local newPos = parentScroll:GetHorizontalScroll() - diff
                parentScroll:SetHorizontalScroll((newPos < parentScroll.minScrollRange) and parentScroll.minScrollRange or newPos)
            -- If attempting to scroll right and haven't reached the moximum scroll range yet set the value.
            elseif(lastX > currX and parentScroll:GetHorizontalScroll() < parentScroll.maxScrollRange) then
                local newPos = parentScroll:GetHorizontalScroll() + diff
                parentScroll:SetHorizontalScroll((newPos > parentScroll.maxScrollRange) and parentScroll.maxScrollRange or newPos)
            end
            lastX = currX
        end
    end)
end

--[[
    CalculateScrollHolderUIValues - Calculates and sets the width and max scroll range values of a scrollframe
    @param scrollHolderFrame - the scroll holder frame that is being adjusted
    @param startingLevel - the starting keystone level to set the scroll to
--]]
local function CalculateScrollHolderUIValues(scrollHolderFrame, startingLevel)
    -- Calculate the row width and max scroll range.
    -- (Number of buttons * button width) - (number of buttons - 1) to account for button anchor offset.
    local totalRowWidth = (((maxLevel + 1) - startingLevel) * buttonWidth) - (maxLevel - startingLevel)
    local diff = totalRowWidth - scrollHolderFrame:GetWidth()
    scrollHolderFrame.scrollFrame.maxScrollRange = (diff > scrollHolderFrame.scrollFrame.minScrollRange) and diff or scrollHolderFrame.scrollFrame.minScrollRange
    scrollHolderFrame.scrollChild:SetWidth(totalRowWidth)
end

--[[
    CreateAllButtons - Create a number of keystone buttons.
    @param scrollHolderFrame - the frame the buttons are a part of
    @param startingLevel - the keystone level to start making buttons at
    @param maxLevel - the keystone level to stop making buttons at.
--]]
local function CreateAllButtons(scrollHolderFrame, startingLevel, maxLevel)
    local button = nil
    -- Create the buttons and add them to the parent frames buttons table
    for i = startingLevel, maxLevel do
        button = CreateButton(i, button, scrollHolderFrame.scrollChild)
        local keystoneButton = addon:CreateKeystoneButton(i, button)
        SetKeystoneButtonScripts(keystoneButton, scrollHolderFrame.scrollChild, scrollHolderFrame.scrollFrame, scrollHolderFrame:GetParent().gainedScoreFrame)
        scrollHolderFrame.scrollChild.keystoneButtons[i] = keystoneButton
    end
end

--[[
    CreateButtonRow - Creates the buttons for a row frame.
    @param scrollHolderFrame - the scroll holder frame for the buttons.
    @param dungeonID - the dungeonID the row is for.
--]]
local function CreateButtonRow(scrollHolderFrame, dungeonID)
    local startingLevel = addon.playerBests[weeklyAffix][dungeonID].level
    -- Setup base values
    scrollHolderFrame.scrollChild.overTime = addon.playerBests[weeklyAffix][dungeonID].overTime
    scrollHolderFrame.scrollChild.dungeonID = dungeonID
    scrollHolderFrame.scrollChild.baseLevel = startingLevel
    scrollHolderFrame.scrollChild.startingLevel = startingLevel
    scrollHolderFrame.scrollChild.selectedLevel = (scrollHolderFrame.scrollChild.overTime) and startingLevel - 1 or startingLevel
    scrollHolderFrame.scrollChild.keystoneButtons = {}
    -- Setup UI values
    CalculateScrollHolderUIValues(scrollHolderFrame, startingLevel)
    -- Create the buttons and add them to the parent frames buttons table
    CreateAllButtons(scrollHolderFrame, startingLevel, maxLevel)
end

--[[
    ScrollButtonRow - Handles the scroll action of a dungeon helper rows scroll frame.
    @param self - the scroll frame being scrolled
    @param delta - the direction of the scroll, 1 for up and -1 for down
--]]
local function ScrollButtonRow(self, delta)
    if(IsMouseButtonDown("RightButton")) then return end
    -- Find the number of buttons before the new to be set scroll position
    local numButtonsPrior = math.floor((self:GetHorizontalScroll()-self.minScrollRange)/(buttonWidth - 1))
    local remainder = math.floor((self:GetHorizontalScroll()-self.minScrollRange)%(buttonWidth - 1))
    if(delta == -1) then 
        numButtonsPrior = numButtonsPrior + 1  
    else 
        if(remainder == 0) then
            numButtonsPrior = numButtonsPrior - 1 
        end
    end
    -- New scroll pos
    local newPos = self.minScrollRange + (numButtonsPrior * (buttonWidth - 1))
    if(newPos > self.maxScrollRange) then 
        newPos = self.maxScrollRange 
    elseif(newPos < self.minScrollRange) then 
        newPos = self.minScrollRange 
    end
    self:SetHorizontalScroll(newPos)
end

--[[
    CreateScrollFrame - Creates a scroll frame for holding a scroll child to scroll.
    @param scrollHolderFrame - the parent frame.
    @return scrollFrame - the created scroll frame
--]]
local function CreateScrollFrame(scrollHolderFrame)
    local scrollFrame = CreateFrame("ScrollFrame", "SCROLLHOLDER_SCROLLFRAME", scrollHolderFrame, "UIPanelScrollFrameCodeTemplate")
    scrollFrame.minScrollRange = 1
    scrollFrame.maxScrollRange = 0
    -- up left, down right
    -- scroll to the nearest button edge in the direction the user inputed.
    scrollFrame:SetScript("OnMouseWheel", ScrollButtonRow)
    scrollFrame:SetPoint("LEFT", scrollHolderFrame, "LEFT", 1, 0)
    scrollFrame:SetSize(scrollHolderFrame:GetWidth() - 2, scrollHolderFrame:GetHeight())
    scrollFrame:SetHorizontalScroll(scrollFrame.minScrollRange)
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
    CreateScrollButton - Creates a scroll button with an arrow texture.
    @param parentFrame - the parent frome of the button
    @param anchorFrame - the buttons anchor
    @param direciont - the direction to point the arrow in.
--]]
local function CreateScrollButton(parentFrame, anchorFrame, direction)
    local downAlpha = 0.7
    local textureName = "Interface/MONEYFRAME/Arrow-" .. direction .. "-Down.PNG"
    local scrollButton = CreateFrame("Button", nil, parentFrame)
    scrollButton:SetPoint("LEFT", anchorFrame, "RIGHT", (direction == "Left") and scrollButtonPadding or -1, 0)
    scrollButton:SetSize(20, parentFrame:GetHeight())
    -- Set texture up and texture down.
    scrollButton.textureUp = scrollButton:CreateTexture()
    scrollButton.textureUp:SetTexture(textureName)
    scrollButton.textureUp:ClearAllPoints()
    scrollButton.textureUp:SetPoint("CENTER")
    scrollButton.textureUp:SetVertexColor(1, 1, 1, downAlpha)
    scrollButton.textureDown = scrollButton:CreateTexture()
    scrollButton.textureDown:SetTexture(textureName)
    scrollButton.textureDown:ClearAllPoints()
    scrollButton.textureDown:SetPoint("CENTER")
    scrollButton.textureDown:SetScale(0.9)
    scrollButton:SetNormalTexture(scrollButton.textureUp)
    scrollButton:SetPushedTexture(scrollButton.textureDown)
    scrollButton:SetScript("OnEnter", function(self, motion)
        self.textureUp:SetVertexColor(1, 1, 1, 1)
    end)
    scrollButton:SetScript("OnLeave", function(self, motion)
        self.textureUp:SetVertexColor(1, 1, 1, downAlpha)
    end)
    scrollButton:SetScript("OnMouseUp", function(self, btn)
        ScrollButtonRow(parentFrame.scrollHolderFrame.scrollFrame, (direction == "Left") and 1 or -1)
    end)
    return scrollButton
end

--[[
    CreateScrollHolderFrame - Creates a scroll holder frame for a scroll frame.
    @param parentRow - the parent row frame
    @return scrollHolderFrame - the created frame
--]]
local function CreateScrollHolderFrame(parentRow)
    local scrollHolderFrame = CreateFrameWithBackdrop(parentRow, nil)
    scrollHolderFrame.widthMulti = 6
    -- Width is multiple of button size minus thee same multiple so button border doesn't overlap/combine with frame border.
    scrollHolderFrame:SetSize((scrollHolderFrame.widthMulti * buttonWidth) - scrollHolderFrame.widthMulti, parentRow:GetHeight())
    scrollHolderFrame.scrollFrame = CreateScrollFrame(scrollHolderFrame)
    scrollHolderFrame.scrollChild = CreateScrollChildFrame(scrollHolderFrame)
    scrollHolderFrame.scrollFrame:SetScrollChild(scrollHolderFrame.scrollChild)
    scrollHolderFrame.scrollChild:SetSize(0, scrollHolderFrame.scrollFrame:GetHeight())
    local leftScrollButton = CreateScrollButton(parentRow, parentRow.dungeonTimerFrame, "Left")
    scrollHolderFrame:SetPoint("LEFT", leftScrollButton, "RIGHT")
    scrollHolderFrame.leftScrollButton = leftScrollButton

    local rightScrollButton = CreateScrollButton(parentRow, scrollHolderFrame, "Right")
    scrollHolderFrame.rightScrollButton = rightScrollButton
    return scrollHolderFrame
end

--[[
    CreateGainedScoreFrame - Creates a frame to show the gained score of a selected keystone level.
    @param parentRow - the parent row frame
    @return frame - the created frame
--]]
local function CreateGainedScoreFrame(parentRow)
    local frame = CreateFrame("Frame", "GAINED_SCORE", parentRow)
    frame:SetPoint("LEFT", parentRow.scrollHolderFrame.rightScrollButton, "RIGHT", scrollButtonPadding, 0)
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.text:SetPoint("LEFT")
    frame.text:SetText("+0.0")
    frame:SetSize(32, parentRow:GetHeight())
    return frame
end

--[[
    CalculateRowWidth - Calculates the width of the dungeon rows.
    @param row - the row to calculate the width of.
    @return totalWidth - the totalWidth of a row
]]
local function CalculateRowWidth(row)
    local totalWidth = 0
    local children = { row:GetChildren() }
    for _, child in ipairs(children) do
        totalWidth = totalWidth + child:GetWidth()
    end
    -- xCol and scroll padding used twice each
    totalWidth = totalWidth + (2 * xColPadding) + (2 * scrollButtonPadding)
    return totalWidth
end

--[[
    UpdateDungeonButtons - Updates the position and selected buttons of a dungeon row based on a given level. Adds new buttons if needed.
    @param scrollHolderFrame - the rows scroll holder frame
    @param oldLevel - the old level to update from
--]]
local function UpdateDungeonButtons(scrollHolderFrame, oldLevel)
    local dungeonID = scrollHolderFrame.scrollChild.dungeonID
    local newLevel = addon.playerBests[weeklyAffix][dungeonID].level
    local oldBase = scrollHolderFrame.scrollChild.baseLevel
    scrollHolderFrame.scrollChild.overTime = addon.playerBests[weeklyAffix][dungeonID].overTime
    scrollHolderFrame.scrollChild.startingLevel = newLevel
    -- Setup new scroll range and pos values
    local newPos
    if(newLevel <= oldBase) then
        newPos = 1
    else
        newPos = 1 + ((newLevel - oldLevel) * (buttonWidth - scrollHolderFrame.scrollFrame.minScrollRange))
    end
    scrollHolderFrame.scrollFrame.minScrollRange = newPos
    if((maxLevel - newLevel) < scrollHolderFrame.widthMulti) then
        scrollHolderFrame.scrollFrame.maxScrollRange = newPos 
    end
    scrollHolderFrame.scrollFrame:SetHorizontalScroll(newPos)
    -- Need new buttons if the newLevel is lower than the base level.
    if(newLevel < oldBase) then
        -- Setup new values and new buttons
        scrollHolderFrame.scrollChild.baseLevel = newLevel
        CalculateScrollHolderUIValues(scrollHolderFrame, newLevel)
        CreateAllButtons(scrollHolderFrame, newLevel, oldBase - 1)
        -- Set new anchor point for old level
        scrollHolderFrame.scrollChild.keystoneButtons[oldBase].button:ClearAllPoints()
        scrollHolderFrame.scrollChild.keystoneButtons[oldBase].button:SetPoint("LEFT", scrollHolderFrame.scrollChild.keystoneButtons[oldBase - 1].button, "RIGHT", -1, 0)
    end
    -- Select/Deselect necessary buttons
    SelectButtons(scrollHolderFrame.scrollChild, scrollHolderFrame.scrollChild.keystoneButtons[newLevel])
    if(scrollHolderFrame.scrollChild.overTime) then
        scrollHolderFrame.scrollChild.keystoneButtons[newLevel].button:SetBackdropColor(unselected.r, unselected.g, unselected.b, unselected.a)
        scrollHolderFrame.scrollChild.selectedLevel = newLevel - 1
    else
        scrollHolderFrame.scrollChild.selectedLevel = newLevel
    end
end

--[[
    PopulateAllDungeonRows - Populates the dungeon rows with the proper data. Called on player entering world.
    @param parentFrame - the parent frame
--]]
local function PopulateAllDungeonRows(parentFrame)
    local sortedLevels = addon:SortDungeonsByLevel(weeklyAffix)
    local rows = { parentFrame:GetChildren() }
    parentFrame.rows = {}
    for i, key in ipairs(sortedLevels) do
        local value = addon.dungeonInfo[key]
        rows[i].dungeonNameFrame.text:SetText(value.name)
        rows[i].dungeonTimerFrame.text:SetText(addon:FormatTimer(value.timeLimit))
        CreateButtonRow(rows[i].scrollHolderFrame, key)
        parentFrame.rows[key] = rows[i]
    end
end

--[[
    CreateAllDungeonRows - Creates a row frame for each mythic+ dungeon.
    @param parentFrame - the parent frame for the rows
--]]
local function CreateAllDungeonRows(parentFrame)
    local row = parentFrame
    for n in pairs(addon.dungeonInfo) do
        row = CreateDungeonRowFrame(row, parentFrame)
        row.dungeonNameFrame = CreateDungeonNameFrame(row)
        row.dungeonTimerFrame = CreateDungeonTimerFrame(row)
        row.scrollHolderFrame = CreateScrollHolderFrame(row)
        row.gainedScoreFrame = CreateGainedScoreFrame(row)
    end
    -- Set frame widths
    local totalWidth = CalculateRowWidth(row)
    parentFrame:SetWidth(totalWidth)
    local children = { parentFrame:GetChildren() }
    for _, child in ipairs(children) do
        child:SetWidth(totalWidth)
    end
end

--[[
    SetDungeonHolderHeight - Calculates and sets the needed height of the dungeon holder frame.
    @param dungeonHolderFrame - the dungeon holder frame.
]]
local function SetDungeonHolderHeight(dungeonHolderFrame)
    local children = { dungeonHolderFrame:GetChildren() }
    local key, value = next(children)
    local totalHeight = (#children * value:GetHeight()) + ((#children - 1) * (-yPadding))
    dungeonHolderFrame:SetHeight(totalHeight)
end

--[[
    CreateSummaryFrame - Creates the parent frame for the summary section.
    @param anchorFrame - the frame to anchor the summary frame to.
    @param parentFrame - the parent frame of the summary frame.
    @param headerWidth - the total width of the header frame.
    @return frame - the created summary frame.
]]
local function CreateSummaryFrame(anchorFrame, parentFrame, headerWidth)
    local frame = CreateFrameWithBackdrop(parentFrame, "Summary")
    frame:SetPoint("LEFT", anchorFrame, "RIGHT", xPadding, 0)
    frame:SetSize(headerWidth - anchorFrame:GetWidth() - xPadding , anchorFrame:GetHeight())
    return frame
end

--[[
    CreateSummaryHeaderFrame - Creates the header frame for the summary section.
    @param parentFrame - the parent frame of the summary header frame.
    @return frame - the created summary header frame.
]]
local function CreateSummaryHeaderFrame(parentFrame)
    local frame = CreateFrame("Frame", "SummaryHeader", parentFrame)
    frame:SetPoint("TOP", parentFrame, "TOP")
    frame:SetSize(parentFrame:GetWidth(), dungeonRowHeight)
    local playerName = CreateFrame("Frame", "PlayerHeader", frame)
    playerName:SetPoint("TOP", frame, "TOP")
    playerName:SetSize(frame:GetWidth(), frame:GetHeight()/2)
    playerName.playerText = playerName:CreateFontString(nil, "OVERLAY", "GameFontNormalLargeOutline")
    playerName.playerText:SetPoint("BOTTOM")
    playerName.playerText:SetText(UnitName("player") .. " (" .. GetRealmName() .. ")")
    local scoreHeader = CreateFrame("Frame", "ScoreHeader", frame)
    scoreHeader:SetPoint("TOP", playerName, "BOTTOM")
    scoreHeader:SetSize(frame:GetWidth(), frame:GetHeight()/2)
    scoreHeader.ratingText = scoreHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalLargeOutline")
    scoreHeader.ratingText:SetPoint("TOP", scoreHeader, "TOP")
    scoreHeader.ratingText:SetText("(1231231230)")
    scoreHeader.gainText = scoreHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scoreHeader.gainText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    scoreHeader.gainText:SetPoint("LEFT", scoreHeader.ratingText, "RIGHT", 0, 0)
    scoreHeader.gainText:SetText("")
    frame.playerName = playerName
    frame.scoreHeader = scoreHeader
    return frame
end
--[[
    CreateAffixInfoHolderFrame - Creates the affix info parent frame for the summary section.
    @param anchorFrame - the anchor frame of the affix info holder frame
    @param parentFrame - the parent frame of the affix info holder frame.
    @return frame - the created affix info holer frame.
]]
local function CreateAffixInfoHolderFrame(anchorFrame, parentFrame)
    local frame = CreateFrame("Frame", "AffixInfo", parentFrame)
    frame:SetPoint("TOP", anchorFrame, "BOTTOM", 0, yPadding)
    frame:SetSize(parentFrame:GetWidth() - (xPadding*2), (dungeonRowHeight * 3) + (-yPadding * 2))
    return frame
end

--[[
    CreateAffixInfoFrame - Creates a frame containing affix name and description
    @param anchorFrame - the frame to anchor to
    @param parentFrame - the frame to parent to
    @param affixTable - the affix name
    @return frame - the created frame
--]]
local function CreateAffixInfoFrame(anchorFrame, parentFrame, affixTable)
    -- Holder frame
    local frame = CreateFrame("Frame", "KeystoneInfo", parentFrame)
    local anchorPoint = "BOTTOM"
    local yOffset = yPadding
    if(parentFrame == anchorFrame) then
        anchorPoint = "TOP"
        yOffset = 0
    end
    local frameWidth = parentFrame:GetWidth()
    frame:SetPoint("TOP", anchorFrame, anchorPoint, 0, yOffset)
    frame:SetSize(frameWidth, dungeonRowHeight)
    -- Header with icon, name of affix, level it starts at.
    local titleFrame = CreateFrame("Frame", "AffixHeader", frame)
    titleFrame:SetPoint("TOP")
    local titleFrameHeight = 20
    titleFrame:SetSize(frameWidth, titleFrameHeight)
    titleFrame.nameText = titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline")
    titleFrame.nameText:SetPoint("CENTER")
    titleFrame.nameText:SetText(affixTable.name)
    titleFrame.levelText = titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline")
    titleFrame.levelText:SetPoint("LEFT", titleFrame.nameText, "RIGHT", xPadding, 0)
    titleFrame.levelText:SetText("(+" .. ((affixTable.level ~= 0) and affixTable.level or "?") .. ")")
    titleFrame.texture = titleFrame:CreateTexture()
    titleFrame.texture:SetPoint("RIGHT", titleFrame.nameText, "LEFT", -4, 0)
    local iconSize = titleFrameHeight/1.2
    titleFrame.texture:SetSize(iconSize, iconSize)
    titleFrame.texture:SetTexture(affixTable.filedataid)
    -- Description
    local descFrame = CreateFrame("Frame", "AffixDesc", frame)
    descFrame:SetPoint("TOP", titleFrame, "BOTTOM")
    descFrame:SetSize(frameWidth, frame:GetHeight() - titleFrameHeight)
    descFrame.descText = descFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    descFrame.descText:ClearAllPoints()
    descFrame.descText:SetPoint("TOPLEFT", descFrame, "TOPLEFT")
    descFrame.descText:SetPoint("TOPRIGHT", descFrame, "TOPRIGHT")
    descFrame.descText:SetJustifyH("LEFT")
    descFrame.descText:SetText(affixTable.description)
    return frame
end

--[[
    CreateSplitFrame - Creates a frame to mimic a horizontal line.
    @param anchorFrame - the frame to anchor the line to
    @param parentFrame - the frame the line is parented to
    Note: Used instead of CreateLine() due to buggy/inconsitent behaviour.
--]]
local function CreateSplitFrame(anchorFrame, parentFrame)
    local frame = CreateFrameWithBackdrop(parentFrame, nil)
    frame:SetPoint("TOP", anchorFrame, "BOTTOM")
    frame:SetSize(parentFrame:GetWidth()/2, 1)
    frame:SetBackdropBorderColor(outline.r, outline.b, outline.g, outline.a)
end

--[[
    CreateBestRunsFrame - Creates the holder frame for best dungeon runs summary
    @param anchorFrame - the frames anchor
    @param parentFrame - the frames parent
    @return - the created frame
--]]
local function CreateBestRunsFrame(anchorFrame, parentFrame)
    local frame = CreateFrame("Frame", "BestRuns", parentFrame)
    frame:SetPoint("TOP", anchorFrame, "BOTTOM", 0, yPadding)
    frame:SetSize(parentFrame:GetWidth() - (xPadding*2), (dungeonRowHeight * 4) + (yPadding * 5))
    frame.smallColumnWidth = 60
    return frame
end

--[[
    CreateRunFrame - Creates a frame to display the given affixes best run for a dungeon
    @param anchorFrame - the frames anchor
    @param parentFrame - the frames parent
    @param affix - the affixes name
    @return - the created frame
]]
local function CreateRunFrame(anchorFrame, parentFrame, affix)
    local parentFrameHeight = parentFrame:GetHeight()
    local affixFrame = CreateFrame("Frame", nil, parentFrame)
    local anchorPosition = "LEFT"
    if(affix == "tyrannical") then anchorPosition = "RIGHT" end
    affixFrame:SetPoint("RIGHT", anchorFrame, anchorPosition)
    affixFrame:SetSize(parentFrame:GetParent().smallColumnWidth, parentFrameHeight)
    affixFrame.keyLevelText = affixFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    affixFrame.keyLevelText:SetPoint("LEFT", affixFrame, "LEFT")
    affixFrame.keyLevelText:SetPoint("RIGHT", affixFrame, "RIGHT")
    affixFrame.keyLevelText:SetJustifyH("RIGHT")
    affixFrame.keyLevelText:SetText("-")
    return affixFrame
end

--[[
    CreateDungeonScoreFrame - Creates a frame to display a dungeons total score.
    @param anchorFrame - the frame to anchor to
    @param parentFrame - the frames parent
    @return - the created frame
--]]
local function CreateDungeonScoreFrame(anchorFrame, parentFrame)
    local scoreFrame = CreateFrame("Frame", nil, parentFrame)
    scoreFrame:SetPoint("RIGHT", anchorFrame, "LEFT")
    scoreFrame:SetSize(parentFrame:GetParent().smallColumnWidth, parentFrame:GetHeight())
    scoreFrame.scoreText = scoreFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scoreFrame.scoreText:SetPoint("LEFT")
    scoreFrame.scoreText:SetText("-")
    return scoreFrame
end

--[[
    CreateDungeonBestNameFrame - Creates the name frame for a dungeon in the best dungeon runs frame
    @param parentFrame - the parent frame
    @return - the created frame
--]]
local function CreateDungeonBestNameFrame(parentFrame)
    local children = { parentFrame:GetChildren() }
    local totalWidth = parentFrame:GetParent().smallColumnWidth * #children
    local nameFrame = CreateFrame("Frame", nil, parentFrame)
    nameFrame:SetPoint("LEFT", parentFrame, "LEFT")
    nameFrame:SetSize(parentFrame:GetWidth() - totalWidth, parentFrame:GetHeight())
    nameFrame.nameText = nameFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameFrame.nameText:ClearAllPoints()
    nameFrame.nameText:SetPoint("LEFT", nameFrame, "LEFT")
    nameFrame.nameText:SetPoint("RIGHT", nameFrame, "RIGHT")
    nameFrame.nameText:SetJustifyH("LEFT")
    nameFrame.nameText:SetText("Default Dungeon")
    return nameFrame
end

--[[
    CreateDungeonSummaryHeader - Creates the header with column titles for the dungeon summary frame.
    @param parentFrame - the parent frame
    @return - the created frame
--]]
local function CreateDungeonSummaryHeader(parentFrame)
    -- 9 rows in the frame
    local holderHeight = parentFrame:GetHeight()/9
    local iconSize = holderHeight/1.3
    local holder = CreateFrame("Frame", "DUNGEON_SUMMARY_HEADER", parentFrame)
    holder:SetPoint("TOP", parentFrame, "TOP")
    holder:SetSize(parentFrame:GetWidth(), holderHeight)
    -- Tyrannical column
    local tyranHeader = CreateFrame("Frame", nil, holder)
    tyranHeader:SetPoint("RIGHT", holder, "RIGHT")
    tyranHeader:SetSize(parentFrame.smallColumnWidth, holderHeight)
    tyranHeader.texture = tyranHeader:CreateTexture()
    tyranHeader.texture:SetPoint("RIGHT")
    tyranHeader.texture:SetSize(iconSize, iconSize)
    tyranHeader.texture:SetTexture("Interface/Icons/Achievement_Boss_Archaedas.PNG")
    -- Fortified column
    local fortHeader = CreateFrame("Frame", nil, holder)
    fortHeader:SetPoint("RIGHT", tyranHeader, "LEFT")
    fortHeader:SetSize(parentFrame.smallColumnWidth, holderHeight)
    fortHeader.texture = fortHeader:CreateTexture()
    fortHeader.texture:SetPoint("RIGHT")
    fortHeader.texture:SetSize(iconSize, iconSize)
    fortHeader.texture:SetTexture("Interface/Icons/ability_toughness.PNG")
    -- Score column
    local scoreHeader = CreateFrame("Frame", nil, holder)
    scoreHeader:SetPoint("RIGHT", fortHeader, "LEFT")
    scoreHeader:SetSize(parentFrame.smallColumnWidth, holderHeight)
    scoreHeader.text = scoreHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline")
    scoreHeader.text:ClearAllPoints()
    scoreHeader.text:SetPoint("LEFT", scoreHeader, "LEFT")
    scoreHeader.text:SetPoint("RIGHT", scoreHeader, "RIGHT")
    scoreHeader.text:SetJustifyH("LEFT")
    scoreHeader.text:SetText("SCORE")
    -- Dungeon name column
    local dungeonHeader = CreateFrame("Frame", nil, holder)
    dungeonHeader:SetPoint("LEFT", holder, "LEFT")
    dungeonHeader:SetSize(parentFrame:GetWidth() - (parentFrame.smallColumnWidth * 3), holderHeight)
    dungeonHeader.text = dungeonHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline")
    dungeonHeader.text:ClearAllPoints()
    dungeonHeader.text:SetPoint("LEFT", dungeonHeader, "LEFT")
    dungeonHeader.text:SetPoint("RIGHT", dungeonHeader, "RIGHT")
    dungeonHeader.text:SetJustifyH("LEFT")
    dungeonHeader.text:SetText("DUNGEON")
    return holder
end

--[[
    CreateBestRunRow - Creates a frame for a dungeon summary row.
    @param anchorFrame - the frames anchor
    @param parentFrame - the frames parent
    @retun - the created frame
--]]
local function CreateBestRunRow(anchorFrame, parentFrame)
    local holder = CreateFrame("Frame", nil, parentFrame)
    holder:SetPoint("TOP", anchorFrame, "BOTTOM", 0, yPadding)
    holder:SetSize(parentFrame:GetWidth(), parentFrame:GetHeight()/9)
    holder.tyrFrame = CreateRunFrame(holder, holder, "tyrannical")
    holder.fortFrame = CreateRunFrame(holder.tyrFrame, holder, "fortified")
    holder.scoreFrame = CreateDungeonScoreFrame(holder.fortFrame, holder)
    holder.nameFrame = CreateDungeonBestNameFrame(holder)
    return holder
end

--[[
    CreateDungeonHelper - Creates the Dungeon Helper panel of the addon
    @param mainFrame - the main addon frame
    @param headerFrame - the header frame of the addon
    @return - the dungeon helper panel frame
--]]
local function CreateDungeonHelper(mainFrame, headerFrame)
    local dungeonHolderFrame = CreateDungeonHolderFrame(headerFrame, mainFrame)
    CreateAllDungeonRows(dungeonHolderFrame)
    SetDungeonHolderHeight(dungeonHolderFrame)
    return dungeonHolderFrame
end

--[[
    GetDungeonLevelString - Creates a string representing the best dungeon run for a affix.
    @param affix - the affix to get the run for
    @param dungeonID - the dungeon to get the run for
    @return - formatted string representing the run.
--]]
local function GetDungeonLevelString(affix, dungeonID)
    local runString = "-"
    local level = addon.playerBests[affix][dungeonID].level
    if(level > 1) then 
        runString = addon:CalculateChest(dungeonID, addon.playerBests[affix][dungeonID].time) .. level
    end
    return runString
end

--[[
    UpdateDungeonBests - Updates a given dungeons dungeon best row.
    @param parentFrame - the row being updated
    @param dungeonID - the dungeon being updated
--]]
local function UpdateDungeonBests(parentFrame, dungeonID)
    addon:CalculateDungeonRatings()
    if(weeklyAffix == "tyrannical") then 
        parentFrame.tyrFrame.keyLevelText:SetText(GetDungeonLevelString("tyrannical", dungeonID))
    else
        parentFrame.fortFrame.keyLevelText:SetText(GetDungeonLevelString("fortified", dungeonID))
    end
    parentFrame.scoreFrame.scoreText:SetText(addon:FormatDecimal(addon.playerDungeonRatings[dungeonID].mapScore))
end

--[[
    PopulateAllBestRunsRows - Sets players best runs per dungeon data. Called on player entering world.
    @param parentFrame - the parent frame
--]]
local function PopulateAllBestRunsRows(parentFrame)
    local sortedScores = addon:SortDungeonsByScore()
    local rows = { parentFrame:GetChildren() }
    parentFrame.rows = {}
    for i, key in ipairs(sortedScores) do
        local index = i + 1
        rows[index].tyrFrame.keyLevelText:SetText(GetDungeonLevelString("tyrannical", key))
        rows[index].fortFrame.keyLevelText:SetText(GetDungeonLevelString("fortified", key))
        rows[index].scoreFrame.scoreText:SetText(addon:FormatDecimal(addon.playerDungeonRatings[key].mapScore))
        rows[index].nameFrame.nameText:SetText(addon.dungeonInfo[key].name)
        parentFrame.rows[key] = rows[index]
    end
end

--[[
    CreateSummary - Creates the Summary panel of the addon
    @param mainFrame - the main addon frame
    @param dungeonHelperFrame - the dungeon helper panels parent frame
    @param width - the width of the summary panel frame to be
    @return - the created frame
--]]
local function CreateSummary(mainFrame, dungeonHelperFrame, width)
    -- Holder and header
    local summaryFrame = CreateSummaryFrame(dungeonHelperFrame, mainFrame, width)
    summaryFrame.header  = CreateSummaryHeaderFrame(summaryFrame)
    CreateSplitFrame(summaryFrame.header, summaryFrame)
    -- Affix info
    local affixInfoFrame = CreateAffixInfoHolderFrame(summaryFrame.header, summaryFrame)
    local anchor = affixInfoFrame
    local sortedAffixes = addon:SortAffixesByLevel()
    for i, key in ipairs(sortedAffixes) do
        anchor = CreateAffixInfoFrame(anchor, affixInfoFrame, addon.affixInfo[key])
    end
    CreateSplitFrame(affixInfoFrame, summaryFrame)
    -- Best runs
    summaryFrame.bestRunsFrame = CreateBestRunsFrame(affixInfoFrame, summaryFrame)
    anchor = CreateDungeonSummaryHeader(summaryFrame.bestRunsFrame)
    for n in pairs(addon.dungeonInfo) do
        anchor = CreateBestRunRow(anchor, summaryFrame.bestRunsFrame)
    end
    return summaryFrame
end

--[[
    CreateBugReportFrame - Creates the bug report frame.
    @param anchorFrame - the frame to anchor to
    @param parentFame - the parent frame of the created frame
    @return frame - the created frame
--]]
local function CreateBugReportFrame(anchorFrame, parentFrame)
    local url = "TEST TEXT WOW A URL?!"
    -- Holder
    local frame = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    frame:SetSize(300, 80)
    frame:SetPoint("BOTTOMRIGHT", anchorFrame, "TOPRIGHT")
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame:SetFrameLevel(20)
    -- Header
    frame.headerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.headerText:ClearAllPoints()
    frame.headerText:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
    frame.headerText:SetText("Report a Bug")
    -- Edit box
    frame.editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    frame.editBox:SetSize(frame:GetWidth() - 40, 20)
    frame.editBox:SetPoint("TOPLEFT", frame.headerText, "BOTTOMLEFT", 4, -8)
    frame.editBox:SetText(url)
    frame.editBox:SetScript("OnTextChanged", function(self, userInput)
        -- Don't want text being changed, reset it on change attempt.
        self:SetText(url)
        self:HighlightText()
    end)
    frame.editBox:SetScript("OnEscapePressed", function(self)
        frame:Hide()
    end)
    -- Copy url text
    frame.copyText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.copyText:ClearAllPoints()
    frame.copyText:SetPoint("TOPLEFT", frame.editBox, "BOTTOMLEFT", -4, -4)
    frame.copyText:SetText("Press Ctrl+C to copy the URL")
    frame:Hide()
    return frame
end

--[[
    CreateFooter - Creates the footer for the main addon frame.
    @param anchorFrame - the frame to anchor to
    @param parentFrame - the frames parent to set
    @param headerFrame - the header frame of the addon
--]]
local function CreateFooter(anchorFrame, parentFrame, headerFrame)
    -- Button rgb values
    local _r, _g, _b, _a = 100/255, 100/255, 100/255, 1
    local hover_r, hover_g, hover_b, hover_a = 144/255, 144/255, 144/255, 1
    -- Holder
    local frame = CreateFrameWithBackdrop(parentFrame, nil)
    frame:SetBackdropBorderColor(0, 0, 0, 0)
    frame:SetSize(headerFrame:GetWidth(), parentFrame:GetHeight() - anchorFrame:GetHeight() - headerFrame:GetHeight() + (yPadding*6))
    frame:SetPoint("BOTTOM", parentFrame, "BOTTOM", 0, 4)
    -- Creator text
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.text:ClearAllPoints()
    frame.text:SetPoint("LEFT", frame, "LEFT", 1, 0)
    frame.text:SetTextColor(_r, _g, _b, _a)
    frame.text:SetText("Made by ExplodingMuffins")
    -- Bug report frame and button
    local bugReportFrame = CreateBugReportFrame(frame, parentFrame)
    local bugButton = CreateFrame("Button", nil, frame)
    bugButton.mouseDown = false
    bugButton:SetPoint("RIGHT", frame, "RIGHT")
    bugButton.text = bugButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bugButton.text:ClearAllPoints()
    bugButton.text:SetPoint("RIGHT", bugButton, "RIGHT", -1, 0)
    bugButton.text:SetTextColor(_r, _g, _b, _a)
    bugButton.text:SetText("Bug Report")
    bugButton:SetSize(math.ceil(bugButton.text:GetWidth()), frame:GetHeight())
    -- Handle button text color change depending on action.
    bugButton:SetScript("OnMouseUp", function(self, btn)
        if(self:IsMouseMotionFocus()) then
            self.text:SetTextColor(hover_r, hover_g, hover_b, hover_a)
        else
            self.text:SetTextColor(_r, _g, _b, _a)
        end
        if(bugReportFrame:IsShown()) then
            bugReportFrame:Hide()
        else
            bugReportFrame:Show()
        end
        self.mouseDown = false
    end)
    bugButton:SetScript("OnEnter", function(self, motion)
        if(not self.mouseDown) then
            self.text:SetTextColor(hover_r, hover_g, hover_b, hover_a)
        end
    end)
    bugButton:SetScript("OnLeave", function(self, motion)
        if(not self.mouseDown) then
            self.text:SetTextColor(_r, _g, _b, _a)
        end
    end)
    bugButton:SetScript("OnMouseDown", function(self, btn)
        self.mouseDown = true
        self.text:SetTextColor(188/255, 188/255, 188/255, 1)
    end)
end

--[[
    LoadData - Loads player dungeon data. Called on player entering world event.
--]]
local function LoadData()
    addon:GetPlayerDungeonBests()
    addon:CalculateDungeonRatings()
end

--[[
    CheckForNewBest - Checks to see if a dungeon run is better than the current best for that dungeon.
--]]
local function CheckForNewBest(dungeonID, level, time)
    local completionRating = addon:CalculateRating((time/1000), dungeonID, level)
    if(level > 1) then
        if(completionRating > addon.playerBests[weeklyAffix][dungeonID].rating) then
            return true
        end
    end
    return false
end

--[[
    StartUp - Handles necessary start up actions.
    @return - the main addon frame
--]]
local function StartUp()
    -- Non-player dungeon info
    addon:GetGeneralDungeonInfo()
    addon:GetPlayerDungeonBests()
    addon:CalculateDungeonRatings()
    weeklyAffix = addon:GetWeeklyAffixInfo()
    -- UI setup
    mainFrame = CreateMainFrame()
    mainFrame:Hide()
    local headerFrame = CreateHeaderFrame(mainFrame)
    local dungeonHolderFrame = CreateDungeonHelper(mainFrame, headerFrame)
    local summaryFrame = CreateSummary(mainFrame, dungeonHolderFrame, headerFrame:GetWidth())
    mainFrame.summaryFrame = summaryFrame
    mainFrame.dungeonHolderFrame = dungeonHolderFrame
    CreateFooter(dungeonHolderFrame, mainFrame, headerFrame)
    -- Data setup.
    mainFrame:RegisterEvent("PLAYER_LOGIN")
    mainFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    mainFrame:SetScript("OnEvent", function(self, event, ...)
        if(event == "PLAYER_LOGIN") then
            LoadData()
            PopulateAllDungeonRows(dungeonHolderFrame)
            summaryFrame.header.scoreHeader.ratingText:SetText(addon.totalRating)
            PopulateAllBestRunsRows(summaryFrame.bestRunsFrame)
        end
        if(event == "CHALLENGE_MODE_COMPLETED") then
            local dungeonID, level, time, onTime, keystoneUpgradeLevels, practiceRun,
                oldOverallDungeonScore, newOverallDungeonScore, IsMapRecord, IsAffixRecord,
                PrimaryAffix, isEligibleForScore, members
                    = C_ChallengeMode.GetCompletionInfo()
            if(CheckForNewBest(dungeonID, level, time)) then
                -- Replace the old run with the newly completed one and update that dungeons summary and helper row.
                local oldLevel = addon.playerBests[weeklyAffix][dungeonID].level
                addon:SetNewBest(dungeonID, level, time, weeklyAffix, onTime)
                UpdateDungeonButtons(dungeonHolderFrame.rows[dungeonID].scrollHolderFrame, oldLevel)
                UpdateDungeonBests(summaryFrame.bestRunsFrame.rows[dungeonID], dungeonID)
                -- Set new total, subtract rows gain, set overall gain, and reset row gain to 0.
                summaryFrame.header.scoreHeader.ratingText:SetText(addon.totalRating)
                totalGained = totalGained - tonumber(string.sub(dungeonHolderFrame.rows[dungeonID].gainedScoreFrame.text:GetText(), 2, -1))
                summaryFrame.header.scoreHeader.gainText:SetText(((totalGained + addon.totalRating) == addon.totalRating) and "" or ("(" .. totalGained + addon.totalRating .. ")"))
                dungeonHolderFrame.rows[dungeonID].gainedScoreFrame.text:SetText("+0.0")
            end
        end
    end)
end

StartUp()

SLASH_MPLUSGAINS1 = "/mplusgains"
SLASH_MPLUSGAINS2 = "/mpg"
SlashCmdList["MPLUSGAINS"] = function()
   if(mainFrame:IsShown()) then mainFrame:Hide() else mainFrame:Show() end
end