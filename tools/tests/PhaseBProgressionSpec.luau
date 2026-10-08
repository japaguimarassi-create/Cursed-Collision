--!strict

return function()
    local Rules = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/ProgressionRules")

    assert(Rules.isValidUpgrade("Damage") == true)
    assert(Rules.isValidUpgrade("Critical") == true)
    assert(Rules.isValidUpgrade("Unknown") == false)
    assert(Rules.getCost("Damage", 0) == 75)
    assert(Rules.getCost("Damage", 1) > 75)
    assert(Rules.getCost("Damage", 25) == math.huge)
    assert(Rules.getMaxLevel("Recovery") == 15)

    assert(Rules.damageMultiplier(0) == 1)
    assert(Rules.damageMultiplier(4) == 1.2)
    assert(Rules.maxHealthBonus(3) == 45)
    assert(Rules.criticalChance(5) == 0.1)
    assert(Rules.recoveryBonus(6) == 3)
    assert(Rules.dashCooldownMultiplier(5) == 0.8)
end
