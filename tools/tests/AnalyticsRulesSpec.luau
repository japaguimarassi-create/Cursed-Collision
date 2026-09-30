--!strict
local Test = require("./Test")
local Rules = require("../../src/CollisionBattlestar/ReplicatedStorage/Shared/AnalyticsRules")

return function()
    local event = Rules.normalize("Wave", {
        wave = 4,
        tier = "Elite",
        result = "Defeat",
        itemId = "Skin_UrbanShadow",
    })
    Test.equal(event.Name, "Wave", "event name")
    Test.equal(event.Fields[1], "4", "wave field")
    Test.expect(#event.Fields <= 3, "field budget")
    Test.expect(Rules.isAllowedEvent("Combat"), "Combat is allowed")
    Test.expect(not Rules.isAllowedEvent("RandomEvent123"), "unknown event rejected")
end
