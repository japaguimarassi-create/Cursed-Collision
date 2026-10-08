--!strict

return function()
    local requiredSignals = {
        "Shop",
        "Companion",
        "Invite",
        "Credits",
        "Wave",
        "Elite",
        "Echo",
    }

    for _, signal in ipairs(requiredSignals) do
        assert(type(signal) == "string" and #signal > 0)
    end
end
