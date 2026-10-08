--!strict

local Themes = {
    Urban = {
        Primary = {75, 82, 95},
        Secondary = {35, 40, 48},
        Accent = {155, 165, 180},
    },
    Tactical = {
        Primary = {70, 95, 75},
        Secondary = {32, 42, 34},
        Accent = {175, 195, 120},
    },
    Industrial = {
        Primary = {110, 87, 55},
        Secondary = {55, 43, 28},
        Accent = {235, 170, 70},
    },
    Neon = {
        Primary = {55, 75, 105},
        Secondary = {24, 28, 45},
        Accent = {85, 220, 255},
    },
    Street = {
        Primary = {105, 65, 85},
        Secondary = {47, 33, 44},
        Accent = {245, 110, 170},
    },
    Corrupted = {
        Primary = {82, 58, 92},
        Secondary = {35, 25, 42},
        Accent = {205, 75, 235},
    },
    Arctic = {
        Primary = {105, 140, 165},
        Secondary = {38, 56, 68},
        Accent = {175, 235, 255},
    },
    Desert = {
        Primary = {125, 100, 68},
        Secondary = {58, 46, 33},
        Accent = {235, 195, 105},
    },
}

local function profile(themeId: string, tier: number, id: string, bodyVariant: string, headVariant: string, gearVariant: string)
    local palette = Themes[themeId]
    return {
        ProfileId = id,
        ThemeId = themeId,
        Tier = tier,
        PrimaryColor = palette.Primary,
        SecondaryColor = palette.Secondary,
        AccentColor = palette.Accent,
        BodyVariant = bodyVariant,
        HeadVariant = headVariant,
        GearVariant = gearVariant,
        AccessoryVariant = "None",
        MaterialVariant = "Metal",
    }
end

local Profiles = {}

for themeId in pairs(Themes) do
    Profiles[themeId] = {
        profile(themeId, 1, themeId .. "_T1_Standard", "Light", "Round", "Harness"),
        profile(themeId, 2, themeId .. "_T2_Heavy", "Heavy", "Visor", "Plate"),
        profile(themeId, 3, themeId .. "_T3_Veteran", "Veteran", "Mask", "Shoulder"),
        profile(themeId, 4, themeId .. "_T4_Commander", "Commander", "Crest", "Commander"),
    }
end

return table.freeze({
    Themes = table.freeze(Themes),
    Profiles = table.freeze(Profiles),
})
