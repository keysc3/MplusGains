local _, addon = ...

function addon.CreateKeystoneButton(level, onTimeScore)
    local keystoneButton = {}
    --local self = setmetatable({}, KeystoneButton)
    keystoneButton.isSelected = false
    keystoneButton.level = level
    keystoneButton.onTimeScore = onTimeScore
    return keystoneButton
end