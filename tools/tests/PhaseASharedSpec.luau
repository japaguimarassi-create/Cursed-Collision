--!strict

return function()
    local Constants = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/Constants")
    local Definitions = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/Definitions")
    local Identity = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/GameIdentity")
    local CombatRules = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/CombatRules")

    assert(Identity.ProductName == "Collision Battlestar")
    assert(Identity.Subtitle == "Where Worlds Collide")
    assert(Constants.ComboSteps == 3)
    assert(Constants.DashDistance > 0)
    assert(Constants.HitboxWidth > 0)
    assert(Constants.HitboxHeight > 0)
    assert(Constants.HitboxDepth > 0)
    assert(CombatRules.nextCombo(0, 5, Constants.ComboResetWindow, Constants.ComboSteps) == 1)
    assert(CombatRules.nextCombo(1, 0.2, Constants.ComboResetWindow, Constants.ComboSteps) == 2)
    assert(CombatRules.nextCombo(2, 0.2, Constants.ComboResetWindow, Constants.ComboSteps) == 3)
    assert(CombatRules.nextCombo(3, 0.2, Constants.ComboResetWindow, Constants.ComboSteps) == 1)
    assert(CombatRules.nextCombo(3, 5, Constants.ComboResetWindow, Constants.ComboSteps) == 1)
    assert(CombatRules.comboMultiplier(1) == 1)
    assert(CombatRules.comboMultiplier(3) > CombatRules.comboMultiplier(2))

    local wave = Definitions.BuildWave(1, Constants.MaxActiveEnemies)
    assert(wave.Number == 1)
    assert(wave.Elite == 1)
    assert(wave.Total == wave.Grunt + wave.Brute + wave.Stalker + wave.Elite)

    local lateWave = Definitions.BuildWave(25, Constants.MaxActiveEnemies)
    assert(lateWave.Elite == 1)
    assert(lateWave.Total <= Constants.MaxActiveEnemies)

    for waveNumber = 1, 100 do
        local generated = Definitions.BuildWave(waveNumber, Constants.MaxActiveEnemies)
        assert(generated.Elite == 1)
        assert(generated.Total <= Constants.MaxActiveEnemies)
        assert(generated.Total == generated.Grunt + generated.Brute + generated.Stalker + generated.Elite)
    end
    assert(Definitions.Enemies.Elite.IsElite == true)
    assert(Definitions.Enemies.Elite.Tier > Definitions.Enemies.Stalker.Tier)
    assert(Definitions.Enemies.Elite.MaxHealth > Definitions.Enemies.Stalker.MaxHealth)
end
