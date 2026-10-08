--!strict

return function()
    local Rules = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/PvPRules")

    assert(Rules.canJoin(false) == true)
    assert(Rules.canJoin(true) == false)
    assert(Rules.canLeave(true) == true)
    assert(Rules.canLeave(false) == false)
    assert(Rules.canDamage(10, 20) == true)
    assert(Rules.canDamage(10, 10) == false)
    assert(Rules.canDamage(-1, 10) == false)
end
