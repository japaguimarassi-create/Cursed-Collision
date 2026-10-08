--!strict

return function()
    local Rules = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/PersistenceRules")

    assert(Rules.canAcquire(nil, nil, "a", 100) == true)
    assert(Rules.canAcquire("a", 200, "a", 100) == true)
    assert(Rules.canAcquire("b", 200, "a", 100) == false)
    assert(Rules.canAcquire("b", 99, "a", 100) == true)
    assert(Rules.canAcquire("b", "bad", "a", 100) == true)

    local lock = Rules.makeLock("session", 100, 120)
    assert(lock.SessionId == "session")
    assert(lock.ExpiresAt == 220)
    assert(Rules.isOwned("session", "session") == true)
    assert(Rules.isOwned("other", "session") == false)
end
