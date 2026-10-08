--!strict

return function()
    local Definitions = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/ShopDefinitions")
    local ShopRules = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/ShopRules")
    local InventoryRules = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/InventoryRules")

    local item = Definitions.Items.AttackFX_Shock
    assert(ShopRules.isValidItem(item) == true)
    assert(ShopRules.isCreditsItem(item) == true)

    local ok, reason = ShopRules.canPurchase(item, {}, 500)
    assert(ok == true and reason == "ok")

    ok, reason = ShopRules.canPurchase(item, {AttackFX_Shock = true}, 500)
    assert(ok == false and reason == "already_owned")

    ok, reason = ShopRules.canPurchase(item, {}, 100)
    assert(ok == false and reason == "insufficient_credits")

    assert(ShopRules.isSafeShopPhase("Intermission") == true)
    assert(ShopRules.isSafeShopPhase("Wave") == false)

    assert(InventoryRules.canGrant({}, "A") == true)
    assert(InventoryRules.canGrant({A = true}, "A") == false)

    local owned = InventoryRules.grant({}, "A")
    assert(owned.A == true)

    local equipped = InventoryRules.equip({}, "A", "AttackFX")
    assert(equipped.AttackFX == "A")
    assert(Definitions.Items.Upgrade_Damage.UpgradeId == "Damage")
end
