--!strict
local Test = require("./Test")
local Rules = require("../../src/CollisionBattlestar/ReplicatedStorage/Shared/EnemySkinRules")

return function()
    local profile = Rules.pick("Urban", "Elite", 123, nil)
    Test.expect(Rules.isValidProfile(profile), "picked profile must be valid")
    Test.equal(profile.ThemeId, "Urban", "theme")
    Test.equal(profile.Tier, "Elite", "tier")
    Test.expect(profile.PrimaryColor == Color3.fromRGB(210, 38, 52), "elite identity must be red")
    Test.expect(Rules.isValidProfile(Rules.pick("Neon", "Tier2", 22, profile.ProfileId)), "secondary profile valid")
    Test.expect(not Rules.isValidProfile({
        ProfileId = "bad",
        ThemeId = "Urban",
        Tier = "Elite",
        PrimaryColor = Color3.fromRGB(10, 10, 10),
        SecondaryColor = Color3.fromRGB(10, 10, 10),
        AccentColor = Color3.fromRGB(10, 10, 10),
        BodyVariant = 1,
        HeadVariant = 1,
        GearVariant = 1,
        AccessoryVariant = 1,
        MaterialVariant = 1,
    }), "elite non-red profile must be rejected")
end
