--!strict
local Test=require("./Test")
local Definitions=require("../../src/CollisionBattlestar/ReplicatedStorage/Shared/EnemySkinDefinitions")
return function()
    local profile=Definitions.make("Urban","Elite",1)
    Test.equal(profile.ProfileId,"Urban_Elite_1","profile id")
    Test.equal(profile.PrimaryColor[1],210,"elite red R")
    Test.equal(profile.PrimaryColor[2],38,"elite red G")
    Test.equal(profile.PrimaryColor[3],52,"elite red B")
    local normal=Definitions.make("Neon","Tier2",2)
    Test.equal(normal.ThemeId,"Neon","theme")
    Test.equal(normal.Tier,"Tier2","tier")
end
