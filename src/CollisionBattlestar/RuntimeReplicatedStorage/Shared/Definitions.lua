--!strict

local Constants = require(script.Parent.Constants)

local Enemies = table.freeze({
    Grunt = table.freeze({
        Id = "Grunt",
        DisplayName = "Riftling",
        Tier = 1,
        MaxHealth = 40,
        Damage = 8,
        Speed = 11,
        AttackRange = 5,
        AttackCooldown = 1.2,
        Reward = 10,
        KnockbackResistance = 0,
        IsElite = false,
    }),
    Brute = table.freeze({
        Id = "Brute",
        DisplayName = "Breaker",
        Tier = 2,
        MaxHealth = 90,
        Damage = 14,
        Speed = 8,
        AttackRange = 6,
        AttackCooldown = 1.5,
        Reward = 20,
        KnockbackResistance = 0.35,
        IsElite = false,
    }),
    Stalker = table.freeze({
        Id = "Stalker",
        DisplayName = "Stalker",
        Tier = 3,
        MaxHealth = 135,
        Damage = 20,
        Speed = 14,
        AttackRange = 5,
        AttackCooldown = 1,
        Reward = 30,
        KnockbackResistance = 0.55,
        IsElite = false,
    }),
    Elite = table.freeze({
        Id = "Elite",
        DisplayName = "Collision Elite",
        Tier = 4,
        MaxHealth = 420,
        Damage = 28,
        Speed = 9,
        AttackRange = 7,
        AttackCooldown = 1.25,
        Reward = 120,
        KnockbackResistance = 0.8,
        IsElite = true,
    }),
})

local WaveProfiles = {
    [1] = {grunt = 4, brute = 0, stalker = 0},
    [2] = {grunt = 5, brute = 1, stalker = 0},
    [3] = {grunt = 6, brute = 2, stalker = 0},
    [4] = {grunt = 6, brute = 2, stalker = 1},
    [5] = {grunt = 7, brute = 3, stalker = 1},
}

local function capWave(grunt: number, brute: number, stalker: number)
    local maxNonElite = math.max(0, Constants.MaxActiveEnemies - 1)
    local overflow = math.max(0, grunt + brute + stalker - maxNonElite)

    local reduce = math.min(overflow, grunt)
    grunt -= reduce
    overflow -= reduce

    reduce = math.min(overflow, brute)
    brute -= reduce
    overflow -= reduce

    reduce = math.min(overflow, stalker)
    stalker -= reduce

    return grunt, brute, stalker
end

local function buildWave(wave: number)
    local safeWave = math.max(1, math.floor(wave))
    local profile = WaveProfiles[safeWave]

    if not profile then
        profile = {
            grunt = math.min(10 + math.floor(safeWave * 0.7), 14),
            brute = math.min(math.floor(safeWave * 0.55), 6),
            stalker = math.min(math.floor(math.max(0, safeWave - 2) * 0.45), 5),
        }
    end

    local grunt, brute, stalker = capWave(profile.grunt, profile.brute, profile.stalker)

    return table.freeze({
        Number = safeWave,
        Grunt = grunt,
        Brute = brute,
        Stalker = stalker,
        Elite = 1,
        Total = grunt + brute + stalker + 1,
    })
end

return table.freeze({
    Enemies = Enemies,
    BuildWave = buildWave,
})
