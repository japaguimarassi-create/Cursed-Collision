--!strict

return function()
    local BossDefinitions = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/BossDefinitions")
    local BossRules = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/BossRules")
    local EventDefinitions = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/WaveEventDefinitions")
    local EventRules = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/WaveEventRules")

    assert(BossRules.getForWave(9, BossDefinitions) == nil)
    assert(BossRules.getForWave(10, BossDefinitions).Id == "RiftTitan")
    assert(BossRules.getForWave(20, BossDefinitions).Id == "CollisionWarden")
    assert(BossRules.scale(100, 2.5) == 250)

    assert(EventRules.pick(4, false) == nil)
    assert(EventRules.pick(5, false) == "RiftSurge")
    assert(EventRules.pick(15, false) == "CreditRush")
    assert(EventRules.pick(20, true) == nil)
    assert(EventDefinitions.Overdrive.SpeedMultiplier > 1)
    assert(EventDefinitions.CreditRush.RewardMultiplier == 2)
end
