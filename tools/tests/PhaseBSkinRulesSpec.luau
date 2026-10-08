--!strict

return function()
    local Definitions = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/EnemySkinDefinitions")
    local Rules = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/EnemySkinRules")

    local candidates = Rules.validProfiles("Urban", 1, Definitions)
    assert(#candidates >= 2)

    local first = Rules.pick("Urban", 1, 1, nil, Definitions)
    local second = Rules.pick("Urban", 1, 2, first and first.ProfileId, Definitions)

    assert(first ~= nil)
    assert(second ~= nil)
    assert(Rules.isValidProfile(first, Definitions))
    assert(Rules.isValidProfile(second, Definitions))
    assert(first.ProfileId ~= second.ProfileId)

    local invalid = {
        ProfileId = "Invalid",
        ThemeId = "Urban",
        Tier = 1,
        PrimaryColor = {0, 0, 0},
        SecondaryColor = {0, 0, 0},
        AccentColor = {0, 0, 0},
        BodyVariant = "Heavy",
        HeadVariant = "Round",
        GearVariant = "Harness",
        AccessoryVariant = "None",
    }

    assert(Rules.isValidProfile(invalid, Definitions) == false)
    assert(#Rules.validProfiles("Neon", 3, Definitions) == 2)
    assert(#Rules.validProfiles("Unknown", 1, Definitions) == 0)
end
