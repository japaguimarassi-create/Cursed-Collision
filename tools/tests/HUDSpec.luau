--!strict

return function()
    local HUDContract = require("../../src/CollisionBattlestar/ReplicatedStorage/Shared/HUDContract")

    assert(HUDContract.required("Health"))
    assert(HUDContract.required("Credits"))
    assert(HUDContract.required("Wave"))
    assert(HUDContract.required("Enemies"))
    assert(HUDContract.required("Elite"))
    assert(HUDContract.required("M1"))
    assert(HUDContract.required("Dash"))
    assert(HUDContract.required("Menu"))
    assert(HUDContract.count() == 8)
end
