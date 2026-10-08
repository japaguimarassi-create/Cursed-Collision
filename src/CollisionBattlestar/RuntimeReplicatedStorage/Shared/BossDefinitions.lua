--!strict

local Bosses = {
    RiftTitan = {
        Id = "RiftTitan",
        DisplayName = "Rift Titan",
        TriggerEvery = 10,
        HealthMultiplier = 2.5,
        DamageMultiplier = 1.35,
        SpeedMultiplier = 0.9,
        RewardMultiplier = 2,
    },
    CollisionWarden = {
        Id = "CollisionWarden",
        DisplayName = "Collision Warden",
        TriggerEvery = 20,
        HealthMultiplier = 3.2,
        DamageMultiplier = 1.55,
        SpeedMultiplier = 0.82,
        RewardMultiplier = 2.5,
    },
}

return table.freeze(Bosses)
