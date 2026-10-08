--!strict

return function()
    local LevelRules = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/LevelRules")
    local Config = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/Config")

    assert(LevelRules.levelForScore(0) == 1)
    assert(LevelRules.scoreForLevel(1) == 0)
    assert(LevelRules.levelForScore(LevelRules.scoreForLevel(2)) == 2)
    assert(LevelRules.levelForScore(LevelRules.scoreForLevel(5)) == 5)

    local progress = LevelRules.progress(1000)
    assert(progress.Level >= 2)
    assert(progress.Required > 0)
    assert(progress.Current >= 0)

    assert(Config.Waves.MaxActiveEnemies == 16)
    assert(Config.AI.MaxActiveEnemies == 16)
    assert(Config.AI.MinThinkInterval < Config.AI.BaseThinkInterval)
    assert(Config.Runtime.RecoveryCooldown > 0)
end
