--!strict

local Rules = {}

function Rules.canAttack(now: number, lastAttackAt: number, minInterval: number): boolean
    return now - lastAttackAt >= minInterval
end

function Rules.nextCombo(previous: number, elapsed: number, window: number): number
    if elapsed > window then
        return 1
    end
    return previous % 3 + 1
end

function Rules.canDash(now: number, lastDashAt: number, cooldown: number): boolean
    return now - lastDashAt >= cooldown
end

function Rules.normalizeDirection(x: number, z: number): {x: number, z: number}
    local magnitude = math.sqrt(x * x + z * z)
    if magnitude < 0.1 then
        return {x = 0, z = 1}
    end
    return {x = x / magnitude, z = z / magnitude}
end

return Rules