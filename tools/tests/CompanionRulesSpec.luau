--!strict
local Test = require("./Test")
local Definitions = require("../../src/CollisionBattlestar/ReplicatedStorage/Shared/CompanionDefinitions")

return function()
    local classes = {"Vanguard", "Striker", "Guardian", "Support"}
    for _, id in ipairs(classes) do
        local class = Definitions.Classes[id]
        Test.expect(class ~= nil, "missing class " .. id)
        Test.expect(class.Damage > 0, "class damage must be positive")
        Test.expect(class.Cooldown > 0, "class cooldown must be positive")
        Test.expect(class.Range > 0, "class range must be positive")
    end
    Test.expect(Definitions.Classes.Support.HealAmount == 8, "support heal amount")
    Test.expect(Definitions.Classes.Support.HealCooldown == 4, "support heal cooldown")
end
