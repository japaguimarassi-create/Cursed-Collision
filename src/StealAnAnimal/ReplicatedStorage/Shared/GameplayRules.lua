local Rules = {}

local function finite(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function numberOr(value, fallback)
    local parsed = tonumber(value)
    if not finite(parsed) then
        return fallback
    end
    return parsed
end

function Rules.StageForAge(ageSeconds, config)
    local stages = config and config.EvolutionStages
    if type(stages) ~= "table" or #stages == 0 then
        return nil, 0
    end
    local age = math.max(0, numberOr(ageSeconds, 0))
    local selected = stages[1]
    local index = 1
    for i, stage in ipairs(stages) do
        if age >= stage.AgeSeconds then
            selected = stage
            index = i
        end
    end
    return selected, index
end

function Rules.StageMultiplier(stageIndex, config)
    local stages = config and config.EvolutionStages
    local stageCount = type(stages) == "table" and #stages or 0
    if stageCount == 0 then
        return 1
    end
    local index = math.clamp(math.floor(numberOr(stageIndex, 1)), 1, stageCount)
    local growth = numberOr(config.EvolutionIncomeMultiplier, 1)
    if growth < 1 then
        growth = 1
    end
    local multiplier = growth ^ (index - 1)
    if not finite(multiplier) then
        return 1
    end
    return multiplier
end

function Rules.AnimalIncome(baseIncome, stageIndex, config)
    if not finite(baseIncome) or baseIncome < 0 then
        return 0
    end
    local income = baseIncome * Rules.StageMultiplier(stageIndex, config)
    if not finite(income) then
        return 0
    end
    return math.floor(income)
end

function Rules.CarrySpeed(baseSpeed, weight, config)
    if not finite(baseSpeed) or not finite(weight) or baseSpeed <= 0 or weight < 0 then
        return nil
    end
    local penaltyRate = numberOr(config and config.CarryWeightPenalty, 0)
    local penaltyCap = numberOr(config and config.CarryPenaltyCap, 0)
    local minimumSpeed = numberOr(config and config.CarrySpeedMinimum, 0)
    if penaltyRate < 0 or penaltyCap < 0 or minimumSpeed <= 0 then
        return nil
    end
    local penalty = math.clamp(weight * penaltyRate, 0, penaltyCap)
    local speed = math.max(minimumSpeed, baseSpeed * (1 - penalty))
    if not finite(speed) then
        return nil
    end
    return speed
end

function Rules.UpgradeCost(level, config)
    local current = numberOr(level, -1)
    local maximum = numberOr(config and config.MaxSpeedLevel, -1)
    local base = numberOr(config and config.UpgradeBaseCost, -1)
    local growth = numberOr(config and config.UpgradeCostGrowth, -1)
    if current < 0 or maximum < 0 or base <= 0 or growth < 1 then
        return nil
    end
    current = math.floor(current)
    if current >= maximum then
        return nil
    end
    local cost = base * growth ^ current
    if not finite(cost) or cost <= 0 then
        return nil
    end
    return math.floor(cost)
end

return table.freeze(Rules)
