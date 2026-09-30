--!strict

return function()
    local HUDContract = require("../../src/CollisionBattlestar/ReplicatedStorage/Shared/HUDContract")

    local required = {
        "Health",
        "Credits",
        "Wave",
        "Enemies",
        "Elite",
        "Phase",
        "M1",
        "Dash",
        "Menu",
        "Shop",
        "Companion",
        "Notifications",
    }

    for _, name in ipairs(required) do
        assert(HUDContract.required(name))
    end

    assert(HUDContract.count() == #required)
    assert(not HUDContract.required("LegacyPing"))
end
