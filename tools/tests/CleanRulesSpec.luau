--!strict

local Test = require("./Test")
local Rules = require("../../src/CollisionBattlestar/ReplicatedStorage/CleanRules")

return function()
    Test.equal(Rules.enemyCount(1), 5, "wave one count")
    Test.equal(Rules.enemyCount(10), 17, "wave ten count")
    Test.equal(Rules.normalTier(1, 1), "Tier1", "early tier")
    Test.equal(Rules.normalTier(8, 1), "Tier2", "mid tier")
    Test.equal(Rules.normalTier(14, 8), "Tier3", "late tier")
    Test.equal(Rules.baseDamage(1), 25, "combo one")
    Test.equal(Rules.baseDamage(3), 35, "combo three")
    Test.equal(Rules.upgradeCost(0), 50, "first upgrade")
    Test.equal(Rules.upgradeCost(1), 100, "second upgrade")
    Test.equal(Rules.waveReward(4), 100, "wave reward")
    Test.equal(Rules.enemyStats("Elite").Reward, 35, "elite reward")
    Test.expect(Rules.isValidEchoClass("Vanguard"), "vanguard valid")
    Test.expect(not Rules.isValidEchoClass("Unknown"), "unknown echo invalid")
    Test.expect(Rules.isValidSkin("NeonPulse"), "neon skin valid")
    Test.expect(not Rules.isValidSkin("Unknown"), "unknown skin invalid")
end
