--!strict

return function()
    local EconomyRules = require("../../src/CollisionBattlestar/ReplicatedStorage/Shared/EconomyRules")

    assert(EconomyRules.upgradeCost(0) == 50)
    assert(EconomyRules.upgradeCost(1) == 100)
    assert(EconomyRules.upgradeCost(2) == 200)
    assert(EconomyRules.upgradeDamage(0) == 0)
    assert(EconomyRules.upgradeDamage(3) == 15)
    assert(EconomyRules.canBuy(150, 100) == true)
    assert(EconomyRules.canBuy(99, 100) == false)
end
