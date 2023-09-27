local _, addon = ...

function addon.CreateKeystoneButton(level, onTimeScore, button, index)
    local keystoneButton = {}
    keystoneButton.level = level
    keystoneButton.onTimeScore = onTimeScore
    keystoneButton.mouseDown = false
    keystoneButton.button = button
    keystoneButton.index = index
    return keystoneButton
end