--!strict

local Items = {
    AttackFX_Shock = {
        ItemId = "AttackFX_Shock",
        DisplayName = "Shock Impact",
        Category = "AttackFX",
        Slot = "AttackFX",
        Price = 350,
        Currency = "Credits",
        Active = true,
        Premium = false,
    },
    AttackFX_Burst = {
        ItemId = "AttackFX_Burst",
        DisplayName = "Burst Impact",
        Category = "AttackFX",
        Slot = "AttackFX",
        Price = 700,
        Currency = "Credits",
        Active = true,
        Premium = false,
    },
    PlayerSkin_Street = {
        ItemId = "PlayerSkin_Street",
        DisplayName = "Street Skin",
        Category = "PlayerSkin",
        Slot = "PlayerSkin",
        Price = 500,
        Currency = "Credits",
        Active = true,
        Premium = false,
    },
    EchoCosmetic_Aurora = {
        ItemId = "EchoCosmetic_Aurora",
        DisplayName = "Aurora Echo",
        Category = "EchoCosmetic",
        Slot = "EchoCosmetic",
        Price = 900,
        Currency = "Credits",
        Active = true,
        Premium = false,
    },
    EliteCosmetic_Commander = {
        ItemId = "EliteCosmetic_Commander",
        DisplayName = "Commander Elite",
        Category = "EliteCosmetic",
        Slot = "EliteCosmetic",
        Price = 1200,
        Currency = "Credits",
        Active = true,
        Premium = false,
    },
}

local UpgradeCatalog = {
    {
        ItemId = "Upgrade_Damage",
        DisplayName = "Damage",
        Category = "Upgrade",
        UpgradeId = "Damage",
        Currency = "Credits",
        Active = true,
        Premium = false,
    },
    {
        ItemId = "Upgrade_MaxHealth",
        DisplayName = "Max Health",
        Category = "Upgrade",
        UpgradeId = "MaxHealth",
        Currency = "Credits",
        Active = true,
        Premium = false,
    },
    {
        ItemId = "Upgrade_Dash",
        DisplayName = "Dash",
        Category = "Upgrade",
        UpgradeId = "Dash",
        Currency = "Credits",
        Active = true,
        Premium = false,
    },
    {
        ItemId = "Upgrade_Critical",
        DisplayName = "Critical",
        Category = "Upgrade",
        UpgradeId = "Critical",
        Currency = "Credits",
        Active = true,
        Premium = false,
    },
    {
        ItemId = "Upgrade_Recovery",
        DisplayName = "Recovery",
        Category = "Upgrade",
        UpgradeId = "Recovery",
        Currency = "Credits",
        Active = true,
        Premium = false,
    },
}

for _, item in ipairs(UpgradeCatalog) do
    Items[item.ItemId] = item
end

local Premium = {
    GamePasses = {},
    DeveloperProducts = {},
}

return table.freeze({
    Items = table.freeze(Items),
    Premium = table.freeze(Premium),
})
