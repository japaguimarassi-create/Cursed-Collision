--!strict

local names={
    "Health","Credits","Wave","Enemies","Elite","Phase","M1","Dash",
    "Menu","Shop","Companion","Notifications","Onboarding","TestLab",
}

local Contract={}
function Contract.required(name:string):boolean
    for _,value in ipairs(names) do if value==name then return true end end
    return false
end
function Contract.count():number return #names end
function Contract.all():{string} return table.clone(names) end
return Contract
