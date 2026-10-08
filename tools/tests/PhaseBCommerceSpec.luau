--!strict

return function()
    local ShopRules = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/ShopRules")
    local InventoryRules = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/InventoryRules")

    assert(ShopRules.isSafeShopPhase("Intermission") == true)
    assert(ShopRules.isSafeShopPhase("Cleared") == true)
    assert(ShopRules.isSafeShopPhase("Wave") == false)

    local owned = InventoryRules.grant({}, "AttackFX_Shock")
    assert(InventoryRules.isOwned(owned, "AttackFX_Shock") == true)
    assert(InventoryRules.canGrant(owned, "AttackFX_Shock") == false)

    local equipped = InventoryRules.equip({}, "AttackFX_Shock", "AttackFX")
    assert(equipped.AttackFX == "AttackFX_Shock")
end
