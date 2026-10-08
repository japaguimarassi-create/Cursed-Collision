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
        HitboxSize = Vector3.new(Constants.HitboxWidth, Constants.HitboxHeight, Constants.HitboxDepth),
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
    Runtime = {
        HealthCheckInterval = 3,
        RecoveryCooldown = 4,
        MaxRecoveryFailures = 3,
    },
    AI = {
        MaxActiveEnemies = Constants.MaxActiveEnemies,
        SchedulerInterval = 0.08,
        TargetRefreshInterval = 0.35,
        MaxNpcErrors = 3,
        BaseSkill = 0.25,
        SkillPerWave = 0.018,
        MaxSkill = 0.82,
        BaseThinkInterval = 0.28,
        MinThinkInterval = 0.16,
        ThinkImprovementPerWave = 0.0025,
        BasePredictionTime = 0.05,
        PredictionPerWave = 0.004,
        MaxPredictionTime = 0.35,
    },
}

return table.freeze({
    Arena = table.freeze(Config.Arena),
    Player = table.freeze(Config.Player),
    Combat = table.freeze(Config.Combat),
    Economy = table.freeze(Config.Economy),
    Waves = table.freeze(Config.Waves),
    Runtime = table.freeze(Config.Runtime),
    AI = table.freeze(Config.AI),
})
