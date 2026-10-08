--!strict

local Themes = {
    Urban = {
        Primary = Color3.fromRGB(75, 82, 95),
        Secondary = Color3.fromRGB(35, 40, 48),
        Accent = Color3.fromRGB(155, 165, 180),
    },
    Tactical = {
        Primary = Color3.fromRGB(70, 95, 75),
        Secondary = Color3.fromRGB(32, 42, 34),
        Accent = Color3.fromRGB(175, 195, 120),
    },
    Industrial = {
        Primary = Color3.fromRGB(110, 87, 55),
        Secondary = Color3.fromRGB(55, 43, 28),
        Accent = Color3.fromRGB(235, 170, 70),
    },
    Neon = {
        Primary = Color3.fromRGB(55, 75, 105),
        Secondary = Color3.fromRGB(24, 28, 45),
        Accent = Color3.fromRGB(85, 220, 255),
    },
    Street = {
        Primary = Color3.fromRGB(105, 65, 85),
        Secondary = Color3.fromRGB(47, 33, 44),
        Accent = Color3.fromRGB(245, 110, 170),
    },
    Corrupted = {
        Primary = Color3.fromRGB(82, 58, 92),
        Secondary = Color3.fromRGB(35, 25, 42),
        Accent = Color3.fromRGB(205, 75, 235),
    },
    Arctic = {
        Primary = Color3.fromRGB(105, 140, 165),
        Secondary = Color3.fromRGB(38, 56, 68),
        Accent = Color3.fromRGB(175, 235, 255),
    },
    Desert = {
        Primary = Color3.fromRGB(125, 100, 68),
        Secondary = Color3.fromRGB(58, 46, 33),
        Accent = Color3.fromRGB(235, 195, 105),
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

local Profiles = {
    Urban = {
        profile("Urban", 1, "Urban_T1_Standard", "Light", "Round", "Harness"),
        profile("Urban", 2, "Urban_T2_Heavy", "Heavy", "Visor", "Plate"),
        profile("Urban", 3, "Urban_T3_Veteran", "Veteran", "Mask", "Shoulder"),
        profile("Urban", 4, "Urban_T4_Commander", "Commander", "Crest", "Commander"),
    },
    Tactical = {
        profile("Tactical", 1, "Tactical_T1_Standard", "Light", "Round", "Harness"),
        profile("Tactical", 2, "Tactical_T2_Heavy", "Heavy", "Visor", "Plate"),
        profile("Tactical", 3, "Tactical_T3_Veteran", "Veteran", "Mask", "Shoulder"),
        profile("Tactical", 4, "Tactical_T4_Commander", "Commander", "Crest", "Commander"),
    },
    Industrial = {
        profile("Industrial", 1, "Industrial_T1_Standard", "Light", "Round", "Harness"),
        profile("Industrial", 2, "Industrial_T2_Heavy", "Heavy", "Visor", "Plate"),
        profile("Industrial", 3, "Industrial_T3_Veteran", "Veteran", "Mask", "Shoulder"),
        profile("Industrial", 4, "Industrial_T4_Commander", "Commander", "Crest", "Commander"),
    },
    Neon = {
        profile("Neon", 1, "Neon_T1_Standard", "Light", "Round", "Harness"),
        profile("Neon", 2, "Neon_T2_Heavy", "Heavy", "Visor", "Plate"),
        profile("Neon", 3, "Neon_T3_Veteran", "Veteran", "Mask", "Shoulder"),
        profile("Neon", 4, "Neon_T4_Commander", "Commander", "Crest", "Commander"),
    },
    Street = {
        profile("Street", 1, "Street_T1_Standard", "Light", "Round", "Harness"),
        profile("Street", 2, "Street_T2_Heavy", "Heavy", "Visor", "Plate"),
        profile("Street", 3, "Street_T3_Veteran", "Veteran", "Mask", "Shoulder"),
        profile("Street", 4, "Street_T4_Commander", "Commander", "Crest", "Commander"),
    },
    Corrupted = {
        profile("Corrupted", 1, "Corrupted_T1_Standard", "Light", "Round", "Harness"),
        profile("Corrupted", 2, "Corrupted_T2_Heavy", "Heavy", "Visor", "Plate"),
        profile("Corrupted", 3, "Corrupted_T3_Veteran", "Veteran", "Mask", "Shoulder"),
        profile("Corrupted", 4, "Corrupted_T4_Commander", "Commander", "Crest", "Commander"),
    },
    Arctic = {
        profile("Arctic", 1, "Arctic_T1_Standard", "Light", "Round", "Harness"),
        profile("Arctic", 2, "Arctic_T2_Heavy", "Heavy", "Visor", "Plate"),
        profile("Arctic", 3, "Arctic_T3_Veteran", "Veteran", "Mask", "Shoulder"),
        profile("Arctic", 4, "Arctic_T4_Commander", "Commander", "Crest", "Commander"),
    },
    Desert = {
        profile("Desert", 1, "Desert_T1_Standard", "Light", "Round", "Harness"),
        profile("Desert", 2, "Desert_T2_Heavy", "Heavy", "Visor", "Plate"),
        profile("Desert", 3, "Desert_T3_Veteran", "Veteran", "Mask", "Shoulder"),
        profile("Desert", 4, "Desert_T4_Commander", "Commander", "Crest", "Commander"),
    },
}

return table.freeze({
    Themes = table.freeze(Themes),
    Profiles = table.freeze(Profiles),
})
