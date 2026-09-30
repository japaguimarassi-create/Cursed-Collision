--!strict

return function()
    local WaveRules = require("../../src/CollisionBattlestar/ReplicatedStorage/Shared/WaveRules")

    assert(WaveRules.enemyCount(1) == 6)
    assert(WaveRules.enemyCount(2) == 8)
    assert(WaveRules.enemyCount(8) == 20)
    assert(WaveRules.enemyCount(40) == 20)
    assert(WaveRules.hasElite(1) == true)
    assert(WaveRules.hasElite(0) == false)
    assert(WaveRules.waveReward(4) == 100)
end
