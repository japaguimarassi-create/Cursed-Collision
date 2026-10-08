--!strict

local PvPRules = {}

function PvPRules.canJoin(currentlyInPvP: boolean)
    return currentlyInPvP ~= true
end

function PvPRules.canLeave(currentlyInPvP: boolean)
    return currentlyInPvP == true
end

function PvPRules.canDamage(attackerUserId: any, targetUserId: any)
    return type(attackerUserId) == "number"
        and type(targetUserId) == "number"
        and attackerUserId > 0
        and targetUserId > 0
        and attackerUserId ~= targetUserId
end

return table.freeze(PvPRules)
