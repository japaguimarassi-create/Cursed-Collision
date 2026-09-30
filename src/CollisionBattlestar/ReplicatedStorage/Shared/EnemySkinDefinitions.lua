--!strict
export type Color={number}
export type Profile={ProfileId:string,ThemeId:string,Tier:string,PrimaryColor:Color,SecondaryColor:Color,AccentColor:Color,BodyVariant:number,HeadVariant:number,GearVariant:number,AccessoryVariant:number,MaterialVariant:number}
local function rgb(r:number,g:number,b:number):Color return {r,g,b} end
local themes:{[string]:{Color,Color,Color}}={
    Urban={rgb(72,82,96),rgb(40,44,52),rgb(126,138,156)},
    Tactical={rgb(62,74,68),rgb(28,34,30),rgb(142,158,132)},
    Industrial={rgb(112,92,62),rgb(54,48,40),rgb(220,168,72)},
    Neon={rgb(48,66,86),rgb(23,28,40),rgb(58,220,208)},
    Street={rgb(88,66,78),rgb(44,36,46),rgb(230,94,160)},
    Corrupted={rgb(74,48,88),rgb(28,20,34),rgb(160,70,220)},
    Arctic={rgb(152,178,194),rgb(80,102,116),rgb(208,236,248)},
    Desert={rgb(152,116,72),rgb(72,56,40),rgb(228,186,92)},
}
local tiers={"Tier1","Tier2","Tier3","Elite"}
local Definitions={}
function Definitions.themeIds():{string} return {"Urban","Tactical","Industrial","Neon","Street","Corrupted","Arctic","Desert"} end
function Definitions.themeColors(themeId:string,tier:string):({number},{number},{number})
    if tier=="Elite" then return rgb(210,38,52),rgb(74,18,24),rgb(255,112,122) end
    local colors=themes[themeId]
    assert(colors,"unknown theme "..themeId)
    local boost=if tier=="Tier3" then 1.08 elseif tier=="Tier2" then 1.03 else 1
    local p,s,a=colors[1],colors[2],colors[3]
    return {math.clamp(p[1]*boost,0,255),math.clamp(p[2]*boost,0,255),math.clamp(p[3]*boost,0,255)},s,a
end
function Definitions.make(themeId:string,tier:string,index:number):Profile
    assert(themes[themeId],"unknown theme "..themeId)
    assert(table.find(tiers,tier)~=nil,"unknown tier "..tier)
    local p,s,a=Definitions.themeColors(themeId,tier)
    return {ProfileId=("%s_%s_%d"):format(themeId,tier,index),ThemeId=themeId,Tier=tier,PrimaryColor=p,SecondaryColor=s,AccentColor=a,BodyVariant=((index-1)%3)+1,HeadVariant=((index-1)%3)+1,GearVariant=((index-1)%4)+1,AccessoryVariant=((index-1)%3)+1,MaterialVariant=((index-1)%3)+1}
end
return Definitions
