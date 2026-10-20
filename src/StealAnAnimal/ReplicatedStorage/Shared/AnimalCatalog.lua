local Catalog = {}

local species = {
    { Id = "Bunny", Name = "Coelhinho", Biome = "Meadow", Rarity = "Comum", Weight = 2, Income = 4, Color = Color3.fromRGB(242, 222, 210), Shape = "Mammal", Accent = Color3.fromRGB(240, 153, 174) },
    { Id = "Chick", Name = "Pintinho", Biome = "Meadow", Rarity = "Comum", Weight = 1, Income = 3, Color = Color3.fromRGB(255, 221, 91), Shape = "Bird", Accent = Color3.fromRGB(255, 147, 57) },
    { Id = "Lamb", Name = "Cordeirinho", Biome = "Meadow", Rarity = "Incomum", Weight = 4, Income = 7, Color = Color3.fromRGB(245, 240, 222), Shape = "Mammal", Accent = Color3.fromRGB(193, 171, 153) },
    { Id = "Fawn", Name = "Filhote de Cervo", Biome = "Meadow", Rarity = "Raro", Weight = 6, Income = 12, Color = Color3.fromRGB(199, 133, 77), Shape = "Deer", Accent = Color3.fromRGB(246, 222, 170) },
    { Id = "Hen", Name = "Galinha", Biome = "Meadow", Rarity = "Épico", Weight = 8, Income = 18, Color = Color3.fromRGB(244, 224, 194), Shape = "Bird", Accent = Color3.fromRGB(190, 62, 58) },

    { Id = "Duckling", Name = "Patinho", Biome = "Lake", Rarity = "Comum", Weight = 2, Income = 8, Color = Color3.fromRGB(255, 225, 109), Shape = "Bird", Accent = Color3.fromRGB(255, 151, 36) },
    { Id = "Swan", Name = "Cisne", Biome = "Lake", Rarity = "Raro", Weight = 9, Income = 31, Color = Color3.fromRGB(250, 248, 238), Shape = "Bird", Accent = Color3.fromRGB(255, 141, 42) },

    { Id = "Fox", Name = "Raposa", Biome = "Forest", Rarity = "Comum", Weight = 5, Income = 9, Color = Color3.fromRGB(225, 116, 55), Shape = "Fox", Accent = Color3.fromRGB(255, 232, 196) },
    { Id = "Hedgehog", Name = "Ouriço", Biome = "Forest", Rarity = "Incomum", Weight = 3, Income = 10, Color = Color3.fromRGB(158, 112, 77), Shape = "Hedgehog", Accent = Color3.fromRGB(231, 206, 168) },
    { Id = "Owl", Name = "Corujinha", Biome = "Forest", Rarity = "Raro", Weight = 4, Income = 17, Color = Color3.fromRGB(158, 119, 88), Shape = "Bird", Accent = Color3.fromRGB(255, 207, 96) },
    { Id = "Wolf", Name = "Lobo", Biome = "Forest", Rarity = "Épico", Weight = 10, Income = 25, Color = Color3.fromRGB(125, 137, 151), Shape = "Wolf", Accent = Color3.fromRGB(224, 235, 244) },

    { Id = "Frog", Name = "Sapinho", Biome = "Wetlands", Rarity = "Comum", Weight = 2, Income = 11, Color = Color3.fromRGB(92, 194, 113), Shape = "Frog", Accent = Color3.fromRGB(245, 225, 112) },
    { Id = "Turtle", Name = "Tartaruguinha", Biome = "Wetlands", Rarity = "Incomum", Weight = 7, Income = 19, Color = Color3.fromRGB(83, 155, 105), Shape = "Turtle", Accent = Color3.fromRGB(185, 132, 76) },
    { Id = "Otter", Name = "Lontrinha", Biome = "Wetlands", Rarity = "Raro", Weight = 8, Income = 27, Color = Color3.fromRGB(146, 103, 72), Shape = "Otter", Accent = Color3.fromRGB(226, 190, 146) },
    { Id = "Crocodile", Name = "Crocodilo Bebê", Biome = "Wetlands", Rarity = "Lendário", Weight = 18, Income = 46, Color = Color3.fromRGB(77, 139, 93), Shape = "Reptile", Accent = Color3.fromRGB(185, 211, 126) },

    { Id = "Penguin", Name = "Pinguinzinho", Biome = "Frost", Rarity = "Comum", Weight = 5, Income = 18, Color = Color3.fromRGB(55, 78, 104), Shape = "Bird", Accent = Color3.fromRGB(250, 245, 227) },
    { Id = "ArcticFox", Name = "Raposa Polar", Biome = "Frost", Rarity = "Raro", Weight = 7, Income = 35, Color = Color3.fromRGB(236, 241, 245), Shape = "Fox", Accent = Color3.fromRGB(160, 213, 255) },
    { Id = "Mammoth", Name = "Mamute Bebê", Biome = "Frost", Rarity = "Épico", Weight = 28, Income = 68, Color = Color3.fromRGB(131, 143, 158), Shape = "Mammoth", Accent = Color3.fromRGB(235, 220, 190) },
    { Id = "PolarBear", Name = "Urso Polar", Biome = "Frost", Rarity = "Lendário", Weight = 24, Income = 83, Color = Color3.fromRGB(238, 242, 246), Shape = "Bear", Accent = Color3.fromRGB(188, 221, 238) },

    { Id = "Meerkat", Name = "Suricato", Biome = "Savanna", Rarity = "Comum", Weight = 4, Income = 24, Color = Color3.fromRGB(203, 154, 94), Shape = "Mammal", Accent = Color3.fromRGB(245, 220, 178) },
    { Id = "LionCub", Name = "Leãozinho", Biome = "Savanna", Rarity = "Raro", Weight = 12, Income = 52, Color = Color3.fromRGB(218, 157, 67), Shape = "Lion", Accent = Color3.fromRGB(255, 207, 96) },
    { Id = "Elephant", Name = "Elefantinho", Biome = "Savanna", Rarity = "Épico", Weight = 35, Income = 90, Color = Color3.fromRGB(143, 151, 160), Shape = "Elephant", Accent = Color3.fromRGB(235, 219, 194) },
    { Id = "LionGuardian", Name = "Leão", Biome = "Savanna", Rarity = "Lendário", Weight = 36, Income = 128, Color = Color3.fromRGB(235, 168, 63), Shape = "Lion", Accent = Color3.fromRGB(120, 71, 47) },

    { Id = "Salamander", Name = "Salamandra de Brasa", Biome = "Volcano", Rarity = "Raro", Weight = 8, Income = 61, Color = Color3.fromRGB(235, 83, 47), Shape = "Reptile", Accent = Color3.fromRGB(255, 191, 67) },
    { Id = "Phoenix", Name = "Fênix Bebê", Biome = "Volcano", Rarity = "Épico", Weight = 6, Income = 115, Color = Color3.fromRGB(240, 101, 45), Shape = "Bird", Accent = Color3.fromRGB(255, 221, 92) },
    { Id = "Dragon", Name = "Dragãozinho", Biome = "Volcano", Rarity = "Mítico", Weight = 22, Income = 180, Color = Color3.fromRGB(135, 75, 182), Shape = "Dragon", Accent = Color3.fromRGB(255, 119, 91) },

    { Id = "Dolphin", Name = "Golfinho", Biome = "Ocean", Rarity = "Raro", Weight = 16, Income = 140, Color = Color3.fromRGB(91, 177, 207), Shape = "Dolphin", Accent = Color3.fromRGB(198, 236, 242) },
    { Id = "MantaRay", Name = "Arraia-Lua", Biome = "Ocean", Rarity = "Épico", Weight = 19, Income = 210, Color = Color3.fromRGB(65, 113, 151), Shape = "Ray", Accent = Color3.fromRGB(113, 212, 224) },
    { Id = "Whale", Name = "Baleia", Biome = "Ocean", Rarity = "Mítico", Weight = 60, Income = 320, Color = Color3.fromRGB(77, 133, 180), Shape = "Whale", Accent = Color3.fromRGB(160, 218, 239) },
}

local byId = {}
for _, entry in ipairs(species) do
    byId[entry.Id] = table.freeze(entry)
end

function Catalog.Get(id)
    return byId[id]
end

function Catalog.All()
    return species
end

function Catalog.ForBiome(biomeId)
    local result = {}
    for _, entry in ipairs(species) do
        if entry.Biome == biomeId then
            table.insert(result, entry)
        end
    end
    return result
end

return table.freeze(Catalog)
