--!strict

return function()
    local Rules = require("../../src/CollisionBattlestar/ReplicatedStorage/Shared/HUDLayoutRules")

    local mobile = Rules.get(390, 844, true)
    assert(mobile.UseCustomControls == true)

    local desktop = Rules.get(1920, 1080, false)
    assert(desktop.UseCustomControls == false)

    assert(mobile.SafeInsetMode == "CoreUISafeInsets")
    assert(desktop.SafeInsetMode == "CoreUISafeInsets")
end
