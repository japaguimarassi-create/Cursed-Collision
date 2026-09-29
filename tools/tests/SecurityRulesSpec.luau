--!strict

return function()
    local SecurityRules = require("../../src/CollisionBattlestar/ReplicatedStorage/Shared/SecurityRules")

    assert(SecurityRules.validAction("M1") == true)
    assert(SecurityRules.validAction("Dash") == true)
    assert(SecurityRules.validAction("GiveCredits") == false)

    assert(SecurityRules.validTarget("Enemy", false) == true)
    assert(SecurityRules.validTarget("Player", true) == true)
    assert(SecurityRules.validTarget("Player", false) == false)

    assert(SecurityRules.validRange(7.9, 8) == true)
    assert(SecurityRules.validRange(8.1, 8) == false)
end
