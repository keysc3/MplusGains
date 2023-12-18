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
local selectedAffix = addon.tyrannicalID

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
    SelectButtons - Sets button colors to selected or unselected based on clicked button.
    @param parentFrame - the parent frame containing the relevant buttons
    @param keystoneButton - the keystonebutton object that was clicked.
    @param isSwitch - bool for whether or not the function was called when switching weeks.
--]]
local function SelectButtons(parentFrame, keystoneButton, isSwitch)
    -- If the clicked button is a higher keystone level than the currently selected button.
    if(keystoneButton.level > parentFrame.selectedLevel[selectedAffix]) then 
        -- Set buttons from the currently selected to the new selected (inclusive) to the selected color.
        for i = parentFrame.selectedLevel[selectedAffix] + 1, keystoneButton.level do
            parentFrame.keystoneButtons[i].button:SetBackdropColor(selected.r, selected.g, selected.b, selected.a)
        end
    -- If the clicked button is a lower keystone level than the currently selected button.
    elseif(keystoneButton.level < parentFrame.selectedLevel[selectedAffix]) then
        -- Set buttons from the currently selected to the new selected (exclusive) to the unselected color.
        for i = parentFrame.selectedLevel[selectedAffix], keystoneButton.level + 1, -1 do
            parentFrame.keystoneButtons[i].button:SetBackdropColor(unselected.r, unselected.g, unselected.b, unselected.a)
        end
    else
        if(keystoneButton.level == parentFrame.startingLevel[selectedAffix] and not isSwitch) then
            parentFrame.keystoneButtons[keystoneButton.level].button:SetBackdropColor(unselected.r, unselected.g, unselected.b, unselected.a)
            parentFrame.selectedLevel[selectedAffix] = keystoneButton.level - 1
            return
        end
    end
    if(not isSwitch) then 
        parentFrame.selectedLevel[selectedAffix] = keystoneButton.level
    end
end

--[[
    CheckForScrollButtonEnable - Checks to see if either scroll buttons needs to be enabled or disabled and does so if necessary.
    @param scrollHolderFrame - the frame the scroll buttons are a part of.
    @param affixID - The affixID of the affix to use for the scroll range check.
--]]
local function CheckForScrollButtonEnable(scrollHolderFrame, affixID)
    local scrollFrame = scrollHolderFrame.scrollFrame
    local scroll = addon:RoundToOneDecimal(scrollFrame:GetHorizontalScroll())
    local leftEnabled = scrollHolderFrame.leftScrollButton:IsEnabled()
    local rightEnabled = scrollHolderFrame.rightScrollButton:IsEnabled()
    if(scrollFrame.minScrollRange[affixID] >= scroll) then
        if(leftEnabled) then
            scrollHolderFrame.leftScrollButton:Disable()
        end
    else
        if(not leftEnabled) then
            scrollHolderFrame.leftScrollButton:Enable()
        end
    end
    if(scrollFrame.maxScrollRange[affixID] <= scroll) then
        if(rightEnabled) then
            scrollHolderFrame.rightScrollButton:Disable()
        end
    else
        if(not rightEnabled) then
            scrollHolderFrame.rightScrollButton:Enable()
        end
    end
end

--[[
    SetDesaturation - Sets the desaturation of the given texture. Uses vertex color if shader supported is false.
    @param texture - The texture being altered.
    @param desaturation - Bool for whether or not to desaturate the texture.
--]]
local function SetDesaturation(texture, desaturation)
	local shaderSupported = texture:SetDesaturated(desaturation)
	if(not shaderSupported) then
		if(desaturation) then
			texture:SetVertexColor(0.5, 0.5, 0.5)
		else
			texture:SetVertexColor(1.0, 1.0, 1.0)
		end
	end
end

--[[
    ResetScrollFrameValues - Resets the values of a dungeons scroll frame.
    @param affixID - the ID of the week being reset
    @param scrollChild - the scrollChild from for the row
    @param gainedScoreFrame - the gainedScoreFrame of the row
--]]
local function ResetScrollFrameValues(affixID, scrollChild, gainedScoreFrame)
    scrollChild.selectedLevel[affixID] = scrollChild.startingLevel[affixID] - 1
    totalGained = totalGained - gainedScoreFrame.gainedScore[affixID]
    gainedScoreFrame.gainedScore[affixID] = 0
end

--[[
    ResetBothToStartingLevel - Resets both affix weeks of the given rows scrollholder frame to the default state.
    @param rowFrame - the row frame to reset
--]]
local function ResetBothToStartingLevel(rowFrame)
    local scrollChild = rowFrame.scrollHolderFrame.scrollChild
    local scrollFrame = rowFrame.scrollHolderFrame.scrollFrame
    local gainedScoreFrame = rowFrame.gainedScoreFrame
    local opp = addon:GetOppositeAffix(selectedAffix)
    local startingLevel = (scrollChild.startingLevel[selectedAffix] < scrollChild.startingLevel[opp]) and scrollChild.startingLevel[selectedAffix] or scrollChild.startingLevel[opp]
    -- Reset button selection UI colors and scroll values/position.
    SelectButtons(scrollChild, scrollChild.keystoneButtons[startingLevel], false)
    scrollChild.keystoneButtons[startingLevel].button:SetBackdropColor(unselected.r, unselected.g, unselected.b, unselected.a)
    scrollFrame.previousScroll = scrollFrame.minScrollRange[opp]
    scrollFrame:SetHorizontalScroll(scrollFrame.minScrollRange[selectedAffix])
    CheckForScrollButtonEnable(rowFrame.scrollHolderFrame, selectedAffix)
    -- Reset the scroll frame values and set the text.
    ResetScrollFrameValues(selectedAffix, scrollChild, gainedScoreFrame)
    ResetScrollFrameValues(addon:GetOppositeAffix(selectedAffix), scrollChild, gainedScoreFrame)
    gainedScoreFrame.text:SetText("+0.0")
    gainedScoreFrame.oppText:SetText("")
end

--[[
    ResetToStartingLevel - Resets the given scroll holder frame to the default state.
    @param scrollHolderFrame - the scroll holder frame to reset
--]]
--[[local function ResetToStartingLevel(scrollHolderFrame)
    local startingLevel = scrollHolderFrame.scrollChild.startingLevel[selectedAffix]
    SelectButtons(scrollHolderFrame.scrollChild, scrollHolderFrame.scrollChild.keystoneButtons[startingLevel], false)
    scrollHolderFrame.scrollChild.keystoneButtons[startingLevel].button:SetBackdropColor(unselected.r, unselected.g, unselected.b, unselected.a)
    scrollHolderFrame.scrollChild.selectedLevel[selectedAffix] = startingLevel - 1
    CheckForScrollButtonEnable(scrollHolderFrame, selectedAffix)
end--]]

--[[
    CreateTooltip - Creates a tooltip for the given frame and with the given text.
    @param parentFrame - The parent frame for the tooltip.
    @param textString - The string to set the tooltips text to.
    @return tooltip - The created tooltip.
--]]
local function CreateTooltip(parentFrame, textString)
    local tooltip = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    tooltip:SetSize(1, 30)
    tooltip:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    tooltip:SetBackdropColor(0, 0, 0, 0.9)
    tooltip:SetFrameLevel(20)
    tooltip.text = tooltip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tooltip.text:ClearAllPoints()
    tooltip.text:SetPoint("CENTER", tooltip, "CENTER", 0, 0)
    tooltip.text:SetText(textString)
    tooltip:SetWidth(math.ceil(tooltip.text:GetWidth() + 16))
    tooltip:Hide()
    return tooltip
end

--[[
    SwitchAffixWeeks - Handles switching between affix weeks on button click.
    @param self - the button clicked
    @param motion - the button used for the click
    @param down - bool for if the button is held down
--]]
local function SwitchAffixWeeks(self, button, down)
    if(button ~= "LeftButton") then return end
    if(selectedAffix ~= self.affixID) then
        SetDesaturation(self.texture, false)
        local otherButton = (self.affixID == addon.tyrannicalID) and self:GetParent().toggles[addon.fortifiedID] or self:GetParent().toggles[addon.tyrannicalID]
        SetDesaturation(otherButton.texture, true)
        if(mainFrame.dungeonHolderFrame.rows ~= nil) then
            for key, value in pairs(mainFrame.dungeonHolderFrame.rows) do
                local scrollChild = value.scrollHolderFrame.scrollChild
                -- If no level is selected then deselect every button including the starting level, otherwise deslect to the selected level.
                if(scrollChild.selectedLevel[self.affixID] < scrollChild.startingLevel[self.affixID]) then
                    SelectButtons(scrollChild, scrollChild.keystoneButtons[scrollChild.startingLevel[self.affixID]], true)
                    scrollChild.keystoneButtons[scrollChild.startingLevel[self.affixID]].button:SetBackdropColor(unselected.r, unselected.g, unselected.b, unselected.a)
                else
                    SelectButtons(scrollChild, scrollChild.keystoneButtons[scrollChild.selectedLevel[self.affixID]], true)
                end
                -- Handle scroll values and button enabling.
                local oldScroll = value.scrollHolderFrame.scrollFrame:GetHorizontalScroll()
                value.scrollHolderFrame.scrollFrame:SetHorizontalScroll(value.scrollHolderFrame.scrollFrame.previousScroll)
                value.scrollHolderFrame.scrollFrame.previousScroll = oldScroll
                CheckForScrollButtonEnable(value.scrollHolderFrame, self.affixID)
                -- Set text values for gains.
                value.gainedScoreFrame.text:SetText("+" .. addon:FormatDecimal(value.gainedScoreFrame.gainedScore[self.affixID]))
                if(value.gainedScoreFrame.gainedScore[selectedAffix] > 0) then
                    value.gainedScoreFrame.oppText:SetText("+" .. addon:FormatDecimal(value.gainedScoreFrame.gainedScore[selectedAffix]))
                else
                    value.gainedScoreFrame.oppText:SetText("")
                end
            end
        end
        selectedAffix = self.affixID
    end
end
--[[
    CreateToggleButton - Creates a toggle button for switching between weeks when choosing keys.
    @param parentFrame - The parent frame for the button.
    @param affixID - The affix the button is for.
    @return button - The created button.
--]]
local function CreateToggleButton(parentFrame, affixID)
    local name, description, filedataid = C_ChallengeMode.GetAffixInfo(affixID);
    local button = CreateFrame("Button", nil, parentFrame)
    button.affixID = affixID
    button:SetSize((parentFrame:GetWidth()/1.5), (parentFrame:GetHeight()/1.5))
    button.texture = button:CreateTexture()
    button.texture:SetTexture(filedataid)
    button:SetNormalTexture(button.texture)
    button:ClearAllPoints()
    button:SetHighlightTexture(CreateNewTexture(hover.r, hover.g, hover.b, hover.a, button))
    button.tooltip = CreateTooltip(parentFrame, "View " .. string.lower(name) .. " keys")
    button:SetScript("OnEnter", function(self, motion)
        self.tooltip:Show()
    end)
    button:SetScript("OnLeave", function(self, motion)
        self.tooltip:Hide()
    end)
    button:SetScript("OnClick", SwitchAffixWeeks)
    return button
end

--[[
    CreateToggle - Creates a scroll button with an arrow texture.
    @param parentFrame - the parent frome of the button.
--]]
local function CreateToggle(parentFrame)
    parentFrame.toggles = {}
    local leftToggle = CreateToggleButton(parentFrame, addon.fortifiedID)
    leftToggle:SetPoint("LEFT", parentFrame, "LEFT")
    leftToggle.tooltip:SetPoint("BOTTOMLEFT", parentFrame, "TOPLEFT", -2, -1)
    local pad = 4
    local rightToggle = CreateToggleButton(parentFrame, addon.tyrannicalID)
    rightToggle:SetPoint("LEFT", leftToggle, "RIGHT", pad, 0)
    rightToggle.tooltip:SetPoint("BOTTOMLEFT", parentFrame, "TOPLEFT", leftToggle:GetWidth() + pad - 2, -1)
    parentFrame.toggles[leftToggle.affixID] = leftToggle
    parentFrame.toggles[rightToggle.affixID] = rightToggle
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
    exitButton:SetHighlightTexture(CreateNewTexture(hover.r, hover.g, hover.b, hover.a/2, exitButton))
    local _r, _g, _b, _a = exitButton.text:GetTextColor()
    exitButton.text:SetTextColor(r, g, b, a)
    exitButton:SetScript("OnMouseUp", function(self, btn)
        exitButton.text:SetTextScale(1.4)
    end)
    exitButton:SetScript("OnMouseDown", function(self, motion)
        exitButton.text:SetTextScale(1.2)
    end)
    exitButton:SetScript("OnClick", function(self, button, down)
        if(button == "LeftButton") then parentFrame:Hide() end
    end)
    local resetButton = CreateFrame("Button", "REFRESH_BUTTON", frame)
    resetButton:SetPoint("LEFT", frame, "LEFT")
    resetButton:SetSize(headerHeight, headerHeight)
    resetButton.texture = resetButton:CreateTexture()
    resetButton.texture:ClearAllPoints()
    resetButton.texture:SetPoint("CENTER")
    resetButton.texture:SetTexture("Interface/AddOns/MplusGains/Textures/UI-RefreshButton-Default.PNG")
    resetButton.texture:SetVertexColor(1, 1, 1, 0.8)
    resetButton:SetNormalTexture(resetButton.texture)
    resetButton.texture1 = resetButton:CreateTexture()
    resetButton.texture1:ClearAllPoints()
    resetButton.texture1:SetPoint("CENTER")
    resetButton.texture1:SetTexture("Interface/AddOns/MplusGains/Textures/UI-RefreshButton-Default.PNG")
    resetButton.texture1:SetVertexColor(1, 1, 1, 0.9)
    resetButton.texture1:SetScale(0.9)
    resetButton:SetPushedTexture(resetButton.texture1)
    resetButton:SetHighlightTexture(CreateNewTexture(hover.r, hover.g, hover.b, hover.a/2, resetButton))
    resetButton:SetScript("OnClick", function(self, btn, down)
        if(btn == "LeftButton") then
            if(mainFrame.dungeonHolderFrame.rows ~= nil) then
                for key, value in pairs(mainFrame.dungeonHolderFrame.rows) do
                    ResetBothToStartingLevel(value)
                end
                mainFrame.summaryFrame.header.scoreHeader.gainText:SetText("")
            end
        end
    end)
    resetButton.tooltip = CreateTooltip(frame, "Reset selected keys")
    resetButton.tooltip:SetPoint("BOTTOMLEFT", resetButton, "TOPLEFT", -2, -1)
    resetButton:SetScript("OnEnter", function(self, motion)
        self.tooltip:Show()
    end)
    resetButton:SetScript("OnLeave", function(self, motion)
        self.tooltip:Hide()
    end)
    -- Create the weekly affix toggles
    local toggle = CreateFrame("Frame", nil, parentFrame)
    toggle:SetSize(headerHeight, headerHeight)
    toggle:SetPoint("LEFT", resetButton, "RIGHT", 10, 0)
    CreateToggle(toggle)
    frame.toggle = toggle
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
    local frame = CreateFrame("Frame", nil, parentRow)
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
    btn:SetBackdropColor(unselected.r, unselected.g, unselected.b, unselected.a)
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
    CalculateGainedRating - Calculates the rating gained given a keystone level and a dungeon.
    @param keystoneLevel - the level of the keystone completed
    @param dungeonID - the dungeon ID for the dungeon being completed.
    @param affixID - the affix ID for the affix of the key.
    @return - the amount of score gained from the completed keystone
--]]
local function CalculateGainedRating(keystoneLevel, dungeonID, affixID)
    local oppositeAffix = (affixID == addon.tyrannicalID) and addon.fortifiedID or addon.tyrannicalID
    local oppositeBest = addon.playerBests[oppositeAffix][dungeonID].rating
    local newScore = addon.scorePerLevel[keystoneLevel]
    local gainedScore = addon:CalculateDungeonTotal(newScore, oppositeBest) - addon.playerDungeonRatings[dungeonID].mapScore
    return (gainedScore > 0) and gainedScore or 0
end

--[[
    CalculateGainedRatingBothSelected - Calculates the rating gained given a selected key while a key from the not selected weekly affix is also selected.
    @param newSelectedLevel - the newly selected key level
    @param parentFrame - the dungeons scroll frame the selection is from.
    @return gainTable - a table with both weeks possible gains.
--]]
local function CalculateGainedRatingBothSelected(newSelectedLevel, parentFrame)
    local dungeonID = parentFrame.dungeonID
    local opp = addon:GetOppositeAffix(weeklyAffix)
    local weeklySelected
    local oppSelected
    -- Set the weekly affixes selected level.
    if(weeklyAffix == selectedAffix) then
        weeklySelected = newSelectedLevel
        oppSelected = parentFrame.selectedLevel[opp]
    else
        weeklySelected = parentFrame.selectedLevel[weeklyAffix]
        oppSelected = newSelectedLevel
    end
    -- Calculate the rating gained from doing the current weeks key first. Then calculate the other weeks key gained given the current weeks selected is completed.
    local weeklyGained = CalculateGainedRating(weeklySelected, dungeonID, weeklyAffix)
    local newScore = addon:CalculateDungeonTotal(addon.scorePerLevel[weeklySelected], addon.playerBests[opp][dungeonID].rating)
    local otherScore = addon:CalculateDungeonTotal(addon.scorePerLevel[oppSelected], addon.scorePerLevel[weeklySelected])
    local newGain = math.abs(newScore - addon.playerDungeonRatings[dungeonID].mapScore)
    local otherGain = math.abs(otherScore - newScore)
    local gainTable = { [weeklyAffix] = addon:RoundToOneDecimal(newGain), [opp] = addon:RoundToOneDecimal(otherGain) }
    return gainTable
end

--[[
    UpdateGained - Update the total gained rating and set the necessary text.
    @param newGain - the new gained amount
    @param frame - the gained score frame of the dungeon to alter.
    @param affix - the affix the gain is from.
--]]
local function UpdateGained(newGain, frame, affix)
    totalGained = totalGained + (newGain - frame.gainedScore[affix])
    if(affix == selectedAffix) then
        frame.text:SetText("+" .. addon:FormatDecimal(newGain))
    else
        frame.oppText:SetText((newGain > 0) and ("+" .. addon:FormatDecimal(newGain)) or "")
    end
    frame.gainedScore[affix] = newGain
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
    keystoneButton.button:SetScript("OnClick", function(self, btn, down)
        if(btn == "LeftButton") then
            -- If the clicked button is not the currently selected button then select necessary buttons.
            if(keystoneButton.level ~= parentFrame.selectedLevel[selectedAffix] or (keystoneButton.level == parentFrame.startingLevel[selectedAffix] and keystoneButton.level == parentFrame.selectedLevel[selectedAffix])) then
                -- Set gained from selected key completion
                local gained = 0
                local opp = addon:GetOppositeAffix(selectedAffix)
                if(keystoneButton.level ~= parentFrame.selectedLevel[selectedAffix]) then
                    -- No selected affix for the opposite level.
                    if(parentFrame.selectedLevel[opp] < parentFrame.startingLevel[opp]) then
                        gained = addon:RoundToOneDecimal(CalculateGainedRating(keystoneButton.level, parentFrame.dungeonID, selectedAffix))
                        UpdateGained(gained, rowGainedScoreFrame, selectedAffix)
                    -- Both affixes have a key selected for the dungeon.
                    else
                        local gainedTable = CalculateGainedRatingBothSelected(keystoneButton.level, parentFrame)
                        UpdateGained(gainedTable[selectedAffix], rowGainedScoreFrame, selectedAffix)
                        UpdateGained(gainedTable[opp], rowGainedScoreFrame, opp)
                    end
                else
                    -- Starting key == selected key and was pressed, no gain for the row.
                    UpdateGained(gained, rowGainedScoreFrame, selectedAffix)
                    -- If a key in the other week is selected then recalculate the gain.
                    if(parentFrame.selectedLevel[opp] > parentFrame.startingLevel[opp]) then
                        gained = addon:RoundToOneDecimal(CalculateGainedRating(parentFrame.selectedLevel[opp], parentFrame.dungeonID, opp))
                        UpdateGained(gained, rowGainedScoreFrame, opp)
                    end
                end
                -- Update total gained and update UI buttons.
                mainFrame.summaryFrame.header.scoreHeader.gainText:SetText(((totalGained + addon.totalRating) == addon.totalRating) and "" or ("(" .. totalGained + addon.totalRating .. ")"))
                SelectButtons(parentFrame, keystoneButton, false)
            end
        end
    end)
    -- OnMouseUp
    keystoneButton.button:SetScript("OnMouseUp", function(self, btn)
        if(btn == "RightButton") then keystoneButton.mouseDown = false end
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
            if(lastX < currX and parentScroll:GetHorizontalScroll() > parentScroll.minScrollRange[selectedAffix]) then
                local newPos = parentScroll:GetHorizontalScroll() - diff
                parentScroll:SetHorizontalScroll((newPos < parentScroll.minScrollRange[selectedAffix]) and parentScroll.minScrollRange[selectedAffix] or newPos)
            -- If attempting to scroll right and haven't reached the moximum scroll range yet set the value.
            elseif(lastX > currX and parentScroll:GetHorizontalScroll() < parentScroll.maxScrollRange[selectedAffix]) then
                local newPos = parentScroll:GetHorizontalScroll() + diff
                parentScroll:SetHorizontalScroll((newPos > parentScroll.maxScrollRange[selectedAffix]) and parentScroll.maxScrollRange[selectedAffix] or newPos)
            end
            CheckForScrollButtonEnable(parentScroll:GetParent(), selectedAffix)
            lastX = currX
        end
    end)
end

--[[
    CalculateScrollMinRange - Finds the minimum scroll range for a scroll frame.
    @param baseLevel - base key level of the row.
    @param startingLevel - starting level of the row.
    @return minimum - the minimum scroll value.
--]]
local function CalculateScrollMinRange(baseLevel, startingLevel)
    local minimum = 1
    if(startingLevel > baseLevel) then
        minimum = minimum + ((startingLevel - baseLevel) * (buttonWidth - 1))
    end
    return minimum
end

--[[
    CalculateScrollHolderUIValues - Calculates and sets the width and max scroll range values of a scrollframe
    @param scrollHolderFrame - the scroll holder frame that is being adjusted
--]]
local function CalculateScrollHolderUIValues(scrollHolderFrame)
    local baseLevel = scrollHolderFrame.scrollChild.baseLevel
    -- Calculate the row width and max scroll range.
    -- (Number of buttons * button width) - (number of buttons - 1) to account for button anchor offset.
    local totalRowWidth = (((maxLevel + 1) - baseLevel) * buttonWidth) - (maxLevel - baseLevel)
    local diff = totalRowWidth - scrollHolderFrame:GetWidth()
    scrollHolderFrame.scrollFrame.minScrollRange[addon.tyrannicalID] = CalculateScrollMinRange(baseLevel, scrollHolderFrame.scrollChild.startingLevel[addon.tyrannicalID])
    scrollHolderFrame.scrollFrame.minScrollRange[addon.fortifiedID] = CalculateScrollMinRange(baseLevel, scrollHolderFrame.scrollChild.startingLevel[addon.fortifiedID])
    scrollHolderFrame.scrollFrame.maxScrollRange[addon.tyrannicalID] = (diff > scrollHolderFrame.scrollFrame.minScrollRange[addon.tyrannicalID]) and diff or scrollHolderFrame.scrollFrame.minScrollRange[addon.tyrannicalID]
    scrollHolderFrame.scrollFrame.maxScrollRange[addon.fortifiedID] = (diff > scrollHolderFrame.scrollFrame.minScrollRange[addon.fortifiedID]) and diff or scrollHolderFrame.scrollFrame.minScrollRange[addon.fortifiedID]
    scrollHolderFrame.scrollFrame.previousScroll = scrollHolderFrame.scrollFrame.minScrollRange[addon:GetOppositeAffix(selectedAffix)]
    scrollHolderFrame.scrollChild:SetWidth(totalRowWidth)
end

--[[
    CreateAllButtons - Create a number of keystone buttons.
    @param scrollHolderFrame - the frame the buttons are a part of
    @param maxLevel - the keystone level to stop making buttons at.
--]]
local function CreateAllButtons(scrollHolderFrame, maxLevel)
    local button = nil
    local baseLevel = scrollHolderFrame.scrollChild.baseLevel
    -- Create the buttons and add them to the parent frames buttons table
    for i = baseLevel, maxLevel do
        button = CreateButton(i, button, scrollHolderFrame.scrollChild)
        local keystoneButton = addon:CreateKeystoneButton(i, button)
        SetKeystoneButtonScripts(keystoneButton, scrollHolderFrame.scrollChild, scrollHolderFrame.scrollFrame, scrollHolderFrame:GetParent().gainedScoreFrame)
        scrollHolderFrame.scrollChild.keystoneButtons[i] = keystoneButton
    end
end

--[[
    GetStartingLevel - Gets the lowest dungeon level it is possible to get rating from and returns it.
    @param dungeonID - the ID of the dungeon to be checked.
    @param affixID - the ID of the affix to get the starting level for.
    @return - the lowest key level the player can get rating from for the dungeon.
--]]
local function GetStartingLevel(dungeonID, affixID)
    local best = addon.playerBests[affixID][dungeonID]
    if(best.overTime) then
        local baseLevel = best.level
        for i = best.level - 1, 2, -1 do
            -- Find lowest key that gives more min rating than best rating
            if(addon.scorePerLevel[i] > best.rating) then
                baseLevel = i
            else
                break
            end
        end
        return baseLevel
    end
    return best.level + 1

end

--[[
    CreateButtonRow - Creates the buttons for a row frame.
    @param scrollHolderFrame - the scroll holder frame for the buttons.
    @param dungeonID - the dungeonID the row is for.
--]]
local function CreateButtonRow(scrollHolderFrame, dungeonID)
    local startingTyranLevel = GetStartingLevel(dungeonID, addon.tyrannicalID)
    local startingFortLevel = GetStartingLevel(dungeonID, addon.fortifiedID)
    -- Setup base values
    scrollHolderFrame.scrollChild.dungeonID = dungeonID
    scrollHolderFrame.scrollChild.baseLevel = (startingTyranLevel < startingFortLevel) and startingTyranLevel or startingFortLevel
    scrollHolderFrame.scrollChild.startingLevel = { [addon.tyrannicalID] = startingTyranLevel, [addon.fortifiedID] = startingFortLevel }
    scrollHolderFrame.scrollChild.selectedLevel = { [addon.tyrannicalID] = startingTyranLevel - 1, [addon.fortifiedID] = startingFortLevel - 1 } 
    scrollHolderFrame.scrollChild.keystoneButtons = {}
    -- Setup UI values
    CalculateScrollHolderUIValues(scrollHolderFrame)
    scrollHolderFrame.scrollFrame:SetHorizontalScroll(scrollHolderFrame.scrollFrame.minScrollRange[selectedAffix])
    -- Create the buttons and add them to the parent frames buttons table
    CreateAllButtons(scrollHolderFrame, maxLevel)
end

--[[
    ScrollButtonRow - Handles the scroll action of a dungeon helper rows scroll frame.
    @param self - the scroll frame being scrolled
    @param delta - the direction of the scroll, 1 for up and -1 for down
--]]
local function ScrollButtonRow(self, delta)
    if(IsMouseButtonDown("RightButton")) then return end
    -- Find the number of buttons before the new to be set scroll position
    local numButtonsPrior = math.floor((self:GetHorizontalScroll()-self.minScrollRange[selectedAffix])/(buttonWidth - 1))
    local remainder = math.floor((self:GetHorizontalScroll()-self.minScrollRange[selectedAffix])%(buttonWidth - 1))
    if(delta == -1) then 
        numButtonsPrior = numButtonsPrior + 1  
    else 
        if(remainder == 0) then
            numButtonsPrior = numButtonsPrior - 1 
        end
    end
    -- New scroll pos
    local newPos = self.minScrollRange[selectedAffix] + (numButtonsPrior * (buttonWidth - 1))
    if(newPos > self.maxScrollRange[selectedAffix]) then 
        newPos = self.maxScrollRange[selectedAffix] 
    elseif(newPos < self.minScrollRange[selectedAffix]) then 
        newPos = self.minScrollRange[selectedAffix] 
    end
    self:SetHorizontalScroll(newPos)
    CheckForScrollButtonEnable(self:GetParent(), selectedAffix)
end

--[[
    CreateScrollFrame - Creates a scroll frame for holding a scroll child to scroll.
    @param scrollHolderFrame - the parent frame.
    @return scrollFrame - the created scroll frame
--]]
local function CreateScrollFrame(scrollHolderFrame)
    local scrollFrame = CreateFrame("ScrollFrame", "SCROLLHOLDER_SCROLLFRAME", scrollHolderFrame, "UIPanelScrollFrameTemplate")
    scrollFrame.minScrollRange = { [addon.tyrannicalID] = 1, [addon.fortifiedID] = 1 }
    scrollFrame.maxScrollRange = { [addon.tyrannicalID] = 0, [addon.fortifiedID] = 0 }
    scrollFrame.previousScroll = 1
    scrollFrame.ScrollBar:Hide()
    scrollFrame.ScrollBar:Disable()
    -- up left, down right
    -- scroll to the nearest button edge in the direction the user inputed.
    scrollFrame:SetScript("OnMouseWheel", ScrollButtonRow)
    scrollFrame:SetPoint("LEFT", scrollHolderFrame, "LEFT", 1, 0)
    scrollFrame:SetSize(scrollHolderFrame:GetWidth() - 2, scrollHolderFrame:GetHeight())
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
    local defualtAlpha = 0.7
    local textureName = "Interface/AddOns/MplusGains/Textures/Arrow-" .. direction .. "-Default.PNG"
    local scrollButton = CreateFrame("Button", nil, parentFrame)
    scrollButton:SetPoint("LEFT", anchorFrame, "RIGHT", (direction == "Left") and scrollButtonPadding or -1, 0)
    scrollButton:SetSize(20, parentFrame:GetHeight())
    -- Set texture up and texture down.
    scrollButton.textureUp = scrollButton:CreateTexture()
    scrollButton.textureUp:SetTexture(textureName)
    scrollButton.textureUp:ClearAllPoints()
    scrollButton.textureUp:SetPoint("CENTER")
    scrollButton.textureUp:SetVertexColor(1, 1, 1, defualtAlpha)
    scrollButton.textureDown = scrollButton:CreateTexture()
    scrollButton.textureDown:SetTexture(textureName)
    scrollButton.textureDown:ClearAllPoints()
    scrollButton.textureDown:SetPoint("CENTER")
    scrollButton.textureDown:SetScale(0.9)
    scrollButton:SetNormalTexture(scrollButton.textureUp)
    scrollButton:SetPushedTexture(scrollButton.textureDown)
    scrollButton.disabledTexture = scrollButton:CreateTexture()
    scrollButton.disabledTexture:SetTexture(textureName)
    scrollButton.disabledTexture:ClearAllPoints()
    scrollButton.disabledTexture:SetPoint("CENTER")
    scrollButton.disabledTexture:SetScale(0.9)
    scrollButton.disabledTexture:SetVertexColor(1, 1, 1, 0.2)
    scrollButton:SetDisabledTexture(scrollButton.disabledTexture)
    scrollButton:SetScript("OnClick", function(self, button, down)
        if(button == "LeftButton") then
            ScrollButtonRow(parentFrame.scrollHolderFrame.scrollFrame, (direction == "Left") and 1 or -1)
        end
    end)
    scrollButton:SetScript("OnEnter", function(self, motion)
        self.textureUp:SetVertexColor(1, 1, 1, 1)
    end)
    scrollButton:SetScript("OnLeave", function(self, motion)
        self.textureUp:SetVertexColor(1, 1, 1, defualtAlpha)
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
    frame.gainedScore = { [addon.tyrannicalID] = 0, [addon.fortifiedID] = 0 }
    frame.oppText = frame:CreateFontString(nil, "OVERLAY")
    frame.oppText:SetFont("Fonts\\FRIZQT__.TTF", 9)
    frame.oppText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 8)
    frame.oppText:SetTextColor(0.8, 0.8, 0.8)
    frame.oppText:SetText("")
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
--]]
local function UpdateDungeonButtons(scrollHolderFrame)
    local dungeonID = scrollHolderFrame.scrollChild.dungeonID
    local newLevel = GetStartingLevel(dungeonID, weeklyAffix)
    local oldBase = scrollHolderFrame.scrollChild.baseLevel
    scrollHolderFrame.scrollChild.startingLevel[weeklyAffix] = newLevel
    -- Need new buttons if the newLevel is lower than the base level.
    --TODO: NEEDED?? FIX?
    --[[if(newLevel < oldBase) then
        -- Setup new values and new buttons
        scrollHolderFrame.scrollChild.baseLevel = newLevel
        CalculateScrollHolderUIValues(scrollHolderFrame)
        CreateAllButtons(scrollHolderFrame, oldBase - 1)
        -- Set new anchor point for old level
        scrollHolderFrame.scrollChild.keystoneButtons[oldBase].button:ClearAllPoints()
        scrollHolderFrame.scrollChild.keystoneButtons[oldBase].button:SetPoint("LEFT", scrollHolderFrame.scrollChild.keystoneButtons[oldBase - 1].button, "RIGHT", -1, 0)
    else--]]
    -- Setup new scroll range and pos values
    scrollHolderFrame.scrollFrame.minScrollRange[weeklyAffix] = CalculateScrollMinRange(oldBase, newLevel)
    if((maxLevel - newLevel) < scrollHolderFrame.widthMulti) then
        scrollHolderFrame.scrollFrame.maxScrollRange[weeklyAffix] = scrollHolderFrame.scrollFrame.minScrollRange[weeklyAffix] 
    end
    --end
    -- Reset scroll frame to no key selected state.
    ResetBothToStartingLevel(scrollHolderFrame:GetParent())
end

--[[
    PopulateAllAffixRows - Fill the affix info frames with the affix data
    @param parentFrame - the frame whose children are the affix rows.
--]]
local function PopulateAllAffixRows(parentFrame)
    local sortedAffixes = addon:SortAffixesByLevel()
    local rows = { parentFrame:GetChildren() }
    for i, key in ipairs(sortedAffixes) do
        local affixTable = addon.affixInfo[key]
        rows[i].titleFrame.nameText:SetText(affixTable.name)
        rows[i].titleFrame.levelText:SetText("(+" .. ((affixTable.level ~= 0) and affixTable.level or "?") .. ")")
        rows[i].titleFrame.texture:SetTexture(affixTable.filedataid)
        rows[i].descFrame.descText:SetText(affixTable.description)
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
        CheckForScrollButtonEnable(rows[i].scrollHolderFrame, selectedAffix)
    end
end

--[[
    CreateAllDungeonRows - Creates a row frame for each mythic+ dungeon.
    @param parentFrame - the parent frame for the rows
--]]
local function CreateAllDungeonRows(parentFrame)
    local row = parentFrame
    --for n in pairs(addon.dungeonInfo) do
    for i = 1, 8 do
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
    scoreHeader.ratingText:SetText("0.0")
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
    @return frame - the created frame
--]]
local function CreateAffixInfoFrame(anchorFrame, parentFrame)
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
    frame.titleFrame = CreateFrame("Frame", "AffixHeader", frame)
    frame.titleFrame:SetPoint("TOP")
    local titleFrameHeight = 20
    frame.titleFrame:SetSize(frameWidth, titleFrameHeight)
    frame.titleFrame.nameText = frame.titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline")
    frame.titleFrame.nameText:SetPoint("CENTER")
    frame.titleFrame.levelText = frame.titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline")
    frame.titleFrame.levelText:SetPoint("LEFT", frame.titleFrame.nameText, "RIGHT", xPadding, 0)
    frame.titleFrame.texture = frame.titleFrame:CreateTexture()
    frame.titleFrame.texture:SetPoint("RIGHT", frame.titleFrame.nameText, "LEFT", -4, 0)
    local iconSize = titleFrameHeight/1.2
    frame.titleFrame.texture:SetSize(iconSize, iconSize)
    -- Description
    frame.descFrame = CreateFrame("Frame", "AffixDesc", frame)
    frame.descFrame:SetPoint("TOP", frame.titleFrame, "BOTTOM")
    frame.descFrame:SetSize(frameWidth, frame:GetHeight() - titleFrameHeight)
    frame.descFrame.descText = frame.descFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.descFrame.descText:ClearAllPoints()
    frame.descFrame.descText:SetPoint("TOPLEFT", frame.descFrame, "TOPLEFT")
    frame.descFrame.descText:SetPoint("TOPRIGHT", frame.descFrame, "TOPRIGHT")
    frame.descFrame.descText:SetJustifyH("LEFT")
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
    frame:SetSize(parentFrame:GetWidth() - (xPadding*2) - 20, (dungeonRowHeight * 4) + (yPadding * 5))
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
    if(affix == addon.tyrannicalID) then anchorPosition = "RIGHT" end
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
    holder.tyrFrame = CreateRunFrame(holder, holder, addon.tyrannicalID)
    holder.fortFrame = CreateRunFrame(holder.tyrFrame, holder, addon.fortifiedID)
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
    if(level > 1 and addon.playerBests[affix][dungeonID].rating > 0) then 
        runString = addon:CalculateChest(dungeonID, addon.playerBests[affix][dungeonID].time) .. level
    end
    return runString
end

--[[
    FillBestRunRow - Fills a best run row with a dungeons player data.
    @param rowFrame - the row to fill
    @param dungeonID - the dungeon data to use
--]]
local function FillBestRunRow(rowFrame, dungeonID)
    rowFrame.tyrFrame.keyLevelText:SetText(GetDungeonLevelString(addon.tyrannicalID, dungeonID))
    rowFrame.fortFrame.keyLevelText:SetText(GetDungeonLevelString(addon.fortifiedID, dungeonID))
    rowFrame.scoreFrame.scoreText:SetText(addon:FormatDecimal(addon.playerDungeonRatings[dungeonID].mapScore))
    rowFrame.nameFrame.nameText:SetText(addon.dungeonInfo[dungeonID].name)
end

--[[
    UpdateDungeonBests - Updates dungone bests frame with a re-sort and update new values.
    @param parentFrame - the row being updated
    @param dungeonID - the dungeon being updated
--]]
local function UpdateDungeonBests(parentFrame, dungeonID)
    addon:CalculateDungeonRatings()
    -- Get row position of the dungeon.
    local orderPos = 1
    for key, value in pairs(parentFrame.order) do
        if(value == dungeonID) then orderPos = key break end
    end
    -- If the dungeon isn't the first then re-order where needed.
    if(orderPos > 1) then
        local tempID
        local newPos = orderPos
        local newRow = parentFrame.rows[dungeonID]
        for i = orderPos - 1, 1, -1 do
            tempID = parentFrame.order[i]
            -- If the updated dungeons map score is better than the current iteration rows dungeon
            if(addon.playerDungeonRatings[dungeonID].mapScore > addon.playerDungeonRatings[tempID].mapScore) then
                -- Store the iterations row, replace it with the last iterations row, replace last iteration row variable.
                local tempRow = parentFrame.rows[tempID]
                parentFrame.rows[tempID] = newRow
                newRow = tempRow
                -- Row is being pushed down one, update order of iterations row and position of dungeon being updated.
                parentFrame.order[i + 1] = tempID
                newPos = i
                -- Fill the row with its new dungeons info
                FillBestRunRow(parentFrame.rows[tempID], tempID)
            else
                break
            end
        end
        -- If the order has changed update dungeons associated row and order
        if(newPos ~= orderPos) then
            parentFrame.rows[dungeonID] = newRow 
            parentFrame.order[newPos] = dungeonID
        end
    end
    FillBestRunRow(parentFrame.rows[dungeonID], dungeonID)
end

--[[
    PopulateAllBestRunsRows - Sets players best runs per dungeon data. Called on player entering world.
    @param parentFrame - the parent frame
--]]
local function PopulateAllBestRunsRows(parentFrame)
    local sortedScores = addon:SortDungeonsByScore()
    local rows = { parentFrame:GetChildren() }
    parentFrame.rows = {}
    parentFrame.order = {}
    for i, key in ipairs(sortedScores) do
        local index = i + 1
        FillBestRunRow(rows[index], key)
        parentFrame.order[i] = key
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
    summaryFrame.affixInfoHolderFrame = CreateAffixInfoHolderFrame(summaryFrame.header, summaryFrame)
    local anchor = summaryFrame.affixInfoHolderFrame
    for i = 1, 3 do
        anchor = CreateAffixInfoFrame(anchor, summaryFrame.affixInfoHolderFrame)
    end
    CreateSplitFrame(summaryFrame.affixInfoHolderFrame, summaryFrame)
    -- Best runs
    summaryFrame.bestRunsFrame = CreateBestRunsFrame(summaryFrame.affixInfoHolderFrame, summaryFrame)
    anchor = CreateDungeonSummaryHeader(summaryFrame.bestRunsFrame)
    --for n in pairs(addon.dungeonInfo) do
    for i = 1, 8 do
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
    local url = "https://github.com/keysc3/MplusGains/issues/new/choose"
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
    frame.splitter = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.splitter:ClearAllPoints()
    frame.splitter:SetPoint("LEFT", frame.text, "RIGHT", 4, 0)
    frame.splitter:SetTextColor(_r, _g, _b, _a)
    frame.splitter:SetText("|")
    frame.versionText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.versionText:ClearAllPoints()
    frame.versionText:SetPoint("LEFT", frame.splitter, "RIGHT", 4, 0)
    frame.versionText:SetTextColor(_r, _g, _b, _a)
    frame.versionText:SetText("v" .. GetAddOnMetadata(addonName, "Version"))
    -- Bug report frame and button
    local bugReportFrame = CreateBugReportFrame(frame, parentFrame)
    local bugButton = CreateFrame("Button", nil, frame)
    bugButton:SetPoint("RIGHT", frame, "RIGHT")
    bugButton.text = bugButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bugButton.text:ClearAllPoints()
    bugButton.text:SetPoint("CENTER", bugButton, "CENTER", 0, 0)
    bugButton.text:SetTextColor(_r, _g, _b, _a)
    bugButton.text:SetText("Bug Report")
    bugButton:SetSize(math.ceil(bugButton.text:GetWidth() + 2), frame:GetHeight())
    bugButton:SetHighlightTexture(CreateNewTexture(hover.r, hover.g, hover.b, hover.a/2, bugButton))
    --bugButton:SetPushedTexture(CreateNewTexture(hover.r, hover.g, hover.b, 0.07, bugButton))
    -- Handle button text color change depending on action.
    bugButton:SetScript("OnClick", function(self, btn, down)
        if(btn == "LeftButton") then
            if(bugReportFrame:IsShown()) then
                bugReportFrame:Hide()
            else
                bugReportFrame:Show()
            end
        end
    end)
    bugButton:SetScript("OnMouseDown", function(self, motion)
        self.text:SetTextScale(0.94)
    end)
    bugButton:SetScript("OnMouseUp", function(self, motion)
        self.text:SetTextScale(1)
    end)
end

--[[
    CheckForNewBest - Checks to see if a dungeon run is better than the current best for that dungeon.
    @param dungeonID - the ID of the dungeon to check for
    @param level - the key level
    @param time - the time completed in
    @return bool - whether it is a new best or not.
--]]
local function CheckForNewBest(dungeonID, level, time)
    local completionRating = addon:CalculateRating((time/1000), dungeonID, level)
    if(level > 1 and completionRating > 0) then
        if(completionRating > addon.playerBests[weeklyAffix][dungeonID].rating) then
            return true
        end
    end
    return false
end

--[[
    DataSetup - Setup for all data that will be displayed.
    @param dungeonHolderFrame - the dungeon holder frame containing dungeon rows
    @param summaryFrame - the summary frame containing to be changed values.
    @param headerFrame - the header frame of the main frame.
    @return bool - whether or not the data was setup.
--]]
local function DataSetup(dungeonHolderFrame, summaryFrame, headerFrame)
    weeklyAffix = addon:GetWeeklyAffixInfo()
    if(weeklyAffix == nil) then return false end
    selectedAffix = weeklyAffix
    if(selectedAffix ~= addon.tyrannicalID) then
        SetDesaturation(headerFrame.toggle.toggles[addon.tyrannicalID].texture, true)
    else
        SetDesaturation(headerFrame.toggle.toggles[addon.fortifiedID].texture, true)
    end
    addon:GetGeneralDungeonInfo()
    addon:GetPlayerDungeonBests()
    addon:CalculateDungeonRatings()
    PopulateAllDungeonRows(dungeonHolderFrame)
    PopulateAllAffixRows(summaryFrame.affixInfoHolderFrame)
    PopulateAllBestRunsRows(summaryFrame.bestRunsFrame)
    summaryFrame.header.scoreHeader.ratingText:SetText(addon.totalRating)
    return true
end

--[[
    StartUp - Handles necessary start up actions.
    @return - the main addon frame
--]]
local function StartUp()
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
    mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    mainFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    mainFrame:SetScript("OnEvent", function(self, event, ...)
        -- Player entering world
        if(event == "PLAYER_ENTERING_WORLD") then
            local isInitialLogin, isReloadingUI = ...
            if(isInitialLogin) then
                self:RegisterEvent("MYTHIC_PLUS_CURRENT_AFFIX_UPDATE")
            else
                if(isReloadingUI) then
                    DataSetup(dungeonHolderFrame, summaryFrame, headerFrame)
                end
            end
        end
        -- M+ affix update
        if(event == "MYTHIC_PLUS_CURRENT_AFFIX_UPDATE") then
            -- Affix info is available after this event fires, but not always the first time.
            if(DataSetup(dungeonHolderFrame, summaryFrame, headerFrame)) then
                self:UnregisterEvent(event)
            end
        end
        -- Challenge mode completed
        if(event == "CHALLENGE_MODE_COMPLETED") then
            local dungeonID, level, time, onTime, keystoneUpgradeLevels, practiceRun,
                oldOverallDungeonScore, newOverallDungeonScore, IsMapRecord, IsAffixRecord,
                PrimaryAffix, isEligibleForScore, members
                    = C_ChallengeMode.GetCompletionInfo()
            if(CheckForNewBest(dungeonID, level, time)) then
                -- Replace the old run with the newly completed one and update that dungeons summary and helper row.
                addon:SetNewBest(dungeonID, level, time, weeklyAffix, onTime)
                UpdateDungeonButtons(dungeonHolderFrame.rows[dungeonID].scrollHolderFrame)
                UpdateDungeonBests(summaryFrame.bestRunsFrame, dungeonID)
                -- Set new total, subtract rows gain, set overall gain, and reset row gain to 0.
                summaryFrame.header.scoreHeader.ratingText:SetText(addon.totalRating)
                summaryFrame.header.scoreHeader.gainText:SetText(((totalGained + addon.totalRating) == addon.totalRating) and "" or ("(" .. totalGained + addon.totalRating .. ")"))
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