--!strict

local Themes = {
    Urban = {Primary = {75, 82, 95}, Secondary = {35, 40, 48}, Accent = {155, 165, 180}},
    Tactical = {Primary = {70, 95, 75}, Secondary = {32, 42, 34}, Accent = {175, 195, 120}},
    Industrial = {Primary = {110, 87, 55}, Secondary = {55, 43, 28}, Accent = {235, 170, 70}},
    Neon = {Primary = {55, 75, 105}, Secondary = {24, 28, 45}, Accent = {85, 220, 255}},
    Street = {Primary = {105, 65, 85}, Secondary = {47, 33, 44}, Accent = {245, 110, 170}},
    Corrupted = {Primary = {82, 58, 92}, Secondary = {35, 25, 42}, Accent = {205, 75, 235}},
    Arctic = {Primary = {105, 140, 165}, Secondary = {38, 56, 68}, Accent = {175, 235, 255}},
    Desert = {Primary = {125, 100, 68}, Secondary = {58, 46, 33}, Accent = {235, 195, 105}},
}

local Compatibility = {
    [1] = {
        Body = {Light = true},
        Head = {Round = true, Visor = true},
        Gear = {Harness = true, HarnessAlt = true},
        Accessory = {None = true, Strap = true},
    },
    [2] = {
        Body = {Heavy = true},
        Head = {Visor = true, Mask = true},
        Gear = {Plate = true, PlateAlt = true},
        Accessory = {None = true, Utility = true},
    },
    [3] = {
        Body = {Veteran = true},
        Head = {Mask = true, Crest = true},
        Gear = {Shoulder = true, ShoulderAlt = true},
        Accessory = {None = true, Cloak = true},
    },
    [4] = {
        Body = {Commander = true},
        Head = {Crest = true, Visor = true},
        Gear = {Commander = true, CommanderAlt = true},
        Accessory = {None = true, Crown = true},
    },
}

local function copyColor(value)
    return {value[1], value[2], value[3]}
end

local function profile(themeId: string, tier: number, id: string, bodyVariant: string, headVariant: string, gearVariant: string, accessoryVariant: string)
    local palette = Themes[themeId]
    return {
        ProfileId = id,
        ThemeId = themeId,
        Tier = tier,
        PrimaryColor = copyColor(palette.Primary),
        SecondaryColor = copyColor(palette.Secondary),
        AccentColor = copyColor(palette.Accent),
        BodyVariant = bodyVariant,
        HeadVariant = headVariant,
        GearVariant = gearVariant,
        AccessoryVariant = accessoryVariant,
        MaterialVariant = "Metal",
    }
end

local Profiles = {}

for themeId in pairs(Themes) do
    Profiles[themeId] = {
        profile(themeId, 1, themeId .. "_T1_A", "Light", "Round", "Harness", "None"),
        profile(themeId, 1, themeId .. "_T1_B", "Light", "Visor", "HarnessAlt", "Strap"),
        profile(themeId, 2, themeId .. "_T2_A", "Heavy", "Visor", "Plate", "None"),
        profile(themeId, 2, themeId .. "_T2_B", "Heavy", "Mask", "PlateAlt", "Utility"),
        profile(themeId, 3, themeId .. "_T3_A", "Veteran", "Mask", "Shoulder", "None"),
        profile(themeId, 3, themeId .. "_T3_B", "Veteran", "Crest", "ShoulderAlt", "Cloak"),
        profile(themeId, 4, themeId .. "_T4_A", "Commander", "Crest", "Commander", "None"),
        profile(themeId, 4, themeId .. "_T4_B", "Commander", "Visor", "CommanderAlt", "Crown"),
    }
end

return table.freeze({
    Themes = table.freeze(Themes),
    Compatibility = table.freeze(Compatibility),
    Profiles = table.freeze(Profiles),
})
