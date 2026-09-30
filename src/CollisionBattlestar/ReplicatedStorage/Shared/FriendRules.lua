--!strict
local Rules={}
function Rules.isEligible(requestingUserId:number,friendUserId:number,friendIds:{number}):boolean
    if requestingUserId<=0 or friendUserId<=0 or requestingUserId==friendUserId then return false end
    for _,id in ipairs(friendIds) do if id==friendUserId then return true end end
    return false
end
function Rules.classIsValid(classId:string):boolean
    return classId=="Vanguard" or classId=="Striker" or classId=="Guardian" or classId=="Support"
end
return table.freeze(Rules)
