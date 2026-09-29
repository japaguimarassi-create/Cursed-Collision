--!strict

local Rules = {}

function Rules.validAction(action: string): boolean
    return action == "M1" or action == "Dash"
end

function Rules.validTarget(kind: string, isPvP: boolean): boolean
    if kind == "Enemy" then
        return not isPvP
    end
    if kind == "Player" then
        return isPvP
    end
    return false
end

function Rules.validRange(distance: number, maxRange: number): boolean
    return distance <= maxRange and distance >= 0
end

function Rules.validLineOfSight(blocked: boolean): boolean
    return not blocked
end

function Rules.validZone(zone: string): boolean
    return zone == "PvE" or zone == "PvP"
end

function Rules.validRequest(action: string, ready: boolean, alive: boolean, zone: string): boolean
    return ready and alive and Rules.validAction(action) and Rules.validZone(zone)
end

return Rules