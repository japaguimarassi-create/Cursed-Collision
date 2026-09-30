--!strict

return function()
    local CombatRules = require("../../src/CollisionBattlestar/ReplicatedStorage/Shared/CombatRules")

    assert(CombatRules.canAttack(10, 9.61, 0.38) == true)
    assert(CombatRules.canAttack(10, 9.7, 0.38) == false)

    assert(CombatRules.nextCombo(1, 1.1, 0.8) == 1)
    assert(CombatRules.nextCombo(1, 0.5, 0.8) == 2)
    assert(CombatRules.nextCombo(3, 0.5, 0.8) == 1)

    assert(CombatRules.canDash(10, 9.1, 0.9) == true)
    assert(CombatRules.canDash(10, 9.2, 0.9) == false)
    assert(CombatRules.normalizeDirection(0, 0).z == 1)
end