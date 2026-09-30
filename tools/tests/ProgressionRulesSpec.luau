--!strict
local Test = require("./Test")
local Rules = require("../../src/CollisionBattlestar/ReplicatedStorage/Shared/ProgressionRules")

return function()
    local profile = Rules.defaultProfile()
    Test.equal(profile.Credits, 0, "default credits")
    Test.equal(profile.DamageLevel, 0, "default damage level")
    Test.equal(profile.XP, 0, "default xp")
    Test.expect(Rules.validate(profile), "default profile valid")
    profile.Credits = -1
    Test.expect(not Rules.validate(profile), "negative credits invalid")
end
