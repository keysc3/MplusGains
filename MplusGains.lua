local addonName, addon = ...

local myButtons = {}
local selected = { r = 212/255, g = 99/255, b = 0/255, a = 1 }
local hover = { r = 255, g = 255, b = 255, a = 0.1 }
local unselected = { r = 66/255, g = 66/255, b = 66/255, a = 1 }
local outline = { r = 0, g = 0, b = 0, a = 1 }
local textColor = { r = 1, g = 0.82, b = 0, a = 1}
local mainColor = { r = 26/255, g = 26/255, b = 27/255, a = 0.9 }
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
local colorVar = nil
local frameToChange = nil

local icon = LibStub("LibDBIcon-1.0")

local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local dataObject = ldb:NewDataObject("MplusGainsDB", { 
    type = "data source", 
    icon = "Interface\\Addons\\MplusGains\\Textures\\icon.PNG",
    OnClick = function(clickedframe, button)
        if(button == "LeftButton") then
            if(mainFrame ~= nil) then
                if(mainFrame:IsShown()) then
                    mainFrame:Hide()
                else
                    mainFrame:Show()
                end
            end
        elseif(button == "RightButton") then
            if(MplusGainsSettings.minimap.lock) then
                icon:Unlock("MplusGainsDB")
            else
                icon:Lock("MplusGainsDB")
            end
        elseif(button == "MiddleButton") then
            MplusGainsSettings.minimap.hide = true
            icon:Hide("MplusGainsDB")
        end
    end,
})

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0")
LSM:Register("font", "Titillium Web", "Interface\\Addons\\MplusGains\\Fonts\\TitilliumWeb-Regular.ttf")

function dataObject:OnTooltipShow()
    self:AddLine(GetAddOnMetadata(addonName, "Title"), 1, 1, 1)
	self:AddLine("Left click: Toggle main window")
    self:AddLine("Right click: Lock minimap button")
    self:AddLine("Middle click: Disable minimap button")
end

local function OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
	GameTooltip:ClearLines()
	dataObject.OnTooltipShow(GameTooltip)
	GameTooltip:Show()
end

local function ApplyScale(value)
    return addon:RoundToOneDecimal(value * MplusGainsSettings.scale)
end

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
    CustomFontString - Creates and returns a font string with a given color and font.
    @param textSize - Size of the text.
    @param color - Table of the rgb values for the text color.
    @param font - Path to the font being used.
    @param parentFrame - Frame the text is for.
    @param flags - Flags to use with the font.
    --TODO: DOC
    @return text - FontString created.
]]
local function CustomFontString(textSize, color, font, parentFrame, flags, changeFont, changeColor)
    local text = parentFrame:CreateFontString(nil, "OVERLAY")
    text:SetFont(font, ApplyScale(textSize), flags)
    text:SetTextColor(color.r, color.g, color.b, 1)
    text.changeFont = changeFont
    text.changeColor = changeColor
    table.insert(mainFrame.textObjects, text)
    return text
end

--[[
    DefaultFontString - Creates and returns a font string using the addons selected color and font.
    @param textSize - Size of the text.
    @param parentFrame - Frame the text is for.
    @param flags - Flags to use with the font.
    @return text - FontString created.
]]
local function DefaultFontString(textSize, parentFrame, flags)
    local text = parentFrame:CreateFontString(nil, "OVERLAY")
    text:SetFont(MplusGainsSettings.Font.path, ApplyScale(textSize), flags)
    text:SetTextColor(MplusGainsSettings.Colors.main.r, MplusGainsSettings.Colors.main.g, MplusGainsSettings.Colors.main.b, MplusGainsSettings.Colors.main.a)
    text.changeFont = true
    text.changeColor = true
    table.insert(mainFrame.textObjects, text)
    return text
end

--[[
    CreateFrameWithBackdrop - Creates a frame using the backdrop template.
    @param parentFrame - the parent frame
    @param name - the name of the frame
    @return - the created frame
--]]
local function CreateFrameWithBackdrop(frameType, parentFrame, name)
    local frame = CreateFrame(frameType, ((name ~= nil) and name or nil), parentFrame, "BackdropTemplate")
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
    local frame = CreateFrameWithBackdrop("Frame", UIParent, "MainMplusGainsFrame")
    frame.textObjects = {}
    frame.textureObjects = {}
    frame.textWidthFrames = {}
    frame:SetPoint("CENTER", nil, 0, 100)
    frame:SetSize(1, 1)
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
    local selectedColor = MplusGainsSettings.Colors["selectedButton"]
    -- If the clicked button is a higher keystone level than the currently selected button.
    if(keystoneButton.level > parentFrame.selectedLevel[selectedAffix]) then 
        -- Set buttons from the currently selected to the new selected (inclusive) to the selected color.
        for i = parentFrame.selectedLevel[selectedAffix] + 1, keystoneButton.level do
            parentFrame.keystoneButtons[i].button:SetBackdropColor(selectedColor.r, selectedColor.g, selectedColor.b, selectedColor.a)
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
    if(addon:RoundToOneDecimal(scrollFrame.minScrollRange[affixID]) >= scroll) then
        if(leftEnabled) then
            scrollHolderFrame.leftScrollButton:Disable()
        end
    else
        if(not leftEnabled) then
            scrollHolderFrame.leftScrollButton:Enable()
        end
    end
    if(addon:RoundToOneDecimal(scrollFrame.maxScrollRange[affixID]) <= scroll) then
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
    CreateTooltip - Creates a tooltip for the given frame and with the given text.
    @param parentFrame - The parent frame for the tooltip.
    @param anchorFrame - The anchor frame for the tooltip.
    @param textString - The string to set the tooltips text to.
    @return tooltip - The created tooltip.
--]]
local function CreateTooltip(parentFrame, anchorFrame, textString)
    local tooltip = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    tooltip:SetPoint("BOTTOMLEFT", anchorFrame, "TOPLEFT", -2, -1)
    tooltip.padding = 16
    tooltip:SetSize(1, ApplyScale(30))
    tooltip:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    tooltip:SetBackdropColor(0, 0, 0, 0.9)
    tooltip:SetFrameLevel(20)
    tooltip.text = DefaultFontString(12, tooltip, nil)
    tooltip.text:SetPoint("CENTER", tooltip, "CENTER", 0, 0)
    tooltip.text:SetText(textString)
    tooltip:SetWidth(math.ceil(tooltip.text:GetStringWidth() + tooltip.padding))
    table.insert(mainFrame.textWidthFrames, tooltip)
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
    local size = (parentFrame:GetWidth()/1.5) - 2
    button:SetSize(size, size)
    button.texture = button:CreateTexture()
    button.texture:SetTexture(filedataid)
    button:SetNormalTexture(button.texture)
    button:ClearAllPoints()
    button:SetHighlightTexture(CreateNewTexture(hover.r, hover.g, hover.b, hover.a, button))
    button.tooltip = CreateTooltip(parentFrame, button, "View " .. string.lower(name) .. " keys")
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
    CalculateHeight - Calculates the height for a frame.
    @param frame - the frame to caclculate for
    @return totalWidth - the total height needed for the frame
]]
local function CalculateHeight(frame)
    local totalHeight = 0
    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        totalHeight = totalHeight + child:GetHeight()
    end
    return totalHeight
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

local function CreateHeaderButton(parentFrame, point, relativeFrame, relativePoint, OnClick, texturePath)
    local color = MplusGainsSettings.Colors.main
    local headerHeight = parentFrame:GetHeight()
    local button = CreateFrame("Button", nil, parentFrame)
    button:SetPoint(point, relativeFrame, relativePoint)
    button:SetSize(headerHeight, headerHeight)
    button.normalTexture = button:CreateTexture()
    button.normalTexture:ClearAllPoints()
    button.normalTexture:SetPoint("CENTER")
    button.normalTexture:SetTexture(texturePath)
    button.normalTexture:SetVertexColor(color.r, color.g, color.b, 0.9)
    button.normalTexture:SetSize(18, 18)
    button.normalTexture:SetScale(MplusGainsSettings.scale)
    table.insert(mainFrame.textureObjects, button.normalTexture)
    button:SetNormalTexture(button.normalTexture)
    button.pushedTexture = button:CreateTexture()
    button.pushedTexture:ClearAllPoints()
    button.pushedTexture:SetPoint("CENTER")
    button.pushedTexture:SetTexture(texturePath)
    button.pushedTexture:SetVertexColor(color.r, color.g, color.b, 0.9)
    button.pushedTexture:SetSize(18, 18)
    button.pushedTexture:SetScale(ApplyScale(0.9))
    table.insert(mainFrame.textureObjects, button.pushedTexture)
    button:SetPushedTexture(button.pushedTexture)
    button:SetHighlightTexture(CreateNewTexture(hover.r, hover.g, hover.b, hover.a/2, button))
    button:SetScript("OnClick", OnClick)
    return button
end

--[[
    ScrollButtonTexture - Creates a new texture for a drop downs scroll button.
    @param frame - Frame the texture is for
    @param alpha - Alpha of the texture
    @param isUp - The direction of the button
    @param scale - Scale of the texture.
    @return newTexture - Texture that was created.
--]]
local function ScrollButtonTexture(frame, alpha, isUp, scale)
    local rotation = (isUp) and math.pi or 0
    local color = MplusGainsSettings.Colors.main
    local newTexture = frame:CreateTexture()
    newTexture:SetTexture("Interface/AddOns/MplusGains/Textures/arrow-down.PNG")
    newTexture:SetPoint("CENTER", 0, 0)
    newTexture:SetVertexColor(color.r, color.g, color.b, alpha)
    table.insert(mainFrame.textureObjects, newTexture)
    newTexture:SetRotation(rotation)
    newTexture:SetScale(ApplyScale(scale))
    newTexture:SetSize(12, 12)
    return newTexture
end

--[[
    SetupDropdownScrollButton - Sets up the textures for a dropdowns scroll button.
    @param button - The button being setup.
    @param isUp - Boolean for whether it is the up button.
--]]
local function SetupDropdownScrollButton(button, isUp)
    button:SetNormalTexture(ScrollButtonTexture(button, 0.7, isUp, 1))
    button:SetPushedTexture(ScrollButtonTexture(button, 0.7, isUp, 0.9))
    button:SetDisabledTexture(ScrollButtonTexture(button, 0.2, isUp, 0.9))
    button:SetHighlightTexture(CreateNewTexture(hover.r, hover.g, hover.b, hover.a, button))
end

--[[
    CreateScrollFrameButton - Creates a button for a settings scroll frame.
    @param scrollFrameHolder - The scroll frame to add the button to.
    @param anchorFrame - The frame to anchor the new button to.
    @param text - The text to go on the button.
    @param selected - The selected buttons text.
    @param font - The font to use for the button.
    @return newFrame - The created button.
--]]
local function CreateScrollFrameButton(scrollHolderFrame, anchorFrame, text, selected, font)
    local newFrame = CreateFrame("Button", nil, scrollHolderFrame.scrollChild)
    if(text == selected) then 
        scrollHolderFrame.selected = newFrame
    end
    newFrame:SetSize(scrollHolderFrame.scrollChild:GetWidth(), scrollHolderFrame.buttonSize)
    newFrame:SetPoint("TOPLEFT", anchorFrame, (anchorFrame == scrollHolderFrame.scrollChild) and "TOPLEFT" or "BOTTOMLEFT")
    newFrame.texture = newFrame:CreateTexture()
    newFrame.texture:SetTexture("Interface\\buttons\\white8x8")
    newFrame.texture:ClearAllPoints()
    newFrame.texture:SetPoint("CENTER")
    newFrame.texture:SetSize(1, newFrame:GetHeight())
    newFrame.highlightTexture = CreateNewTexture(hover.r, hover.g, hover.b, hover.a, newFrame)
    newFrame:SetHighlightTexture(newFrame.highlightTexture)
    if(newFrame == scrollHolderFrame.selected) then
        newFrame.texture:SetVertexColor(hover.r, hover.g, hover.b, hover.a/2)
        newFrame.highlightTexture:SetVertexColor(0, 0, 0, 0)
    else
        newFrame.texture:SetVertexColor(0, 0, 0, 0)
    end
    newFrame.text = CustomFontString(12, MplusGainsSettings.Colors.main, font, newFrame, "", false, true)
    table.insert(mainFrame.textObjects, newFrame.text)
    newFrame.text:SetPoint("CENTER")
    newFrame.text:SetText(text)
    -- Store largest width of button for sizing on scroll holder frame.
    if(newFrame.text:GetWidth() > scrollHolderFrame.largestWidth) then scrollHolderFrame.largestWidth = newFrame.text:GetWidth() end
    return newFrame
end

--[[
    SetScrollFrameWidths - Sets the widths and points of a settings scrollHolderFrames children and their elements.
    @param scrollHolderFrame - Frame to adjust.
--]]
local function SetScrollFrameWidths(scrollHolderFrame)
    local maxFrameWidth = ApplyScale(300)
    local largestWidth = scrollHolderFrame.largestWidth
    if(largestWidth > maxFrameWidth) then largestWidth = maxFrameWidth end
    largestWidth = math.ceil(largestWidth) + 4
    scrollHolderFrame.scrollFrame:SetWidth(largestWidth)
    scrollHolderFrame.scrollChild:SetWidth(largestWidth)
    scrollHolderFrame:SetWidth(largestWidth)
    local children = { scrollHolderFrame.scrollChild:GetChildren() }
    for _, v in pairs(children) do
        -- Setup text points here to avoid frame width issues.
        v:SetWidth(largestWidth)
        v.text:ClearAllPoints()
        v.text:SetPoint("TOPLEFT", 2, 0)
        v.text:SetPoint("BOTTOMLEFT")
        v.text:SetPoint("RIGHT")
        v.text:SetJustifyH("LEFT")
        v.texture:SetWidth(largestWidth)
    end
end

local function CreateSettingsScrollFrame(parentFrame, settingType, itemAmount)
    local buttonSize = ApplyScale(20)
    local displayLength = 6
    -- Parent frame.
    local scrollHolderFrame = CreateFrame("FRAME", nil, parentFrame)
    scrollHolderFrame.texture = CreateNewTexture(0, 0, 0, 1, scrollHolderFrame)
    scrollHolderFrame.buttonSize = buttonSize
    scrollHolderFrame:SetSize(1, (itemAmount < displayLength) and (buttonSize * itemAmount) or (displayLength * buttonSize))
    scrollHolderFrame:SetSize(1, displayLength * buttonSize)
    scrollHolderFrame:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT")
    -- Anchor frame for the scroll bar.
    local scrollBarHolder = CreateFrame("FRAME", nil, scrollHolderFrame)
    scrollBarHolder:SetSize(math.floor(ApplyScale(18)), parentFrame:GetHeight())
    scrollBarHolder:SetPoint("TOPLEFT", scrollHolderFrame, "TOPRIGHT")
    scrollBarHolder:SetPoint("BOTTOMLEFT", scrollHolderFrame, "BOTTOMRIGHT")
    scrollBarHolder.texture = CreateNewTexture(66, 66, 66, 1, scrollBarHolder)
    -- Scroll frame for the items.
    scrollHolderFrame.scrollFrame = CreateFrame("ScrollFrame", "Settings-" .. settingType, scrollHolderFrame, "UIPanelScrollFrameTemplate")
    local scrollbarName = scrollHolderFrame.scrollFrame:GetName()
    local scrollBar = scrollHolderFrame.scrollFrame.ScrollBar or _G[scrollbarName .."ScrollBar"]
    local scrollUpButton = scrollHolderFrame.scrollFrame.ScrollUpButton or _G[scrollbarName .."ScrollBarScrollUpButton"]
    local scrollDownButton = scrollHolderFrame.scrollFrame.ScrollDownButton or _G[scrollbarName .."ScrollBarScrollDownButton"]
    local thumbTexture = scrollHolderFrame.scrollFrame.ThumbTexture or _G[scrollbarName .."ScrollBarThumbTexture"]
    -- Setup scroll frame components
    scrollBar:SetWidth(ApplyScale(scrollBar:GetWidth()))
    scrollUpButton:ClearAllPoints()
    scrollUpButton:SetPoint("TOPRIGHT", scrollBarHolder, "TOPRIGHT")
    scrollUpButton:SetSize(scrollBarHolder:GetWidth(), scrollBarHolder:GetWidth())
    scrollDownButton:ClearAllPoints()
    scrollDownButton:SetPoint("BOTTOMRIGHT", scrollBarHolder, "BOTTOMRIGHT")
    scrollDownButton:SetSize(scrollBarHolder:GetWidth(), scrollBarHolder:GetWidth())
    thumbTexture:SetTexture("Interface\\buttons\\white8x8")
    thumbTexture:SetVertexColor(1, 1, 1, 0.2)
    thumbTexture:SetWidth(scrollBarHolder:GetWidth())
    thumbTexture:SetHeight(math.floor(scrollBarHolder:GetWidth() * 1.5))
    scrollBar.scrollStep = buttonSize
    scrollBar:SetWidth(ApplyScale(scrollBar:GetWidth()))
    scrollBar:ClearAllPoints()
    scrollBar:SetPoint("TOPRIGHT", scrollUpButton, "BOTTOMRIGHT")
    scrollBar:SetPoint("BOTTOMLEFT", scrollDownButton, "TOPLEFT")
    -- Setup scroll button textures.
    SetupDropdownScrollButton(scrollUpButton, true)
    SetupDropdownScrollButton(scrollDownButton, false)
    scrollHolderFrame.scrollFrame:SetAllPoints(scrollHolderFrame)
    scrollHolderFrame.scrollFrame:SetSize(1, scrollHolderFrame:GetHeight())
    scrollHolderFrame.scrollChild = CreateFrame("Frame", nil)
    scrollHolderFrame.scrollFrame:SetScrollChild(scrollHolderFrame.scrollChild)
    scrollHolderFrame.scrollChild:SetSize(1, 1)
    -- Scroll frame variables
    scrollHolderFrame.selected = nil
    scrollHolderFrame.largestWidth = 0
    scrollHolderFrame:Hide()
    -- OnClick
    parentFrame:SetScript("OnClick", function(self, btn, down)
        if(btn == "LeftButton") then
            if(scrollHolderFrame:IsShown()) then
                scrollHolderFrame:Hide()
            else
                scrollHolderFrame:Show()
            end
        end
    end)
    return scrollHolderFrame
end

local function UpdateTextFont(path)
    for _, v in ipairs(mainFrame.textObjects) do
        if(v.changeFont) then
            local font, size, flags = v:GetFont()
            v:SetFont(path, size, flags)
        end
    end
    for _, v in ipairs(mainFrame.textWidthFrames) do
        v:SetWidth(math.ceil(v.text:GetWidth() + v.padding))
    end
end

--[[
    SetupFontChoices - Handles the setup of the font drop down options and their onclicks.
    @param dropDown - The drop down for the fonts.
--]]
local function SetupFontChoices(dropDown)
    local fontsList = LSM:List("font")
    local scrollHolderFrame = CreateSettingsScrollFrame(dropDown, "Font", #fontsList)
    local anchorFrame = scrollHolderFrame.scrollChild
    for _, v in pairs(fontsList) do
        local newFrame = CreateScrollFrameButton(scrollHolderFrame, anchorFrame, v, MplusGainsSettings.Font.name, LSM:Fetch("font", v))
        newFrame:SetScript("OnClick", function(self, btn, down)
            if(btn == "LeftButton") then
                if(newFrame ~= scrollHolderFrame.selected) then
                    -- Set unselected texture colors.
                    scrollHolderFrame.selected.texture:SetVertexColor(0, 0, 0, 0)
                    scrollHolderFrame.selected.highlightTexture:SetVertexColor(hover.r, hover.g, hover.b, hover.a)
                    -- Set up new selected.
                    scrollHolderFrame.selected = self
                    self.texture:SetVertexColor(hover.r, hover.g, hover.b, hover.a/2)
                    self.highlightTexture:SetVertexColor(0, 0, 0, 0)
                    scrollHolderFrame:GetParent().textFrame.text:SetText(self.text:GetText())
                    local fontName, fontHeight, fontFlags = self.text:GetFont()
                    scrollHolderFrame:GetParent().textFrame.text:SetFont(fontName, fontHeight, fontFlags)
                    MplusGainsSettings.Font.path = fontName
                    MplusGainsSettings.Font.name = v
                    UpdateTextFont(fontName)
                end
                scrollHolderFrame:Hide()
            end
        end)
        anchorFrame = newFrame
    end
    SetScrollFrameWidths(scrollHolderFrame)
end

--[[
    CreateDropDown - Creates a drop down button frame.
    @param parentFrame - Parent frame of the new button.
    @param anchorFrame - Frame to anchor the button to.
    @param text - Text to go on the drop down button.
--]]
local function CreateDropDown(parentFrame, anchorFrame, text)
    local color = MplusGainsSettings.Colors.main
    -- Button frame
    local fontDropDownButton = CreateFrameWithBackdrop("Button", parentFrame, nil)
    fontDropDownButton:SetBackdropColor(unselected.r, unselected.g, unselected.b, 1)
    fontDropDownButton:SetPoint("LEFT", anchorFrame, "RIGHT")
    fontDropDownButton:SetSize(parentFrame:GetWidth()/1.8, parentFrame:GetHeight())
    fontDropDownButton:SetScript("OnEnter", function(self, motion)
        self:SetBackdropBorderColor(1, 1, 1, 1)
    end)
    fontDropDownButton:SetScript("OnLeave", function(self, motion)
        self:SetBackdropBorderColor(outline.r, outline.g, outline.b, outline.a)
    end)
    -- Text frame
    local textFrame = CreateFrame("Frame", nil, fontDropDownButton)
    fontDropDownButton.textFrame = textFrame
    textFrame:SetSize(fontDropDownButton:GetWidth() - fontDropDownButton:GetHeight(), fontDropDownButton:GetHeight())
    textFrame:SetPoint("LEFT")
    textFrame.text = DefaultFontString(12, textFrame, "")
    textFrame.text:ClearAllPoints()
    textFrame.text:SetPoint("TOPLEFT", 2, 0)
    textFrame.text:SetPoint("BOTTOMLEFT")
    textFrame.text:SetPoint("RIGHT")
    textFrame.text:SetText(text)
    textFrame.text:SetJustifyH("LEFT")
    -- Texture frame
    local textureFrame = CreateFrame("Frame", nil, fontDropDownButton)
    textureFrame:SetSize(fontDropDownButton:GetHeight(), fontDropDownButton:GetHeight())
    textureFrame:SetPoint("RIGHT")
    textureFrame.texture = textureFrame:CreateTexture()
    textureFrame.texture:SetTexture("Interface/AddOns/MplusGains/Textures/arrow-down.PNG")
    --textureFrame.texture:SetRotation(-(math.pi/2))
    textureFrame.texture:ClearAllPoints()
    textureFrame.texture:SetPoint("CENTER", 0, 0)
    textureFrame.texture:SetSize(12, 12)
    textureFrame.texture:SetVertexColor(color.r, color.g, color.b, 0.7)
    textureFrame.texture:SetScale(MplusGainsSettings.scale)
    table.insert(mainFrame.textureObjects, textureFrame.texture)
    -- Mouse enter and leave
    fontDropDownButton:SetScript("OnEnter", function(self, motion)
        self:SetBackdropBorderColor(0.8, 0.8, 0.8 , 1)
        textureFrame.texture:SetVertexColor(color.r, color.g, color.b, 1)
    end)
    fontDropDownButton:SetScript("OnLeave", function(self, motion)
        self:SetBackdropBorderColor(outline.r, outline.g, outline.b, outline.a)
        textureFrame.texture:SetVertexColor(color.r, color.g, color.b, 0.7)
    end)
    return fontDropDownButton
end

--[[
    lerp - Linearly interpolates between two points.
    @param a - Start value
    @param b - End value
    @param t - Interpolation value between a and b
    @return - Interpolated value between a and b
--]]
local function lerp(a, b, t)
    return ((1 - t) * a) + (t * b)
end

--[[
    CreateSlider - Creates a settings frame slider.
    @param parentFrame - The new frames parent.
    @param anchorFrame - The new frames anchor frame.
    @param minValue - Sliders minimum value.
    @param maxValue - Sliders maximum value.
    @param setting - Setting that the slider is changing.
    @return slider - The newly created slider.
--]]
local function CreateSlider(parentFrame, anchorFrame, minValue, maxValue, setting)
    local c1 = 40/255
    local c2 = 20/255
    -- SLider values
    local slider = CreateFrameWithBackdrop("Slider", parentFrame, nil)
    slider:SetBackdropColor(unselected.r, unselected.g, unselected.b, 1)
    slider:SetSize(parentFrame:GetWidth()/1.8, parentFrame:GetHeight())
    slider:SetOrientation("HORIZONTAL")
    slider:SetPoint("LEFT", anchorFrame, "RIGHT")
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValue(MplusGainsSettings[setting])
    slider:Enable()
    slider:Show()
    slider.mouseDown = false
    slider.entered = false
    slider.width = slider:GetWidth()
    -- Thumb
    slider.ThumbTexture = slider:CreateTexture()
    slider.ThumbTexture:SetTexture("Interface\\buttons\\white8x8")
    slider.ThumbTexture:SetVertexColor(c1, c1, c1, 1)
    slider.ThumbTexture:SetSize(ApplyScale(30), slider:GetHeight() - 2)
    slider:SetThumbTexture(slider.ThumbTexture)
    -- Text
    slider.text = DefaultFontString(12, slider, "")
    slider.text:SetText(addon:FormatDecimal(MplusGainsSettings[setting]))

    local halfThumb = slider.ThumbTexture:GetWidth()/2
    slider.halfThumb = halfThumb
    -- Better way to do this than a lerp?
    local offset = lerp(halfThumb, slider.width - halfThumb, (slider:GetValue() - minValue)/(maxValue - minValue))
    slider.text:SetPoint("CENTER", slider, "LEFT", offset, 0)
    slider:SetScript("OnValueChanged", function(self, value)
        local rMin, rMax = self:GetMinMaxValues()
        offset = lerp(self.halfThumb, self.width - self.halfThumb, (slider:GetValue() - rMin)/(rMax - rMin))
        self.text:SetPoint("CENTER", self, "LEFT", offset, 0)
        local newValue = addon:RoundToOneDecimal(value)
        if(newValue ~= MplusGainsSettings[setting]) then
            self.text:SetText(addon:FormatDecimal(newValue))
            MplusGainsSettings[setting] = newValue
        end
    end)
    -- Slider animations
    slider:SetScript("OnEnter", function(self, motion)
        self.entered = true
        self.ThumbTexture:SetVertexColor(c2, c2, c2, 1)
        self:SetBackdropBorderColor(1, 1, 1, 1)
    end)
    slider:SetScript("OnLeave", function(self, motion)
        self.entered = false
        if(not self.mouseDown) then
            self.ThumbTexture:SetVertexColor(c1, c1, c1, 1)
            self:SetBackdropBorderColor(outline.r, outline.g, outline.b, outline.a)
        end
    end)
    slider:SetScript("OnMouseDown", function(self, button)
        if(button == "LeftButton") then
            self.mouseDown = true
        end
    end)
    slider:SetScript("OnMouseUp", function(self, button)
        if(button == "LeftButton") then
            self.mouseDown = false
        end
        if(not self.entered) then
            self.ThumbTexture:SetVertexColor(c1, c1, c1, 1)
            self:SetBackdropBorderColor(outline.r, outline.g, outline.b, outline.a)
        end
    end)
    return slider
end

local function UpdateSelectedButtonColor()
    for _, v in pairs(mainFrame.dungeonHolderFrame.rows) do
        local scrollChild = v.scrollHolderFrame.scrollChild
        for i = scrollChild.baseLevel, scrollChild.selectedLevel[selectedAffix] do
            scrollChild.keystoneButtons[i].button:SetBackdropColor(MplusGainsSettings.Colors.selectedButton.r, MplusGainsSettings.Colors.selectedButton.g, 
            MplusGainsSettings.Colors.selectedButton.b, MplusGainsSettings.Colors.selectedButton.a)
        end
    end
end

local function UpdateTextColor()
    for _, v in ipairs(mainFrame.textObjects) do
        if(v.changeColor) then
            v:SetTextColor(MplusGainsSettings.Colors.main.r, MplusGainsSettings.Colors.main.g, 
            MplusGainsSettings.Colors.main.b, MplusGainsSettings.Colors.main.a)
        end
    end
end

local function UpdateTextureColor()
    for _, v in ipairs(mainFrame.textureObjects) do
        v:SetVertexColor(MplusGainsSettings.Colors.main.r, MplusGainsSettings.Colors.main.g, 
        MplusGainsSettings.Colors.main.b, v:GetAlpha())
    end
end

local function ColorCallback(restore)
    local newR, newG, newB, newA;
    -- If canceled
    if restore then
        newR, newG, newB, newA = unpack(restore)
        
    else
        newA, newR, newG, newB = ColorPickerFrame:GetColorAlpha(), ColorPickerFrame:GetColorRGB()
    end
    -- Set color variable
    if(colorVar ~= nil) then
        MplusGainsSettings.Colors[colorVar].r = newR
        MplusGainsSettings.Colors[colorVar].g = newG
        MplusGainsSettings.Colors[colorVar].b = newB
        MplusGainsSettings.Colors[colorVar].a = newA
        if(colorVar == "selectedButton") then UpdateSelectedButtonColor() end
        if(colorVar == "main") then 
            UpdateTextColor()
            UpdateTextureColor()
         end
    end
    if(frameToChange ~= nil) then
        frameToChange:SetBackdropColor(newR, newG, newB, newA)
    end
end

local function ShowColorPicker(var, frame)
    local color = MplusGainsSettings.Colors[var]
    colorVar = var
    frameToChange = frame
    ColorPickerFrame.hasOpacity, ColorPickerFrame.opacity = false, color.a
    ColorPickerFrame.previousValues = { color.r, color.g, color.b, color.a }
    ColorPickerFrame.swatchFunc, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = ColorCallback, ColorCallback, ColorCallback
    ColorPickerFrame.Content.ColorSwatchOriginal:SetColorTexture(color.r, color.g, color.b)
    ColorPickerFrame.Content.ColorPicker:SetColorRGB(color.r, color.g, color.b)
    ColorPickerFrame:Hide() -- Need to run the OnShow handler.
    ColorPickerFrame:Show()
end

local function CreateColorPickerFrame(parentFrame, anchorFrame, rowHeight, text, colorTableName)
    -- Main frame
    local frame = CreateFrame("Frame", nil, parentFrame)
    frame:SetSize(parentFrame:GetWidth(), rowHeight)
    frame:SetPoint("TOP", anchorFrame, "BOTTOM", 0, -2)
    -- Text
    local label = CreateFrame("Frame", nil, frame)
    label:SetSize(frame:GetWidth()/4, frame:GetHeight())
    label:SetPoint("LEFT", 2, 0)
    label.text = DefaultFontString(12, label, "OUTLINE")
    label.text:ClearAllPoints()
    label.text:SetPoint("LEFT")
    label.text:SetText(text)
    -- Color button
    local button = CreateFrameWithBackdrop("Button", frame, nil)
    button:SetBackdropColor(MplusGainsSettings.Colors[colorTableName].r, MplusGainsSettings.Colors[colorTableName].g, 
    MplusGainsSettings.Colors[colorTableName].b, MplusGainsSettings.Colors[colorTableName].a)
    button:SetPoint("LEFT", label, "RIGHT")
    button:SetSize(frame:GetHeight(), frame:GetHeight())
    button:SetScript("OnEnter", function(self, motion)
        self:SetBackdropBorderColor(1, 1, 1, 1)
    end)
    button:SetScript("OnLeave", function(self, motion)
        self:SetBackdropBorderColor(outline.r, outline.g, outline.b, outline.a)
    end)
    button:SetScript("OnClick", function(self, motion)
        ShowColorPicker(colorTableName, self)
    end)
    return frame
end

--[[
    CreateSettingsWindow - Handles the setup of the settings frame.
    @param parentFrame - The parent frame for the settings frame.
    @return frame - The newly created frame
--]]
local function CreateSettingsWindow(parentFrame)
    local rowHeight = ApplyScale(20)
    local headerHeight = ApplyScale(40)
    local frame = CreateFrameWithBackdrop("Frame", parentFrame, "SETTINGS_FRAME")
    frame:SetSize(ApplyScale(240), ApplyScale(200))
    frame:SetPoint("CENTER")
    frame:SetBackdropColor(26/255, 26/255, 27/255, 0.95)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:Hide()
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOP")
    header:SetSize(frame:GetWidth(), headerHeight)
    header.text = DefaultFontString(14, header, "OUTLINE")
    header.text:ClearAllPoints()
    header.text:SetPoint("LEFT", 2, 0)
    header.text:SetText("Settings")
    -- Exit button
    local function ExitOnClick(self, button, down)
        if(button == "LeftButton") then frame:Hide() end
    end
    local exitButton = CreateHeaderButton(header, "RIGHT", header, "RIGHT", ExitOnClick, "Interface/AddOns/MplusGains/Textures/exit.PNG")
    -- Font setting
    local fontFrame = CreateFrame("Frame", nil, frame)
    fontFrame:SetSize(frame:GetWidth(), rowHeight)
    fontFrame:SetPoint("TOP", header, "BOTTOM")
    local fontLabel = CreateFrame("Frame", nil, fontFrame)
    fontLabel:SetSize(fontFrame:GetWidth()/4, fontFrame:GetHeight())
    fontLabel:SetPoint("LEFT", 2, 0)
    fontLabel.text = DefaultFontString(12, fontLabel, "OUTLINE")
    fontLabel.text:ClearAllPoints()
    fontLabel.text:SetPoint("LEFT")
    fontLabel.text:SetText("Font")
    -- Font dropdown
    local fontDropDown = CreateDropDown(fontFrame, fontLabel, MplusGainsSettings.Font.name)
    SetupFontChoices(fontDropDown)
    -- Scaling frame
    local scalingFrame = CreateFrame("Frame", nil, frame)
    scalingFrame:SetSize(frame:GetWidth(), rowHeight)
    scalingFrame:SetPoint("TOP", fontFrame, "BOTTOM", 0, -2)
    local scalingLabel = CreateFrame("Frame", nil, scalingFrame)
    scalingLabel:SetSize(scalingFrame:GetWidth()/4, scalingFrame:GetHeight())
    scalingLabel:SetPoint("LEFT", 2, 0)
    scalingLabel.text = DefaultFontString(12, scalingLabel, "OUTLINE")
    scalingLabel.text:ClearAllPoints()
    scalingLabel.text:SetPoint("LEFT")
    scalingLabel.text:SetText("Scale")
    -- Scale slider
    local scalingSlider = CreateSlider(scalingFrame, scalingLabel, 0.6, 1.4, "scale")
    -- Main color frame
    local mainColorFrame = CreateColorPickerFrame(frame, scalingFrame, rowHeight, "Theme", "main")
    -- Selected button color frame
    local selectedButtonColorFrame = CreateColorPickerFrame(frame, mainColorFrame, rowHeight, "Button", "selectedButton")
    -- Frame height
    frame:SetHeight((header:GetHeight() - header.text:GetStringHeight())/2 + CalculateHeight(frame) + 0.1)
    return frame
end

--[[
    CreateHeaderFrame- Creates the header frame for the addon.
    @param parentFrame - the parent frame to use
    @return frame - the created frame
--]]
local function CreateHeaderFrame(parentFrame)
    local color = MplusGainsSettings.Colors.main
    local headerWidthDiff = 8
    local headerHeight = ApplyScale(40)
    local frame = CreateFrameWithBackdrop("Frame", parentFrame, "Header")
    frame:SetPoint("TOP", parentFrame, "TOP", 0, - (headerWidthDiff/2))
    frame:SetSize(parentFrame:GetWidth() - headerWidthDiff, headerHeight)
    frame.text = DefaultFontString(24, frame, "OUTLINE")
    frame.text:SetPoint("CENTER")
    frame.text:SetText(GetAddOnMetadata(addonName, "Title"))
    -- Exit button
    local function ExitOnClick(self, button, down)
        if(button == "LeftButton") then parentFrame:Hide() end
    end
    local exitButton = CreateHeaderButton(frame, "RIGHT", frame, "RIGHT", ExitOnClick, "Interface/AddOns/MplusGains/Textures/exit.PNG")
    local r, g, b, a = 207/255, 170/255, 0, 1
    -- Settings button
    local settingsFrame = CreateSettingsWindow(parentFrame)
    local function SettingsOnClick(self, button, down)
        if(button == "LeftButton") then 
            if(settingsFrame:IsShown()) then
                settingsFrame:Hide() 
            else
                settingsFrame:Show()
            end
        end
    end

    local settingsButton = CreateHeaderButton(frame, "RIGHT", exitButton, "LEFT", SettingsOnClick, "Interface/AddOns/MplusGains/Textures/settings.PNG")
    -- Reset button
    local function ResetOnClick(self, btn, down)
        if(btn == "LeftButton") then
            if(mainFrame.dungeonHolderFrame.rows ~= nil) then
                for key, value in pairs(mainFrame.dungeonHolderFrame.rows) do
                    ResetBothToStartingLevel(value)
                end
                mainFrame.summaryFrame.header.scoreHeader.gainText:SetText("")
            end
        end
    end
    local resetButton = CreateHeaderButton(frame, "LEFT", frame, "LEFT", ResetOnClick, "Interface/AddOns/MplusGains/Textures/reset.PNG")
    local width = resetButton.normalTexture:GetWidth() + 10
    resetButton.normalTexture:SetSize(width, width)
    resetButton.pushedTexture:SetSize(width, width)
    resetButton.tooltip = CreateTooltip(frame, resetButton, "Reset selected keys")
    resetButton:SetScript("OnEnter", function(self, motion)
        self.tooltip:Show()
    end)
    resetButton:SetScript("OnLeave", function(self, motion)
        self.tooltip:Hide()
    end)
    -- Create the weekly affix toggles
    local toggle = CreateFrame("Frame", nil, frame)
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
    local frame = CreateFrameWithBackdrop("Frame", parentFrame, nil)
    local yOffset = yPadding
    local anchorPoint = "BOTTOMLEFT"
    if(anchorFrame == parentFrame) then
        yOffset = 0
        anchorPoint = "TOPLEFT"
    end
    frame:SetPoint("TOPLEFT", anchorFrame, anchorPoint, 0, yOffset)
    frame:SetSize(ApplyScale(600), dungeonRowHeight)
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
    frame:SetSize(ApplyScale(150), parentRow:GetHeight())
    frame.text = DefaultFontString(12, frame, nil)
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
    frame.text = DefaultFontString(12, frame, nil)
    frame.text:SetPoint("LEFT")
    frame.text:SetText("xx:xx")
    frame:SetSize(ApplyScale(40), parentRow:GetHeight())

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
    local btn = CreateFrameWithBackdrop("Button", parentFrame, parentFrame:GetName() .. "Button" .. "+" .. tostring(keyLevel))
    btn:SetBackdropColor(unselected.r, unselected.g, unselected.b, unselected.a)
    -- If anchorButton is nil then it is the first in its parent frame, so set anchoring appropriately.
    if(anchorButton ~= nil) then 
        btn:SetPoint("LEFT", anchorButton, "RIGHT", -1, 0)
    else
        btn:SetPoint("LEFT", parentFrame, "LEFT")
    end
    btn:SetSize(buttonWidth, parentFrame:GetHeight())
    btn:SetBackdropColor(unselected.r, unselected.g, unselected.b, unselected.a)
    btn:SetText((keyLevel > 1) and ("+" .. keyLevel) or "-")
    btn:SetHighlightTexture(CreateNewTexture(hover.r, hover.g, hover.b, hover.a, btn))
    -- Create keystone button font
    local myFont = CreateFont("Font")
    myFont:SetFont(MplusGainsSettings.Font.path, ApplyScale(12), "OUTLINE, MONOCHROME")
    myFont:SetTextColor(1, 1, 1, 1)
    myFont.changeFont = true
    btn:SetNormalFontObject(myFont)
    table.insert(mainFrame.textObjects, myFont)
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
                    if(parentFrame.selectedLevel[opp] >= parentFrame.startingLevel[opp]) then
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
    local numButtonsPrior = math.floor(addon:RoundToOneDecimal((self:GetHorizontalScroll()-self.minScrollRange[selectedAffix]))/(buttonWidth - 1))
    local remainder = math.floor(addon:RoundToOneDecimal((self:GetHorizontalScroll()-self.minScrollRange[selectedAffix]))%(buttonWidth - 1))
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
    @param isLeft - the direction to point the arrow in.
--]]
local function CreateScrollButton(parentFrame, anchorFrame, isLeft)
    local defualtAlpha = 0.7
    local rotation = (isLeft) and -(math.pi/2) or math.pi/2
    local color = MplusGainsSettings.Colors.main
    local textureName = "Interface/AddOns/MplusGains/Textures/arrow-down.PNG"
    local scrollButton = CreateFrame("Button", nil, parentFrame)
    scrollButton:SetPoint("LEFT", anchorFrame, "RIGHT", (isLeft) and scrollButtonPadding or -1, 0)
    scrollButton:SetSize(ApplyScale(20),  parentFrame:GetHeight())
    -- Set texture up and texture down.
    scrollButton.textureUp = scrollButton:CreateTexture()
    scrollButton.textureUp:SetTexture(textureName)
    scrollButton.textureUp:ClearAllPoints()
    scrollButton.textureUp:SetPoint("CENTER")
    scrollButton.textureUp:SetVertexColor(color.r, color.g, color.b, defualtAlpha)
    scrollButton.textureUp:SetSize(14, 14)
    scrollButton.textureUp:SetRotation(rotation)
    table.insert(mainFrame.textureObjects, scrollButton.textureUp)
    scrollButton.textureUp:SetScale(MplusGainsSettings.scale)
    scrollButton.textureDown = scrollButton:CreateTexture()
    scrollButton.textureDown:SetTexture(textureName)
    scrollButton.textureDown:ClearAllPoints()
    scrollButton.textureDown:SetPoint("CENTER")
    scrollButton.textureDown:SetScale(MplusGainsSettings.scale - 0.2)
    scrollButton.textureDown:SetVertexColor(color.r, color.g, color.b, 1)
    scrollButton.textureDown:SetSize(14, 14)
    scrollButton.textureDown:SetRotation(rotation)
    table.insert(mainFrame.textureObjects, scrollButton.textureDown)
    scrollButton:SetNormalTexture(scrollButton.textureUp)
    scrollButton:SetPushedTexture(scrollButton.textureDown)
    scrollButton.disabledTexture = scrollButton:CreateTexture()
    scrollButton.disabledTexture:SetTexture(textureName)
    scrollButton.disabledTexture:ClearAllPoints()
    scrollButton.disabledTexture:SetPoint("CENTER")
    scrollButton.disabledTexture:SetScale(MplusGainsSettings.scale - 0.2)
    scrollButton.disabledTexture:SetVertexColor(color.r, color.g, color.b, 0.2)
    scrollButton.disabledTexture:SetSize(14, 14)
    scrollButton.disabledTexture:SetRotation(rotation)
    table.insert(mainFrame.textureObjects, scrollButton.disabledTexture)
    scrollButton:SetDisabledTexture(scrollButton.disabledTexture)
    scrollButton:SetScript("OnClick", function(self, button, down)
        if(button == "LeftButton") then
            ScrollButtonRow(parentFrame.scrollHolderFrame.scrollFrame, (isLeft) and 1 or -1)
        end
    end)
    scrollButton:SetScript("OnEnter", function(self, motion)
        self.textureUp:SetVertexColor(color.r, color.g, color.b, 1)
    end)
    scrollButton:SetScript("OnLeave", function(self, motion)
        self.textureUp:SetVertexColor(color.r, color.g, color.b, defualtAlpha)
    end)
    return scrollButton
end

--[[
    CreateScrollHolderFrame - Creates a scroll holder frame for a scroll frame.
    @param parentRow - the parent row frame
    @return scrollHolderFrame - the created frame
--]]
local function CreateScrollHolderFrame(parentRow)
    local scrollHolderFrame = CreateFrameWithBackdrop("Frame", parentRow, nil)
    scrollHolderFrame.widthMulti = 6
    -- Width is multiple of button size minus thee same multiple so button border doesn't overlap/combine with frame border.
    scrollHolderFrame:SetSize((scrollHolderFrame.widthMulti * buttonWidth) - scrollHolderFrame.widthMulti, parentRow:GetHeight())
    scrollHolderFrame.scrollFrame = CreateScrollFrame(scrollHolderFrame)
    scrollHolderFrame.scrollChild = CreateScrollChildFrame(scrollHolderFrame)
    scrollHolderFrame.scrollFrame:SetScrollChild(scrollHolderFrame.scrollChild)
    scrollHolderFrame.scrollChild:SetSize(0, scrollHolderFrame.scrollFrame:GetHeight())
    local leftScrollButton = CreateScrollButton(parentRow, parentRow.dungeonTimerFrame, true)
    scrollHolderFrame:SetPoint("LEFT", leftScrollButton, "RIGHT")
    scrollHolderFrame.leftScrollButton = leftScrollButton
    local rightScrollButton = CreateScrollButton(parentRow, scrollHolderFrame, false)
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
    frame.text = DefaultFontString(12, frame, nil)
    frame.text:SetPoint("LEFT")
    frame.text:SetText("+0.0")
    frame:SetSize(ApplyScale(32), parentRow:GetHeight())
    frame.gainedScore = { [addon.tyrannicalID] = 0, [addon.fortifiedID] = 0 }
    frame.oppText = CustomFontString(9, {r = 0.8, g = 0.8, b = 0.8, a = 1}, MplusGainsSettings.Font.path, frame, nil, true, false)
    frame.oppText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 8)
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
    local frame = CreateFrameWithBackdrop("Frame", parentFrame, "Summary")
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
    playerName.playerText = DefaultFontString(16, playerName, "OUTLINE")
    playerName.playerText:SetPoint("BOTTOM")
    playerName.playerText:SetText(UnitName("player") .. " (" .. GetRealmName() .. ")")
    local scoreHeader = CreateFrame("Frame", "ScoreHeader", frame)
    scoreHeader:SetPoint("TOP", playerName, "BOTTOM")
    scoreHeader:SetSize(frame:GetWidth(), frame:GetHeight()/2)
    scoreHeader.ratingText = DefaultFontString(16, scoreHeader, "OUTLINE")
    scoreHeader.ratingText:SetPoint("TOP", scoreHeader, "TOP")
    scoreHeader.ratingText:SetText("0.0")
    scoreHeader.gainText = DefaultFontString(10, scoreHeader, "OUTLINE")
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
    frame.titleFrame.nameText = DefaultFontString(14, frame.titleFrame, "OUTLINE")
    frame.titleFrame.nameText:SetPoint("CENTER")
    frame.titleFrame.levelText = DefaultFontString(14, frame.titleFrame, "OUTLINE")
    frame.titleFrame.levelText:SetPoint("LEFT", frame.titleFrame.nameText, "RIGHT", xPadding, 0)
    frame.titleFrame.texture = frame.titleFrame:CreateTexture()
    frame.titleFrame.texture:SetPoint("RIGHT", frame.titleFrame.nameText, "LEFT", -4, 0)
    local iconSize = titleFrameHeight/1.2
    frame.titleFrame.texture:SetSize(iconSize, iconSize)
    -- Description
    frame.descFrame = CreateFrame("Frame", "AffixDesc", frame)
    frame.descFrame:SetPoint("TOP", frame.titleFrame, "BOTTOM")
    frame.descFrame:SetSize(frameWidth, frame:GetHeight() - titleFrameHeight)
    frame.descFrame.descText = DefaultFontString(12, frame.descFrame, nil)
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
    local frame = CreateFrameWithBackdrop("Frame", parentFrame, nil)
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
    frame.smallColumnWidth = ApplyScale(60)
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
    affixFrame.keyLevelText = DefaultFontString(12, affixFrame, nil)
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
    scoreFrame.scoreText = DefaultFontString(12, scoreFrame, nil)
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
    nameFrame:SetSize(parentFrame:GetWidth() - (totalWidth + 10), parentFrame:GetHeight())
    nameFrame.nameText = DefaultFontString(12, nameFrame, nil)
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
    scoreHeader.text = DefaultFontString(12, scoreHeader, "OUTLINE")
    scoreHeader.text:ClearAllPoints()
    scoreHeader.text:SetPoint("LEFT", scoreHeader, "LEFT")
    scoreHeader.text:SetPoint("RIGHT", scoreHeader, "RIGHT")
    scoreHeader.text:SetJustifyH("LEFT")
    scoreHeader.text:SetText("SCORE")
    -- Dungeon name column
    local dungeonHeader = CreateFrame("Frame", nil, holder)
    dungeonHeader:SetPoint("LEFT", holder, "LEFT")
    dungeonHeader:SetSize(parentFrame:GetWidth() - (parentFrame.smallColumnWidth * 3), holderHeight)
    dungeonHeader.text = DefaultFontString(12, dungeonHeader, "OUTLINE")
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
    @param parentFrame - the parent frame of the created frame
    @return frame - the created frame
--]]
local function CreateBugReportFrame(anchorFrame, parentFrame)
    local url = "https://github.com/keysc3/MplusGains/issues/new/choose"
    -- Holder
    local frame = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    frame:SetSize(ApplyScale(300), ApplyScale(80))
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
    frame.headerText = DefaultFontString(16, frame, nil)
    frame.headerText:ClearAllPoints()
    frame.headerText:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
    frame.headerText:SetText("Report a Bug")
    -- Edit box
    frame.editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    frame.editBox:SetSize(frame:GetWidth() - 40, ApplyScale(20))
    -- TODO: TEXT SIZE
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
    frame.copyText = DefaultFontString(12, frame, nil)
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
    local color = { r = 100/255, g = 100/255, b = 100/255, 1} 
    -- Holder
    local frame = CreateFrame("Frame", nil, parentFrame)
    frame:SetSize(headerFrame:GetWidth(), parentFrame:GetHeight() - anchorFrame:GetHeight() - headerFrame:GetHeight() + (yPadding*6))
    frame:SetPoint("BOTTOM", parentFrame, "BOTTOM", 0, 4)
    -- Creator text
    frame.text = CustomFontString(10, color, MplusGainsSettings.Font.path, frame, nil, true, false)
    frame.text:ClearAllPoints()
    frame.text:SetPoint("LEFT", frame, "LEFT", 1, 0)
    frame.text:SetText("Made by ExplodingMuffins")
    frame.splitter = CustomFontString(10, color, MplusGainsSettings.Font.path, frame, nil, true, false)
    frame.splitter:ClearAllPoints()
    frame.splitter:SetPoint("LEFT", frame.text, "RIGHT", 4, 0)
    frame.splitter:SetText("|")
    frame.versionText = CustomFontString(10, color, MplusGainsSettings.Font.path, frame, nil, true, false)
    frame.versionText:ClearAllPoints()
    frame.versionText:SetPoint("LEFT", frame.splitter, "RIGHT", 4, 0)
    frame.versionText:SetText("v" .. GetAddOnMetadata(addonName, "Version"))
    -- Bug report frame and button
    local bugReportFrame = CreateBugReportFrame(frame, parentFrame)
    local bugButton = CreateFrame("Button", nil, frame)
    bugButton:SetPoint("RIGHT", frame, "RIGHT")
    bugButton.text = CustomFontString(10, color, MplusGainsSettings.Font.path, bugButton, nil, true, false)
    bugButton.text:ClearAllPoints()
    bugButton.text:SetPoint("CENTER", bugButton, "CENTER", 0, 0)
    bugButton.text:SetText("Bug Report")
    bugButton.padding = 2
    bugButton:SetSize(math.ceil(bugButton.text:GetWidth() + bugButton.padding), frame:GetHeight())
    table.insert(mainFrame.textWidthFrames, bugButton)
    bugButton:SetHighlightTexture(CreateNewTexture(hover.r, hover.g, hover.b, hover.a/2, bugButton))
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
    local headerFrame
    local dungeonHolderFrame
    local summaryFrame
    -- Data setup.
    mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    mainFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    mainFrame:RegisterEvent("ADDON_LOADED")
    mainFrame:SetScript("OnEvent", function(self, event, ...)
        if(event == "ADDON_LOADED") then
            local addonLoaded = ...
            if(addonLoaded == "MplusGains") then
                if(MplusGainsSettings == nil) then
                    -- Set initial font
                    MplusGainsSettings = {
                        Count = 1, 
                        Font = { 
                            path = "Fonts\\FRIZQT__.TTF", 
                            name = "Friz Quadrata TT", 
                        }, 
                        scale = 1.0, 
                        Colors = { 
                            main = { r = 1, g = 0.82, b = 0, a = 1}, 
                            selectedButton = { r = 212/255, g = 99/255, b = 0, a = 1 },
                        },
                        minimap = { 
                            hide = false,
                            minimapPos = nil,
                            lock = false,
                         },
                    }
                else
                    -- Use saved variable font
                    MplusGainsSettings.Count = MplusGainsSettings.Count + 1
                    local fontCheck = LSM:Fetch("font", MplusGainsSettings.Font.name)
                    if(fontCheck == nil) then 
                        MplusGainsSettings.Font.path = "Fonts\\FRIZQT__.TTF"
                        MplusGainsSettings.Font.name = "Friz Quadrata TT"
                    end
                end
                -- Register minimap icon.
                icon:Register("MplusGainsDB", dataObject, MplusGainsSettings.minimap)
                -- Setup static frames.
                buttonWidth = math.floor(ApplyScale(buttonWidth))
                dungeonRowHeight = ApplyScale(dungeonRowHeight)
                mainFrame:SetSize(ApplyScale(1000), ApplyScale(600))
                headerFrame = CreateHeaderFrame(mainFrame)
                dungeonHolderFrame = CreateDungeonHelper(mainFrame, headerFrame)
                summaryFrame = CreateSummary(mainFrame, dungeonHolderFrame, headerFrame:GetWidth())
                mainFrame.summaryFrame = summaryFrame
                mainFrame.dungeonHolderFrame = dungeonHolderFrame
                CreateFooter(dungeonHolderFrame, mainFrame, headerFrame)
                print(MplusGainsSettings.Count)
            end
        end
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