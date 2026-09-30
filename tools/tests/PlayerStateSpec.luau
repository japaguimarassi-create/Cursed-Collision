--!strict

return function()
    local PlayerState = require("../../src/CollisionBattlestar/ReplicatedStorage/Shared/PlayerState")

    local state = PlayerState.new()
    assert(state.Credits == 0)
    assert(state.DamageLevel == 0)
    assert(state.Wave == 0)
    assert(state.DataReady == false)

    PlayerState.setReady(state, true)
    PlayerState.addCredits(state, 25)
    PlayerState.addDamageLevel(state)

    assert(state.DataReady == true)
    assert(state.Credits == 25)
    assert(state.DamageLevel == 1)
end
