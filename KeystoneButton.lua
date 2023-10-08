local _, addon = ...

--[[
    CreateKeystoneButton - Creates a new keystone button object.
    @param level - keystone level for the button.
    @param button - button the object represents.
    @return keystoneButton - created keystone button object
--]]
function addon:CreateKeystoneButton(level, button)
    local keystoneButton = {}
    keystoneButton.level = level
    keystoneButton.mouseDown = false
    keystoneButton.button = button
    return keystoneButton
end