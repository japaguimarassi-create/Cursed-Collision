local Guardians = {}

local entries = {
    Meadow = {
        Id = "GuardianHen", Name = "Galinha Guardiã", Biome = "Meadow",
        GuardianType = "Chicken", Shape = "Bird", Rarity = "Lendário",
        Weight = 34, Income = 0,
        Color = Color3.fromRGB(238, 190, 112), Accent = Color3.fromRGB(225, 64, 48),
    },
    Lake = {
        Id = "GuardianSwan", Name = "Cisne Real", Biome = "Lake",
        GuardianType = "Swan", Shape = "Bird", Rarity = "Lendário",
        Weight = 38, Income = 0,
        Color = Color3.fromRGB(238, 249, 255), Accent = Color3.fromRGB(78, 169, 238),
    },
    Forest = {
        Id = "GuardianScorpion", Name = "Escorpião das Dunas", Biome = "Forest",
        GuardianType = "Scorpion", Shape = "Mammal", Rarity = "Lendário",
        Weight = 48, Income = 0,
        Color = Color3.fromRGB(223, 137, 44), Accent = Color3.fromRGB(255, 203, 79),
    },
    Wetlands = {
        Id = "GuardianTiger", Name = "Tigre Guardião", Biome = "Wetlands",
        GuardianType = "Tiger", Shape = "Mammal", Rarity = "Mítico",
        Weight = 52, Income = 0,
        Color = Color3.fromRGB(239, 125, 34), Accent = Color3.fromRGB(38, 34, 31),
    },
    Frost = {
        Id = "GuardianYeti", Name = "Yeti Glacial", Biome = "Frost",
        GuardianType = "Yeti", Shape = "Bear", Rarity = "Mítico",
        Weight = 62, Income = 0,
        Color = Color3.fromRGB(225, 244, 255), Accent = Color3.fromRGB(93, 176, 255),
    },
    Volcano = {
        Id = "GuardianHellhound", Name = "Cão Infernal", Biome = "Volcano",
        GuardianType = "Hellhound", Shape = "Wolf", Rarity = "Mítico",
        Weight = 68, Income = 0,
        Color = Color3.fromRGB(49, 41, 59), Accent = Color3.fromRGB(255, 86, 27),
    },
    Ocean = {
        Id = "GuardianWhale", Name = "Baleia Abissal", Biome = "Ocean",
        GuardianType = "Whale", Shape = "Whale", Rarity = "Secreto",
        Weight = 90, Income = 0,
        Color = Color3.fromRGB(29, 89, 183), Accent = Color3.fromRGB(79, 226, 255),
    },
    Savanna = {
        Id = "GuardianTyrannosaur", Name = "Tiranossauro Ancestral", Biome = "Savanna",
        GuardianType = "Tyrannosaur", Shape = "Mammal", Rarity = "Secreto",
        Weight = 100, Income = 0,
        Color = Color3.fromRGB(133, 91, 55), Accent = Color3.fromRGB(206, 188, 133),
    },
}

for biomeId, entry in pairs(entries) do
    entries[biomeId] = table.freeze(entry)
end

function Guardians.Get(biomeId)
    return entries[biomeId]
end

function Guardians.All()
    local result = {}
    for _, entry in ipairs({
        entries.Meadow, entries.Lake, entries.Forest, entries.Wetlands,
        entries.Frost, entries.Volcano, entries.Ocean, entries.Savanna,
    }) do
        table.insert(result, entry)
    end
    return result
end

return table.freeze(Guardians)
