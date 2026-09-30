--!strict

local Rules={}
local allowed={
    Session=true,Wave=true,Combat=true,Economy=true,Upgrade=true,
    Shop=true,Companion=true,Social=true,Event=true,Progression=true,
}

function Rules.isAllowedEvent(name:string):boolean return allowed[name]==true end

function Rules.normalize(name:string,fields):{Name:string,Fields:{string}}
    assert(allowed[name],"analytics event is not allowed")
    local result={Name=name,Fields={}}
    for _,key in ipairs({"action","wave","tier","result","itemId","classId","reason"}) do
        if fields[key]~=nil and #result.Fields<3 then
            table.insert(result.Fields,tostring(fields[key]))
        end
    end
    return result
end

return table.freeze(Rules)
