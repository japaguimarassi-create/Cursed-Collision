--!strict

return function()
    local FriendRules = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/FriendRules")
    local Classes = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/CompanionDefinitions")
    local Rules = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/CompanionRules")

    local friends = {
        {Id = 100, Username = "FriendA", DisplayName = "Friend A"},
        {Id = 200, Username = "FriendB", DisplayName = "Friend B"},
    }

    assert(FriendRules.isValidUserId(100) == true)
    assert(FriendRules.isValidUserId(-2) == false)
    assert(FriendRules.isValidClass("Support") == true)
    assert(FriendRules.isValidClass("Mage") == false)

    local ok, reason = FriendRules.canSelect(10, 100, friends, "Vanguard")
    assert(ok == true and reason == "ok")

    ok, reason = FriendRules.canSelect(10, 10, friends, "Vanguard")
    assert(ok == false and reason == "self_not_allowed")

    ok, reason = FriendRules.canSelect(10, 999, friends, "Vanguard")
    assert(ok == false and reason == "not_friend")

    assert(Classes.Vanguard.Damage == 20)
    assert(Classes.Striker.Damage > Classes.Guardian.Damage)
    assert(Classes.Support.HealAmount == 8)

    assert(Rules.canSummon(0) == true)
    assert(Rules.canSummon(1) == false)
    assert(Rules.healAmount(92, 100, 8) == 8)
    assert(Rules.healAmount(98, 100, 8) == 2)
    assert(Rules.canTransition("Follow", "Acquire") == true)
    assert(Rules.canTransition("Follow", "Attack") == false)

    local elite = Rules.targetScore("Striker", {
        Distance = 20,
        MaxHealth = 100,
        IsElite = true,
        ThreatensOwner = false,
        NearOwner = false,
    })

    local normal = Rules.targetScore("Striker", {
        Distance = 2,
        MaxHealth = 300,
        IsElite = false,
        ThreatensOwner = false,
        NearOwner = false,
    })

    assert(elite > normal)
end
