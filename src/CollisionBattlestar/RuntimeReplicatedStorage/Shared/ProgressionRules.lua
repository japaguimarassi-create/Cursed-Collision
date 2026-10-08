--!strict

local ProgressionRules = {}

local DEFINITIONS = {
    Damage = {MaxLevel = 25, BaseCost = 75, Growth = 1.45},
    MaxHealth = {MaxLevel = 20, BaseCost = 90, Growth = 1.5},
    Dash = {MaxLevel = 15, BaseCost = 110, Growth = 1.5},
    Critical = {MaxLevel = 15, BaseCost = 150, Growth = 1.6},
    Recovery = {MaxLevel = 15, BaseCost = 100, Growth = 1.5},
}

function ProgressionRules.isValidUpgrade(upgradeId: any)
    return type(upgradeId) == "string" and DEFINITIONS[upgradeId] ~= nil
end

function ProgressionRules.getDefinition(upgradeId: string)
    return DEFINITIONS[upgradeId]
end

function ProgressionRules.getCost(upgradeId: string, currentLevel: number)
    local definition = DEFINITIONS[upgradeId]
    if not definition then
        return math.huge
    end

    local level = math.max(0, math.floor(currentLevel))
    if level >= definition.MaxLevel then
        return math.huge
    end

    return math.floor(definition.BaseCost * definition.Growth ^ level)
end

function ProgressionRules.getMaxLevel(upgradeId: string)
    local definition = DEFINITIONS[upgradeId]
    return definition and definition.MaxLevel or 0
end

function ProgressionRules.damageMultiplier(level: number)
    return 1 + math.clamp(math.floor(level), 0, 25) * 0.05
end

function ProgressionRules.maxHealthBonus(level: number)
    return math.clamp(math.floor(level), 0, 20) * 15
end

function ProgressionRules.dashCooldownMultiplier(level: number)
    return 1 - math.clamp(math.floor(level), 0, 15) * 0.04
end

function ProgressionRules.criticalChance(level: number)
    return math.clamp(math.floor(level), 0, 15) * 0.02
end

function ProgressionRules.recoveryBonus(level: number)
    return math.clamp(math.floor(level), 0, 15) * 0.5
end

return table.freeze(ProgressionRules)
