--!strict

return {
    Identity = {
        ProductName = "Collision Battlestar",
        Subtitle = "Where Worlds Collide",
        Version = "foundation-1.0.0",
        Mode = "PvE",
    },
    Combat = {
        PlayerMaxHealth = 100,
        M1 = {
            Damages = {25, 30, 35},
            ComboWindow = 0.8,
            MinInterval = 0.38,
            Range = 8,
            BoxSize = Vector3.new(7, 5, 8),
            Knockback = 28,
            FinisherKnockback = 56,
        },
        Dash = {
            Cooldown = 0.9,
            Speed = 70,
            Duration = 0.12,
            Distance = 8.4,
        },
    },
    Waves = {
        BaseCount = 6,
        CountStep = 2,
        MaxCount = 20,
        Intermission = 5,
        SpawnDelay = 0.12,
        WaveRewardMultiplier = 25,
    },
    Enemies = {
        Tier1 = {MaxHealth = 60, Damage = 8, Credits = 5, WalkSpeed = 8, AttackRange = 4.2, AttackCooldown = 1.1},
        Tier2 = {MaxHealth = 110, Damage = 12, Credits = 8, WalkSpeed = 7.5, AttackRange = 4.4, AttackCooldown = 1.2},
        Tier3 = {MaxHealth = 180, Damage = 18, Credits = 12, WalkSpeed = 7, AttackRange = 4.6, AttackCooldown = 1.3},
        Elite = {MaxHealth = 350, Damage = 28, Credits = 30, WalkSpeed = 6.5, AttackRange = 4.8, AttackCooldown = 1.45},
    },
    Economy = {
        UpgradeDamagePerLevel = 5,
        UpgradeInitialCost = 50,
        UpgradeCostMultiplier = 2,
    },
    AI = {Tick = 0.1, PathRecompute = 0.5},
    FX = {MaxInstances = 24},
}