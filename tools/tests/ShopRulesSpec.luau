--!strict
local Test = require("./Test")
local Rules = require("../../src/CollisionBattlestar/ReplicatedStorage/Shared/ShopRules")
local Catalog = require("../../src/CollisionBattlestar/ReplicatedStorage/Shared/ShopDefinitions")

return function()
    local item = Catalog.Items["Skin_UrbanShadow"]
    Test.expect(item ~= nil, "catalog item must exist")
    Test.equal(Rules.price("Skin_UrbanShadow", Catalog.Items), item.Price, "price lookup")
    Test.expect(Rules.canPurchase(100, item.Price, false), "affordable item")
    Test.expect(not Rules.canPurchase(100, item.Price, true), "owned item must not be repurchased")
    Test.expect(not Rules.canPurchase(0, item.Price, false), "insufficient credits")
    Test.expect(Rules.price("unknown", Catalog.Items) == nil, "unknown item must not resolve")
end
