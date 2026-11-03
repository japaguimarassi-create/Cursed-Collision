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

    { Id = "ShibaInu", Name = "Shiba Inu", Biome = "Forest", Rarity = "Incomum", Weight = 6, Income = 16, Color = Color3.fromRGB(224, 132, 61), Shape = "Fox", Accent = Color3.fromRGB(250, 225, 181) },
    { Id = "RedPanda", Name = "Panda-Vermelho", Biome = "Forest", Rarity = "Épico", Weight = 13, Income = 48, Color = Color3.fromRGB(183, 73, 39), Shape = "Mammal", Accent = Color3.fromRGB(250, 229, 193) },
    { Id = "HouseCat", Name = "Gatinho", Biome = "Meadow", Rarity = "Incomum", Weight = 4, Income = 14, Color = Color3.fromRGB(128, 139, 151), Shape = "Mammal", Accent = Color3.fromRGB(236, 225, 207) },
    { Id = "Axolotl", Name = "Axolote", Biome = "Wetlands", Rarity = "Épico", Weight = 8, Income = 56, Color = Color3.fromRGB(239, 151, 165), Shape = "Reptile", Accent = Color3.fromRGB(255, 222, 224) },
    { Id = "Unicorn", Name = "Unicórnio Celestial", Biome = "Frost", Rarity = "Mítico", Weight = 18, Income = 190, Color = Color3.fromRGB(241, 233, 255), Shape = "Mammal", Accent = Color3.fromRGB(174, 126, 230) },
    { Id = "Koala", Name = "Coalinha", Biome = "Forest", Rarity = "Raro", Weight = 7, Income = 33, Color = Color3.fromRGB(145, 153, 157), Shape = "Bear", Accent = Color3.fromRGB(238, 178, 184) },
    { Id = "Peacock", Name = "Pavão Real", Biome = "Savanna", Rarity = "Épico", Weight = 12, Income = 78, Color = Color3.fromRGB(36, 112, 139), Shape = "Bird", Accent = Color3.fromRGB(52, 190, 151) },
    { Id = "Capybara", Name = "Capivara", Biome = "Wetlands", Rarity = "Incomum", Weight = 6, Income = 22, Color = Color3.fromRGB(155, 105, 68), Shape = "Mammal", Accent = Color3.fromRGB(221, 190, 151) },
    { Id = "Panda", Name = "Panda-Gigante", Biome = "Frost", Rarity = "Épico", Weight = 16, Income = 88, Color = Color3.fromRGB(235, 232, 218), Shape = "Bear", Accent = Color3.fromRGB(42, 39, 37) },
    { Id = "Raccoon", Name = "Guaxinim", Biome = "Forest", Rarity = "Incomum", Weight = 5, Income = 25, Color = Color3.fromRGB(116, 119, 119), Shape = "Mammal", Accent = Color3.fromRGB(45, 43, 42) },
    { Id = "Sloth", Name = "Bicho-Preguiça", Biome = "Wetlands", Rarity = "Raro", Weight = 9, Income = 44, Color = Color3.fromRGB(126, 143, 95), Shape = "Mammal", Accent = Color3.fromRGB(205, 185, 143) },
    { Id = "Cheetah", Name = "Guepardo", Biome = "Savanna", Rarity = "Lendário", Weight = 22, Income = 145, Color = Color3.fromRGB(222, 169, 91), Shape = "Mammal", Accent = Color3.fromRGB(52, 43, 35) },


    { Id = "CrystalbackGecko", Name = "Lagarto Prisma", Biome = "Forest", Rarity = "Lendário", Weight = 11, Income = 95, Color = Color3.fromRGB(31, 177, 104), Shape = "Gecko", Accent = Color3.fromRGB(74, 201, 255) },
    { Id = "BloomforgedBeetle", Name = "Besouro Flor de Cristal", Biome = "Meadow", Rarity = "Mítico", Weight = 19, Income = 175, Color = Color3.fromRGB(49, 57, 156), Shape = "Beetle", Accent = Color3.fromRGB(74, 220, 255) },
    { Id = "RunebillBluejay", Name = "Gaio Rúnico", Biome = "Lake", Rarity = "Mítico", Weight = 8, Income = 160, Color = Color3.fromRGB(31, 91, 225), Shape = "Bluejay", Accent = Color3.fromRGB(74, 219, 255) },
    { Id = "AstralJackalope", Name = "Jackalope Astral", Biome = "Frost", Rarity = "Cósmico", Weight = 17, Income = 420, Color = Color3.fromRGB(122, 119, 181), Shape = "Jackalope", Accent = Color3.fromRGB(191, 132, 255) },
    { Id = "SpiritwoodPanda", Name = "Panda Guardião", Biome = "Forest", Rarity = "Cósmico", Weight = 29, Income = 690, Color = Color3.fromRGB(34, 39, 43), Shape = "SpiritPanda", Accent = Color3.fromRGB(119, 230, 115) },
    { Id = "Novafox", Name = "Raposa Nova", Biome = "Ocean", Rarity = "Secreto", Weight = 14, Income = 1800, Color = Color3.fromRGB(62, 73, 135), Shape = "StarryFox", Accent = Color3.fromRGB(48, 193, 255) },
    { Id = "StarforgedSunlion", Name = "Leão Forjado em Estrelas", Biome = "Volcano", Rarity = "Eterno", Weight = 48, Income = 5200, Color = Color3.fromRGB(115, 49, 224), Shape = "Sunlion", Accent = Color3.fromRGB(255, 193, 66) },
    { Id = "VerdantSkyWhale", Name = "Baleia Jardim Celestial", Biome = "Ocean", Rarity = "Divino", Weight = 75, Income = 12000, Color = Color3.fromRGB(76, 49, 161), Shape = "SkyWhale", Accent = Color3.fromRGB(89, 220, 255) },

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
