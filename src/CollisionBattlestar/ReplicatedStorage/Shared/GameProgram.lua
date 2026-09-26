--!strict

local DSL = require(script.Parent:WaitForChild("GameDSL"))
local GamePassIds = require(script.Parent:WaitForChild("GamePassIds"))

local game = DSL.game("Collision Battlestar")

game:identity("pve-4.0.0", 5290480963, 15338267657, "PvE")

game:meta({
    Authoring = "Collision Script",
    Syntax = "Luau-embedded DSL",
    Runtime = "Server authoritative",
})

game:world({
    Seed = 260926,
    Size = 1200,
    BlockSize = 96,
    RoadWidth = 32,
})

game:combat({
    M1 = {Cooldown = 0.34, BaseDamage = 12, Range = 7, BoxSize = Vector3.new(6, 5, 8)},
    Dash = {Cooldown = 1.25, Distance = 16},
})

game:waves({
    Intermission = 8,
    FirstWaveEnemies = 12,
    EnemyGrowth = 2,
    EliteEveryWave = true,
    CompletionReward = 30,
    MaxAliveEnemies = 28,
})

game:enemy("Tier1", {Health = 60, Speed = 11, Damage = 7, AttackRange = 5, AttackCooldown = 1.1, Reward = 10})
game:enemy("Tier2", {Health = 110, Speed = 12, Damage = 10, AttackRange = 5.5, AttackCooldown = 1.0, Reward = 16})
game:enemy("Tier3", {Health = 180, Speed = 13, Damage = 14, AttackRange = 6, AttackCooldown = 0.9, Reward = 24})
game:enemy("Elite", {HealthMultiplier = 3.25, SpeedMultiplier = 1.08, DamageMultiplier = 1.8, RewardMultiplier = 4})

game:ai("Enemy", {
    ThinkInterval = 0.1,
    RetargetDistance = 115,
    CrowdPenalty = 9,
    KillerBias = 42,
    LowHealthBias = 7,
    DirectChaseDistance = 34,
    RepathInterval = 0.72,
    SeparationRadius = 8,
    StuckTimeout = 1.35,
    EliteDodgeMin = 7,
    EliteDodgeMax = 15,
    EliteDodgeCooldownMin = 3,
    EliteDodgeCooldownMax = 5,
    AttackWindup = 0.16,
    AgentRadius = 2,
    AgentHeight = 5,
    WaypointSpacing = 3.5,
})

game:ai("Companion", {
    ThinkInterval = 0.14,
    RepathInterval = 0.8,
    FollowDistance = 7,
    FormationDistance = 5,
    StrafeDistance = 2.5,
    AgentRadius = 2,
    AgentHeight = 5,
    WaypointSpacing = 3.5,
    AttackWindup = 0.12,
})

game:assets({
    Hair = {MessyBlack = 8022080793, AnimeBlack = 14892977317, ShortBlack = 6346833550, SpikyBlack = 99947960733959},
    Monster = {BlackLongHorns = 13343410419, RedStripedHorns = 13472644423, FlamingDemonHorns = 6130258595},
    Animations = {Idle = 507766666, Walk = 507777826, Run = 507767714, Jump = 507765000, Fall = 507767968, Attack = 2515090838},
})

game:shop({
    Damage = {BaseCost = 50, Growth = 1.65, MaxLevel = 25},
    Defense = {BaseCost = 75, Growth = 1.7, MaxLevel = 25},
    Speed = {BaseCost = 100, Growth = 1.8, MaxLevel = 12},
    Companions = {
        {Key = "Scout", DisplayName = "Scout", Cost = 250, Damage = 14, Health = 90, Speed = 15, AttackRange = 22, AttackCooldown = 1.1},
        {Key = "Brute", DisplayName = "Brute", Cost = 900, Damage = 35, Health = 240, Speed = 12, AttackRange = 8, AttackCooldown = 0.75},
        {Key = "Ranger", DisplayName = "Ranger", Cost = 2400, Damage = 65, Health = 180, Speed = 16, AttackRange = 30, AttackCooldown = 0.55},
        {Key = "Titan", DisplayName = "Titan", Cost = 7000, Damage = 120, Health = 650, Speed = 10, AttackRange = 9, AttackCooldown = 0.65},
    },
})

game:passes({
    {Key = "EliteBonus", Name = "Elite Hunter", Id = GamePassIds.EliteBonus, Description = "Dobra as recompensas recebidas de inimigos Elite."},
    {Key = "SecondCompanion", Name = "Companion Slot+", Id = GamePassIds.SecondCompanion, Description = "Permite equipar dois NPCs aliados."},
    {Key = "ShopDiscount", Name = "Arsenal VIP", Id = GamePassIds.ShopDiscount, Description = "Reduz permanentemente os preços da loja em 15%."},
    {Key = "VIP", Name = "VIP", Id = GamePassIds.VIP, Description = "Bônus permanente de recompensas e cosméticos VIP."},
    {Key = "ExtraWaveReward", Name = "Wave Master", Id = GamePassIds.ExtraWaveReward, Description = "Aumenta em 25% a recompensa de conclusão das ondas."},
    {Key = "StarterCompanion", Name = "Companion Prime", Id = GamePassIds.StarterCompanion, Description = "Desbloqueia imediatamente o uso do Scout."},
})

game:ui({
    Background = Color3.fromRGB(7, 9, 14),
    Surface = Color3.fromRGB(13, 16, 24),
    Surface2 = Color3.fromRGB(22, 27, 39),
    Surface3 = Color3.fromRGB(31, 38, 54),
    Stroke = Color3.fromRGB(72, 82, 103),
    Text = Color3.fromRGB(245, 247, 252),
    Muted = Color3.fromRGB(151, 162, 181),
    Subtle = Color3.fromRGB(108, 118, 137),
    Good = Color3.fromRGB(106, 235, 163),
    Danger = Color3.fromRGB(255, 82, 93),
    Warning = Color3.fromRGB(255, 195, 88),
    Accent = Color3.fromRGB(116, 145, 255),
    Accent2 = Color3.fromRGB(186, 115, 255),
    Info = Color3.fromRGB(90, 190, 255),
    Shadow = Color3.fromRGB(0, 0, 0),
})

return game:compile()
