--!strict
local Rules={}
function Rules.defaultProfile()
    return {Version=2,Credits=0,DamageLevel=0,XP=0,TotalKills=0,HighestWave=0,OwnedItems={Echo_Vanguard=true},EquippedSkin="Default",EquippedEcho="Echo_Vanguard"}
end
function Rules.validate(profile):boolean
    if type(profile)~="table" or profile.Version~=2 then return false end
    for _,key in ipairs({"Credits","DamageLevel","XP","TotalKills","HighestWave"}) do if type(profile[key])~="number" or profile[key]<0 then return false end end
    if type(profile.OwnedItems)~="table" or type(profile.EquippedSkin)~="string" or type(profile.EquippedEcho)~="string" then return false end
    for itemId,owned in pairs(profile.OwnedItems) do if type(itemId)~="string" or type(owned)~="boolean" then return false end end
    return true
end
function Rules.migrate(raw)
    if type(raw)~="table" then return Rules.defaultProfile() end
    local p=Rules.defaultProfile()
    p.Credits=math.max(0,tonumber(raw.Credits) or 0)
    p.DamageLevel=math.max(0,tonumber(raw.DamageLevel) or 0)
    p.XP=math.max(0,tonumber(raw.XP) or 0)
    p.TotalKills=math.max(0,tonumber(raw.TotalKills) or 0)
    p.HighestWave=math.max(0,tonumber(raw.HighestWave) or 0)
    if type(raw.OwnedItems)=="table" then
        p.OwnedItems={}
        for itemId,owned in pairs(raw.OwnedItems) do if type(itemId)=="string" and owned==true then p.OwnedItems[itemId]=true end end
    end
    if type(raw.EquippedSkin)=="string" then p.EquippedSkin=raw.EquippedSkin end
    if type(raw.EquippedEcho)=="string" and p.OwnedItems[raw.EquippedEcho]==true then p.EquippedEcho=raw.EquippedEcho else p.EquippedEcho="None" end
    return p
end
return table.freeze(Rules)
