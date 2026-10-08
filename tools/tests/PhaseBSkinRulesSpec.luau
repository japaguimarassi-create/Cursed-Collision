--!strict

return function()
    local Definitions = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/EnemySkinDefinitions")
    local Rules = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/EnemySkinRules")

    local first = Rules.pick("Urban", 1, 1, nil, Definitions)
    local second = Rules.pick("Urban", 1, 2, first and first.ProfileId, Definitions)

    assert(first ~= nil)
    assert(second ~= nil)
    assert(Rules.isValidProfile(first))
    assert(Rules.isValidProfile(second))
    assert(first.ProfileId ~= second.ProfileId or #Rules.validProfiles("Urban", 1, Definitions) == 1)

    assert(#Rules.validProfiles("Neon", 3, Definitions) >= 1)
    assert(#Rules.validProfiles("Unknown", 1, Definitions) == 0)
    assert(Definitions.Profiles.Corrupted[4].Tier == 4)
end
