local _, addon = ...

--[[
    CreateKeystoneButton - Creates a new keystone button object.
    @param level - keystone level for the button.
    @param button - button the object represents.
    @param index - index of the button in its respective rows button table.
    @return keystoneButton - created keystone button object
--]]
function addon:CreateKeystoneButton(level, button, index)
    local keystoneButton = {}
    keystoneButton.level = level
    keystoneButton.mouseDown = false
    keystoneButton.button = button
    keystoneButton.index = index
    return keystoneButton
end