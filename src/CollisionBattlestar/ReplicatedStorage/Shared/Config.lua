--!strict

local GamePassIds = require(script.Parent:WaitForChild("GamePassIds"))

return {
    BuildVersion = "pve-2.0.0",
    UniverseId = 5290480963,
    PlaceId = 15338267657,
    GameMode = "PvE",

    World = {
        Seed = 260926,
        Size = 1000,
        BlockSize = 84,
        RoadWidth = 28,
    },

    Combat = {
        M1 = {
            Cooldown = 0.34,
            BaseDamage = 12,
            Range = 7,
            BoxSize = Vector3.new(6, 5, 8),
        },
        Dash = {
            Cooldown = 1.25,
            Distance = 16,
        },
    },

    Waves = {
        Intermission = 8,
        FirstWaveEnemies = 4,
        EnemyGrowth = 2,
        EliteEveryWave = true,
        CompletionReward = 30,
        MaxAliveEnemies = 30,
    },

    Enemies = {
        Tier1 = {
            Health = 60,
            Speed = 11,
            Damage = 7,
            AttackRange = 5,
            AttackCooldown = 1.1,
            Reward = 10,
        },
        Tier2 = {
            Health = 110,
            Speed = 12,
            Damage = 10,
            AttackRange = 5.5,
            AttackCooldown = 1.0,
            Reward = 16,
        },
        Tier3 = {
            Health = 180,
            Speed = 13,
            Damage = 14,
            AttackRange = 6,
            AttackCooldown = 0.9,
            Reward = 24,
        },
        Elite = {
            HealthMultiplier = 3.25,
            SpeedMultiplier = 1.08,
            DamageMultiplier = 1.8,
            RewardMultiplier = 4,
        },
    },

    Shop = {
        Damage = {
            BaseCost = 50,
            Growth = 1.65,
            MaxLevel = 25,
        },
        Defense = {
            BaseCost = 75,
            Growth = 1.7,
            MaxLevel = 25,
        },
        Speed = {
            BaseCost = 100,
            Growth = 1.8,
            MaxLevel = 12,
        },
        Companions = {
            {
                Key = "Scout",
                DisplayName = "Scout",
                Cost = 250,
                Damage = 14,
                Health = 90,
                Speed = 15,
                AttackRange = 22,
                AttackCooldown = 1.1,
            },
            {
                Key = "Brute",
                DisplayName = "Brute",
                Cost = 900,
                Damage = 35,
                Health = 240,
                Speed = 12,
                AttackRange = 8,
                AttackCooldown = 0.75,
            },
            {
                Key = "Ranger",
                DisplayName = "Ranger",
                Cost = 2400,
                Damage = 65,
                Health = 180,
                Speed = 16,
                AttackRange = 30,
                AttackCooldown = 0.55,
            },
            {
                Key = "Titan",
                DisplayName = "Titan",
                Cost = 7000,
                Damage = 120,
                Health = 650,
                Speed = 10,
                AttackRange = 9,
                AttackCooldown = 0.65,
            },
        },
    },

    GamePasses = {
        {
            Key = "EliteBonus",
            Name = "Elite Hunter",
            Id = GamePassIds.EliteBonus,
            Description = "Dobra as recompensas recebidas de inimigos Elite.",
        },
        {
            Key = "SecondCompanion",
            Name = "Companion Slot+",
            Id = GamePassIds.SecondCompanion,
            Description = "Permite equipar dois NPCs aliados.",
        },
        {
            Key = "ShopDiscount",
            Name = "Arsenal VIP",
            Id = GamePassIds.ShopDiscount,
            Description = "Reduz permanentemente os preços da loja em 15%.",
        },
        {
            Key = "VIP",
            Name = "VIP",
            Id = GamePassIds.VIP,
            Description = "Bônus permanente de recompensas e cosméticos VIP.",
        },
        {
            Key = "ExtraWaveReward",
            Name = "Wave Master",
            Id = GamePassIds.ExtraWaveReward,
            Description = "Aumenta em 25% a recompensa de conclusão das ondas.",
        },
        {
            Key = "StarterCompanion",
            Name = "Companion Prime",
            Id = GamePassIds.StarterCompanion,
            Description = "Desbloqueia imediatamente o uso do Scout.",
        },
    },

    UI = {
        Surface = Color3.fromRGB(12, 14, 20),
        Surface2 = Color3.fromRGB(24, 28, 38),
        Stroke = Color3.fromRGB(70, 78, 96),
        Text = Color3.fromRGB(242, 245, 250),
        Muted = Color3.fromRGB(158, 167, 182),
        Good = Color3.fromRGB(110, 225, 170),
        Danger = Color3.fromRGB(255, 70, 78),
        Warning = Color3.fromRGB(255, 194, 90),
    },
}
