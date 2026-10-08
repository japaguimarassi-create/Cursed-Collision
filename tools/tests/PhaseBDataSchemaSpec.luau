--!strict

return function()
    local Schema = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/DataSchema")

    local fresh = Schema.Default()
    assert(fresh.SchemaVersion == 2)
    assert(fresh.Credits == 0)
    assert(fresh.PowerLevel == 1)
    assert(fresh.Inventory.Owned.Default == nil)

    local legacy = Schema.Migrate({
        SchemaVersion = 1,
        Credits = 250,
        PowerLevel = 4,
        Upgrades = {
            Damage = 3,
        },
        Inventory = {
            Owned = {
                Sword = true,
                Broken = "yes",
            },
        },
        Echoes = {
            main = {
                FriendUserId = 123,
                ClassId = "Striker",
                Level = 5,
                Bond = 12,
                Equipped = true,
                CosmeticIds = {"EchoA"},
            },
        },
    })

    assert(legacy.SchemaVersion == Schema.CurrentVersion)
    assert(legacy.Credits == 250)
    assert(legacy.PowerLevel == 4)
    assert(legacy.Upgrades.Damage == 3)
    assert(legacy.Inventory.Owned.Sword == true)
    assert(legacy.Inventory.Owned.Broken == nil)
    assert(legacy.Echoes.main.FriendUserId == 123)
    assert(legacy.Echoes.main.ClassId == "Striker")

    local hostile = Schema.Sanitize({
        Credits = -50,
        PowerLevel = math.huge,
        Upgrades = {
            Damage = 9999,
            MaxHealth = -4,
        },
        Inventory = {
            Owned = {
                Valid = true,
                Invalid = 123,
            },
        },
    })

    assert(hostile.Credits == 0)
    assert(hostile.PowerLevel == 1)
    assert(hostile.Upgrades.Damage == 100)
    assert(hostile.Upgrades.MaxHealth == 0)
    assert(hostile.Inventory.Owned.Valid == true)
    assert(hostile.Inventory.Owned.Invalid == nil)
end
