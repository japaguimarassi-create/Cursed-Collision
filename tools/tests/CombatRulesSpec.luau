--!strict

return function()
    local CombatRules = require("../../src/CollisionBattlestar/ReplicatedStorage/Shared/CombatRules")
    local Constants = require("../../src/CollisionBattlestar/ReplicatedStorage/Shared/Constants")

    assert(CombatRules.canAttack(10, 9.61, Constants.Combat.M1.MinInterval) == true)
    assert(CombatRules.canAttack(10, 9.7, Constants.Combat.M1.MinInterval) == false)

    assert(CombatRules.nextCombo(1, 1.1, Constants.Combat.M1.ComboWindow) == 1)
    assert(CombatRules.nextCombo(1, 0.5, Constants.Combat.M1.ComboWindow) == 2)
    assert(CombatRules.nextCombo(3, 0.5, Constants.Combat.M1.ComboWindow) == 1)

    assert(CombatRules.canDash(10, 9.1, Constants.Combat.Dash.Cooldown) == true)
    assert(CombatRules.canDash(10, 9.2, Constants.Combat.Dash.Cooldown) == false)
    assert(CombatRules.normalizeDirection(0, 0).z == 1)
end