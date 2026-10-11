local Catalog = {}

Catalog.RarityMultipliers = table.freeze({
    Common = 1,
    Uncommon = 1.5,
    Rare = 2.5,
    Epic = 5,
    Legendary = 10,
    Mythic = 20,
})

Catalog.Animals = table.freeze({
    Chicken = table.freeze({
        Id = "Chicken",
        DisplayName = "Galinha",
        Biome = "Farm",
        Weight = 2,
        RequiredStrength = 1,
        BaseValue = 25,
        Rarity = "Common",
        RespawnSeconds = 12,
        Color = Color3.fromRGB(247, 224, 150),
        Accent = Color3.fromRGB(218, 81, 71),
        Shape = "Bird",
    }),
    Capybara = table.freeze({
        Id = "Capybara",
        DisplayName = "Capivara",
        Biome = "Farm",
        Weight = 5,
        RequiredStrength = 1,
        BaseValue = 55,
        Rarity = "Common",
        RespawnSeconds = 15,
        Color = Color3.fromRGB(153, 111, 78),
        Accent = Color3.fromRGB(91, 65, 48),
        Shape = "Mammal",
    }),
    Goat = table.freeze({
        Id = "Goat",
        DisplayName = "Cabra",
        Biome = "Farm",
        Weight = 9,
        RequiredStrength = 5,
        BaseValue = 110,
        Rarity = "Uncommon",
        RespawnSeconds = 18,
        Color = Color3.fromRGB(239, 226, 194),
        Accent = Color3.fromRGB(108, 86, 66),
        Shape = "Mammal",
    }),
    Monkey = table.freeze({
        Id = "Monkey",
        DisplayName = "Macaco da Selva",
        Biome = "Jungle",
        Weight = 7,
        RequiredStrength = 5,
        BaseValue = 140,
        Rarity = "Uncommon",
        RespawnSeconds = 18,
        Color = Color3.fromRGB(150, 93, 58),
        Accent = Color3.fromRGB(239, 187, 136),
        Shape = "Mammal",
    }),
    Macaw = table.freeze({
        Id = "Macaw",
        DisplayName = "Arara Azul",
        Biome = "Jungle",
        Weight = 8,
        RequiredStrength = 6,
        BaseValue = 260,
        Rarity = "Rare",
        RespawnSeconds = 22,
        Color = Color3.fromRGB(55, 160, 231),
        Accent = Color3.fromRGB(255, 195, 67),
        Shape = "Bird",
    }),
    Jaguar = table.freeze({
        Id = "Jaguar",
        DisplayName = "Onça Pintada",
        Biome = "Jungle",
        Weight = 22,
        RequiredStrength = 15,
        BaseValue = 450,
        Rarity = "Rare",
        RespawnSeconds = 24,
        Color = Color3.fromRGB(237, 179, 67),
        Accent = Color3.fromRGB(44, 36, 29),
        Shape = "Mammal",
    }),
    Panda = table.freeze({
        Id = "Panda",
        DisplayName = "Panda",
        Biome = "Jungle",
        Weight = 35,
        RequiredStrength = 25,
        BaseValue = 1200,
        Rarity = "Epic",
        RespawnSeconds = 30,
        Color = Color3.fromRGB(241, 239, 225),
        Accent = Color3.fromRGB(30, 34, 39),
        Shape = "Mammal",
    }),
    Tiger = table.freeze({
        Id = "Tiger",
        DisplayName = "Tigre Vulcânico",
        Biome = "Volcano",
        Weight = 55,
        RequiredStrength = 40,
        BaseValue = 2600,
        Rarity = "Legendary",
        RespawnSeconds = 38,
        Color = Color3.fromRGB(255, 131, 45),
        Accent = Color3.fromRGB(54, 34, 30),
        Shape = "Mammal",
    }),
    LavaFox = table.freeze({
        Id = "LavaFox",
        DisplayName = "Raposa de Lava",
        Biome = "Volcano",
        Weight = 28,
        RequiredStrength = 22,
        BaseValue = 1750,
        Rarity = "Epic",
        RespawnSeconds = 32,
        Color = Color3.fromRGB(255, 102, 47),
        Accent = Color3.fromRGB(255, 220, 107),
        Shape = "Mammal",
    }),
    Phoenix = table.freeze({
        Id = "Phoenix",
        DisplayName = "Fênix Mítica",
        Biome = "Volcano",
        Weight = 42,
        RequiredStrength = 35,
        BaseValue = 6000,
        Rarity = "Mythic",
        RespawnSeconds = 45,
        Color = Color3.fromRGB(248, 71, 44),
        Accent = Color3.fromRGB(255, 209, 64),
        Shape = "Bird",
    }),
})

function Catalog.Get(animalId)
    return Catalog.Animals[animalId]
end

function Catalog.ForBiome(biomeName)
    local results = {}

    for _, animal in pairs(Catalog.Animals) do
        if animal.Biome == biomeName then
            table.insert(results, animal)
        end
    end

    table.sort(results, function(a, b)
        return a.BaseValue < b.BaseValue
    end)

    return results
end

return table.freeze(Catalog)
