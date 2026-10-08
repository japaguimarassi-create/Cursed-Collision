--!strict

local Companions = {
    Vanguard = {
        Id = "Vanguard",
        Damage = 20,
        AttackCooldown = 0.9,
        AttackRange = 5,
        PreferredDistance = 4,
        Speed = 13,
    },
    Striker = {
        Id = "Striker",
        Damage = 26,
        AttackCooldown = 1.1,
        AttackRange = 9,
        PreferredDistance = 8,
        Speed = 12,
    },
    Guardian = {
        Id = "Guardian",
        Damage = 16,
        AttackCooldown = 1,
        AttackRange = 5.5,
        PreferredDistance = 5,
        Speed = 11,
    },
    Support = {
        Id = "Support",
        Damage = 12,
        AttackCooldown = 1.2,
        AttackRange = 8,
        PreferredDistance = 9,
        Speed = 11,
        HealAmount = 8,
        HealCooldown = 4,
        HealRange = 18,
    },
}

return table.freeze(Companions)
