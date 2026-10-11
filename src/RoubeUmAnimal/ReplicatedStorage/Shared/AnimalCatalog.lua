local Catalog = {}

Catalog.RarityMultipliers = table.freeze({
    Common = 1,
    Uncommon = 1.5,
    Rare = 2.5,
    Epic = 5,
    Legendary = 10,
    Mythic = 20,
})

Catalog.BiomeOrder = table.freeze({
    Meadow = 1,
    Forest = 2,
    Wetlands = 3,
    Snow = 4,
    Savannah = 5,
    Volcano = 6,
})

Catalog.BiomeInfo = table.freeze({
    Meadow = table.freeze({ Name = "SUNNY MEADOW", Accent = Color3.fromRGB(255, 205, 89), Ground = Color3.fromRGB(133, 206, 104), Subtitle = "Friendly farm animals" }),
    Forest = table.freeze({ Name = "WHISPERING FOREST", Accent = Color3.fromRGB(66, 183, 117), Ground = Color3.fromRGB(62, 135, 82), Subtitle = "Rare woodland animals" }),
    Wetlands = table.freeze({ Name = "MISTY WETLANDS", Accent = Color3.fromRGB(66, 197, 191), Ground = Color3.fromRGB(69, 144, 130), Subtitle = "Animals that love water" }),
    Snow = table.freeze({ Name = "FROST PEAK", Accent = Color3.fromRGB(125, 211, 255), Ground = Color3.fromRGB(188, 223, 231), Subtitle = "Cold-weather creatures" }),
    Savannah = table.freeze({ Name = "GOLDEN SAVANNA", Accent = Color3.fromRGB(255, 177, 75), Ground = Color3.fromRGB(201, 174, 102), Subtitle = "Powerful wild animals" }),
    Volcano = table.freeze({ Name = "EMBER VOLCANO", Accent = Color3.fromRGB(255, 101, 67), Ground = Color3.fromRGB(75, 59, 67), Subtitle = "Mythical fire creatures" }),
})

Catalog.Animals = table.freeze({
    Chicken = table.freeze({
        Id = "Chicken", DisplayName = "Chicken", Biome = "Meadow", Weight = 2,
        BaseValue = 25, IncomePerSecond = 1, Rarity = "Common", RespawnSeconds = 12,
        Color = Color3.fromRGB(247, 224, 150), Accent = Color3.fromRGB(218, 81, 71), Shape = "Bird",
    }),
    Goat = table.freeze({
        Id = "Goat", DisplayName = "Goat", Biome = "Meadow", Weight = 8,
        BaseValue = 85, IncomePerSecond = 3, Rarity = "Uncommon", RespawnSeconds = 16,
        Color = Color3.fromRGB(239, 226, 194), Accent = Color3.fromRGB(108, 86, 66), Shape = "Mammal",
    }),
    Rabbit = table.freeze({
        Id = "Rabbit", DisplayName = "Meadow Rabbit", Biome = "Meadow", Weight = 3,
        BaseValue = 65, IncomePerSecond = 2, Rarity = "Common", RespawnSeconds = 14,
        Color = Color3.fromRGB(232, 215, 186), Accent = Color3.fromRGB(255, 154, 172), Shape = "Mammal",
    }),
    Deer = table.freeze({
        Id = "Deer", DisplayName = "Fawn", Biome = "Meadow", Weight = 7,
        BaseValue = 125, IncomePerSecond = 5, Rarity = "Uncommon", RespawnSeconds = 18,
        Color = Color3.fromRGB(193, 133, 78), Accent = Color3.fromRGB(244, 223, 179), Shape = "Mammal",
    }),
    Monkey = table.freeze({
        Id = "Monkey", DisplayName = "Forest Monkey", Biome = "Forest", Weight = 7,
        BaseValue = 145, IncomePerSecond = 7, Rarity = "Uncommon", RespawnSeconds = 18,
        Color = Color3.fromRGB(150, 93, 58), Accent = Color3.fromRGB(239, 187, 136), Shape = "Mammal",
    }),
    Macaw = table.freeze({
        Id = "Macaw", DisplayName = "Blue Macaw", Biome = "Forest", Weight = 8,
        BaseValue = 260, IncomePerSecond = 11, Rarity = "Rare", RespawnSeconds = 22,
        Color = Color3.fromRGB(55, 160, 231), Accent = Color3.fromRGB(255, 195, 67), Shape = "Bird",
    }),
    Fox = table.freeze({
        Id = "Fox", DisplayName = "Red Fox", Biome = "Forest", Weight = 9,
        BaseValue = 310, IncomePerSecond = 13, Rarity = "Rare", RespawnSeconds = 22,
        Color = Color3.fromRGB(230, 111, 55), Accent = Color3.fromRGB(255, 230, 201), Shape = "Mammal",
    }),
    Jaguar = table.freeze({
        Id = "Jaguar", DisplayName = "Jaguar", Biome = "Forest", Weight = 22,
        BaseValue = 650, IncomePerSecond = 27, Rarity = "Epic", RespawnSeconds = 26,
        Color = Color3.fromRGB(237, 179, 67), Accent = Color3.fromRGB(44, 36, 29), Shape = "Mammal",
    }),
    Panda = table.freeze({
        Id = "Panda", DisplayName = "Panda", Biome = "Forest", Weight = 35,
        BaseValue = 1200, IncomePerSecond = 42, Rarity = "Epic", RespawnSeconds = 30,
        Color = Color3.fromRGB(241, 239, 225), Accent = Color3.fromRGB(30, 34, 39), Shape = "Mammal",
    }),
    Wolf = table.freeze({
        Id = "Wolf", DisplayName = "Grey Wolf", Biome = "Forest", Weight = 27,
        BaseValue = 1050, IncomePerSecond = 38, Rarity = "Epic", RespawnSeconds = 28,
        Color = Color3.fromRGB(123, 139, 151), Accent = Color3.fromRGB(51, 62, 76), Shape = "Mammal",
    }),
    Capybara = table.freeze({
        Id = "Capybara", DisplayName = "Capybara", Biome = "Wetlands", Weight = 5,
        BaseValue = 110, IncomePerSecond = 5, Rarity = "Uncommon", RespawnSeconds = 15,
        Color = Color3.fromRGB(153, 111, 78), Accent = Color3.fromRGB(91, 65, 48), Shape = "Mammal",
    }),
    Frog = table.freeze({
        Id = "Frog", DisplayName = "Tree Frog", Biome = "Wetlands", Weight = 2,
        BaseValue = 240, IncomePerSecond = 10, Rarity = "Rare", RespawnSeconds = 19,
        Color = Color3.fromRGB(86, 202, 105), Accent = Color3.fromRGB(255, 221, 81), Shape = "Mammal",
    }),
    Otter = table.freeze({
        Id = "Otter", DisplayName = "River Otter", Biome = "Wetlands", Weight = 10,
        BaseValue = 480, IncomePerSecond = 19, Rarity = "Rare", RespawnSeconds = 23,
        Color = Color3.fromRGB(137, 91, 63), Accent = Color3.fromRGB(219, 190, 145), Shape = "Mammal",
    }),
    Crocodile = table.freeze({
        Id = "Crocodile", DisplayName = "Swamp Crocodile", Biome = "Wetlands", Weight = 48,
        BaseValue = 2100, IncomePerSecond = 76, Rarity = "Legendary", RespawnSeconds = 34,
        Color = Color3.fromRGB(69, 125, 78), Accent = Color3.fromRGB(193, 194, 112), Shape = "Reptile",
    }),
    Penguin = table.freeze({
        Id = "Penguin", DisplayName = "Penguin", Biome = "Snow", Weight = 6,
        BaseValue = 330, IncomePerSecond = 14, Rarity = "Rare", RespawnSeconds = 20,
        Color = Color3.fromRGB(42, 60, 77), Accent = Color3.fromRGB(244, 244, 225), Shape = "Bird",
    }),
    ArcticFox = table.freeze({
        Id = "ArcticFox", DisplayName = "Arctic Fox", Biome = "Snow", Weight = 9,
        BaseValue = 750, IncomePerSecond = 28, Rarity = "Epic", RespawnSeconds = 26,
        Color = Color3.fromRGB(236, 242, 246), Accent = Color3.fromRGB(139, 196, 221), Shape = "Mammal",
    }),
    Reindeer = table.freeze({
        Id = "Reindeer", DisplayName = "Reindeer", Biome = "Snow", Weight = 30,
        BaseValue = 1650, IncomePerSecond = 60, Rarity = "Legendary", RespawnSeconds = 32,
        Color = Color3.fromRGB(148, 111, 82), Accent = Color3.fromRGB(245, 219, 160), Shape = "Mammal",
    }),
    Zebra = table.freeze({
        Id = "Zebra", DisplayName = "Zebra", Biome = "Savannah", Weight = 35,
        BaseValue = 1900, IncomePerSecond = 72, Rarity = "Legendary", RespawnSeconds = 32,
        Color = Color3.fromRGB(235, 235, 221), Accent = Color3.fromRGB(45, 48, 52), Shape = "Mammal",
    }),
    Lion = table.freeze({
        Id = "Lion", DisplayName = "Savannah Lion", Biome = "Savannah", Weight = 43,
        BaseValue = 2800, IncomePerSecond = 105, Rarity = "Legendary", RespawnSeconds = 36,
        Color = Color3.fromRGB(222, 167, 74), Accent = Color3.fromRGB(145, 88, 42), Shape = "Mammal",
    }),
    Elephant = table.freeze({
        Id = "Elephant", DisplayName = "Elephant", Biome = "Savannah", Weight = 90,
        BaseValue = 6200, IncomePerSecond = 215, Rarity = "Mythic", RespawnSeconds = 42,
        Color = Color3.fromRGB(145, 157, 163), Accent = Color3.fromRGB(227, 224, 208), Shape = "Mammal",
    }),
    LavaFox = table.freeze({
        Id = "LavaFox", DisplayName = "Ember Fox", Biome = "Volcano", Weight = 28,
        BaseValue = 1750, IncomePerSecond = 68, Rarity = "Epic", RespawnSeconds = 32,
        Color = Color3.fromRGB(255, 102, 47), Accent = Color3.fromRGB(255, 220, 107), Shape = "Mammal",
    }),
    Tiger = table.freeze({
        Id = "Tiger", DisplayName = "Volcanic Tiger", Biome = "Volcano", Weight = 55,
        BaseValue = 3600, IncomePerSecond = 135, Rarity = "Legendary", RespawnSeconds = 38,
        Color = Color3.fromRGB(255, 131, 45), Accent = Color3.fromRGB(54, 34, 30), Shape = "Mammal",
    }),
    Phoenix = table.freeze({
        Id = "Phoenix", DisplayName = "Mythic Phoenix", Biome = "Volcano", Weight = 42,
        BaseValue = 6000, IncomePerSecond = 260, Rarity = "Mythic", RespawnSeconds = 45,
        Color = Color3.fromRGB(248, 71, 44), Accent = Color3.fromRGB(255, 209, 64), Shape = "Bird",
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
        if a.IncomePerSecond == b.IncomePerSecond then
            return a.BaseValue < b.BaseValue
        end
        return a.IncomePerSecond < b.IncomePerSecond
    end)
    return results
end

function Catalog.All()
    local results = {}
    for _, animal in pairs(Catalog.Animals) do
        table.insert(results, animal)
    end
    table.sort(results, function(a, b)
        local biomeA = Catalog.BiomeOrder[a.Biome] or 99
        local biomeB = Catalog.BiomeOrder[b.Biome] or 99
        if biomeA == biomeB then
            return a.IncomePerSecond < b.IncomePerSecond
        end
        return biomeA < biomeB
    end)
    return results
end

return table.freeze(Catalog)
