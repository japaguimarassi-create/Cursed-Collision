--!strict

local Constants = require(script.Parent.Constants)

local Config = {
    Arena = {
        Radius = Constants.ArenaRadius,
        SpawnRadius = Constants.EnemySpawnRadius,
        SafeSpawnRadius = Constants.SafeSpawnRadius,
    },
    Player = {
        BaseHealth = Constants.BaseHealth,
        BaseWalkSpeed = Constants.BaseWalkSpeed,
    },
    Combat = {
        MaxAttackDistance = Constants.MaxAttackDistance,
        MaxAttackAngle = Constants.MaxAttackAngle,
        AttackCooldown = Constants.AttackCooldown,
        ComboResetWindow = Constants.ComboResetWindow,
        ComboSteps = Constants.ComboSteps,
        HitboxSize = Constants.HitboxSize,
        KnockbackBase = Constants.KnockbackBase,
        KnockbackVertical = Constants.KnockbackVertical,
        DashCooldown = Constants.DashCooldown,
        DashDistance = Constants.DashDistance,
        DashDuration = Constants.DashDuration,
        DashVerticalLimit = Constants.DashVerticalLimit,
    },
    Economy = {
        BaseCredits = Constants.BaseCredits,
        WaveClearReward = Constants.WaveClearReward,
        UpgradeBaseCost = Constants.UpgradeBaseCost,
        UpgradeCostGrowth = Constants.UpgradeCostGrowth,
    },
    Waves = {
        Intermission = Constants.WaveIntermission,
        MaxActiveEnemies = Constants.MaxActiveEnemies,
    },
}

return table.freeze({
    Arena = table.freeze(Config.Arena),
    Player = table.freeze(Config.Player),
    Combat = table.freeze(Config.Combat),
    Economy = table.freeze(Config.Economy),
    Waves = table.freeze(Config.Waves),
})
