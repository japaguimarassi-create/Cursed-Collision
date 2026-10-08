--!strict

local Events = {
    RiftSurge = {
        Id = "RiftSurge",
        DisplayName = "Rift Surge",
        SpeedMultiplier = 1.15,
        DamageMultiplier = 1,
        RewardMultiplier = 1.25,
    },
    Overdrive = {
        Id = "Overdrive",
        DisplayName = "Overdrive",
        SpeedMultiplier = 1.1,
        DamageMultiplier = 1.2,
        RewardMultiplier = 1.4,
    },
    CreditRush = {
        Id = "CreditRush",
        DisplayName = "Credit Rush",
        SpeedMultiplier = 1,
        DamageMultiplier = 1,
        RewardMultiplier = 2,
    },
}

return table.freeze(Events)
