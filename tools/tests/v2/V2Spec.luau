--!strict

local Constants = require("../../../src/CollisionBattlestarV2/ReplicatedStorage/Shared/Constants")
local Rules = require("../../../src/CollisionBattlestarV2/ReplicatedStorage/Shared/Rules")
local Data = require("../../../src/CollisionBattlestarV2/ReplicatedStorage/Shared/Data")
local Missions = require("../../../src/CollisionBattlestarV2/ReplicatedStorage/Shared/MissionDefinitions")
local Enemies = require("../../../src/CollisionBattlestarV2/ReplicatedStorage/Shared/EnemyDefinitions")

assert(Constants.MaxNPCs == 16)
assert(Constants.AttackCooldown > 0)
assert(Constants.AttackRange > 0)
assert(Constants.DashDistance > 0)

assert(Rules.combo(0, 0) == 1)
assert(Rules.combo(1, 0.2) == 2)
assert(Rules.combo(2, 0.2) == 3)
assert(Rules.combo(3, 0.2) == 1)
assert(Rules.combo(3, 2) == 1)

assert(Rules.levelForScore(0) == 1)
assert(Rules.levelForScore(Rules.scoreForLevel(2)) == 2)
assert(Rules.levelForScore(Rules.scoreForLevel(10)) == 10)

local _, progress, required = Rules.levelProgress(1000)
assert(progress >= 0)
assert(required > 0)

for wave = 1, 100 do
    local profile = Rules.waveProfile(wave)
    assert(profile.Total <= 15)
end

local low = Rules.aiProfile(0)
local high = Rules.aiProfile(50)
assert(high.Skill > low.Skill)
assert(high.ThinkInterval < low.ThinkInterval)
assert(high.Prediction > low.Prediction)

local clean = Data.sanitize({
    Credits = 500,
    Score = 1000,
    Kills = 2,
    Waves = 4,
    Upgrades = {Damage = 2, Health = 1, Dash = 3},
})
assert(clean.Credits == 500)
assert(clean.Score == 1000)
assert(clean.Upgrades.Dash == 3)

assert(Missions.Bosses.Goal == 3)
assert(Enemies.Boss.Boss == true)

print("PASS Collision Battlestar V2 pure rules")
