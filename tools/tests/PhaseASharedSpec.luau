--!strict

return function()
    local Constants = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/Constants")
    local Definitions = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/Definitions")
    local Identity = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/GameIdentity")

    assert(Identity.ProductName == "Collision Battlestar")
    assert(Identity.Subtitle == "Where Worlds Collide")
    assert(Constants.ComboSteps == 3)
    assert(Constants.DashDistance > 0)
    assert(Constants.HitboxWidth > 0)
    assert(Constants.HitboxHeight > 0)
    assert(Constants.HitboxDepth > 0)

    local wave = Definitions.BuildWave(1)
    assert(wave.Number == 1)
    assert(wave.Elite == 1)
    assert(wave.Total == wave.Grunt + wave.Brute + wave.Stalker + wave.Elite)

    local lateWave = Definitions.BuildWave(25)
    assert(lateWave.Elite == 1)
    assert(lateWave.Total <= Constants.MaxActiveEnemies)
    assert(Definitions.Enemies.Elite.IsElite == true)
    assert(Definitions.Enemies.Elite.Tier > Definitions.Enemies.Stalker.Tier)
    assert(Definitions.Enemies.Elite.MaxHealth > Definitions.Enemies.Stalker.MaxHealth)
end
