--!strict

local Rules = {}

function Rules.upgradeCost(level: number): number
    return math.floor(50 * (2 ^ math.max(0, level)))
end

function Rules.upgradeDamage(level: number): number
    return math.max(0, level) * 5
end

function Rules.canBuy(credits: number, cost: number): boolean
    return credits >= cost
end

return Rules