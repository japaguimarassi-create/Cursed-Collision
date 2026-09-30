--!strict
local Test = require("./Test")
local Rules = require("../../src/CollisionBattlestar/ReplicatedStorage/Shared/FriendRules")

return function()
    Test.expect(not Rules.isEligible(10, 10, {20, 30}), "self must be rejected")
    Test.expect(not Rules.isEligible(10, 99, {20, 30}), "non-friend must be rejected")
    Test.expect(Rules.isEligible(10, 20, {20, 30}), "friend must be accepted")
    Test.expect(Rules.classIsValid("Vanguard"), "Vanguard must be valid")
    Test.expect(not Rules.classIsValid("Invalid"), "invalid class must be rejected")
end
