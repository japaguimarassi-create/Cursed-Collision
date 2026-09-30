--!strict
local Test=require("./Test")
local Rules=require("../../src/CollisionBattlestar/ReplicatedStorage/Shared/EnemySkinRules")
return function()
    local profile={
        ProfileId="Urban_Elite_1",
        ThemeId="Urban",
        Tier="Elite",
        PrimaryColor={210,38,52},
        SecondaryColor={74,18,24},
        AccentColor={255,112,122},
        BodyVariant=1,
        HeadVariant=1,
        GearVariant=2,
        AccessoryVariant=2,
        MaterialVariant=1,
    }
    Test.expect(Rules.isValidProfile(profile),"valid profile")
    Test.expect(not Rules.isValidProfile({
        ProfileId="bad",ThemeId="Urban",Tier="Elite",
        PrimaryColor={10,10,10},SecondaryColor={10,10,10},AccentColor={10,10,10},
        BodyVariant=1,HeadVariant=1,GearVariant=1,AccessoryVariant=1,MaterialVariant=1,
    }),"elite non-red profile rejected")
end
