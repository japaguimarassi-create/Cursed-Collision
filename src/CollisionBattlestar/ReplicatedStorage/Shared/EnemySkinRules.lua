--!strict
local Definitions=require(script.Parent:WaitForChild("EnemySkinDefinitions"))
local Rules={}
local validTiers={Tier1=true,Tier2=true,Tier3=true,Elite=true}
local function sameColor(a:{number},b:{number}):boolean return a[1]==b[1] and a[2]==b[2] and a[3]==b[3] end
function Rules.isValidProfile(profile):boolean
    if type(profile)~="table" or type(profile.ProfileId)~="string" or profile.ProfileId=="" then return false end
    if type(profile.ThemeId)~="string" or not validTiers[profile.Tier] then return false end
    local validTheme=false
    for _,id in ipairs(Definitions.themeIds()) do if id==profile.ThemeId then validTheme=true break end end
    if not validTheme then return false end
    for _,key in ipairs({"PrimaryColor","SecondaryColor","AccentColor"}) do
        local c=profile[key]
        if type(c)~="table" or #c~=3 then return false end
        for _,v in ipairs(c) do if type(v)~="number" or v<0 or v>255 then return false end end
    end
    for _,key in ipairs({"BodyVariant","HeadVariant","GearVariant","AccessoryVariant","MaterialVariant"}) do if type(profile[key])~="number" or profile[key]<1 then return false end end
    return profile.Tier~="Elite" or sameColor(profile.PrimaryColor,{210,38,52})
end
local function seeded(seed:number):number
    local value=math.floor(math.abs(seed))%2147483647
    return (value*48271)%2147483647
end
function Rules.validProfiles(themeId:string,tier:string)
    local count=if tier=="Elite" then 2 else 4
    local profiles={}
    for i=1,count do table.insert(profiles,Definitions.make(themeId,tier,i)) end
    return profiles
end
function Rules.pick(themeId:string,tier:string,seed:number,previousProfileId:string?)
    local profiles=Rules.validProfiles(themeId,tier)
    local index=(seeded(seed)%#profiles)+1
    if previousProfileId and #profiles>1 and profiles[index].ProfileId==previousProfileId then index=(index%#profiles)+1 end
    return profiles[index]
end
return table.freeze(Rules)
