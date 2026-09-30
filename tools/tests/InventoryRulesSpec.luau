--!strict
local Test = require("./Test")
local Rules = require("../../src/CollisionBattlestar/ReplicatedStorage/Shared/InventoryRules")

return function()
    local owned = {Skin_UrbanShadow = true, Echo_Vanguard = false}
    Test.expect(Rules.canEquip("Skin_UrbanShadow", owned), "owned item should equip")
    Test.expect(not Rules.canEquip("Echo_Vanguard", owned), "unowned item should not equip")
    Test.expect(not Rules.canEquip("missing", owned), "missing item should not equip")
end
