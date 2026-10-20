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

function Rules.TrainingGain(level, config)
    local maximum = math.max(1, math.floor(numberOr(config and config.MaxTreadmillLevel, 1)))
    local current = math.clamp(math.floor(numberOr(level, 1)), 1, maximum)
    local baseGain = numberOr(config and config.BaseTrainingGain, 1)
    local growth = numberOr(config and config.TreadmillGainMultiplier, 1)
    if baseGain < 0 or growth < 1 then
        return 0
    end
    local gain = baseGain * growth ^ (current - 1)
    if not finite(gain) then
        return 0
    end
    return math.max(0, math.floor(gain))
end

function Rules.MoveSpeed(speedPoints, config)
    local base = numberOr(config and config.BaseWalkSpeed, 16)
    local maximum = numberOr(config and config.MaxWalkSpeed, base)
    local factor = numberOr(config and config.SpeedPerPointFactor, 0)
    local points = numberOr(speedPoints, 0)
    if points < 0 then
        points = 0
    end
    if factor < 0 or maximum < base then
        return base
    end
    local calculated = base + math.sqrt(points) * factor
    if not finite(calculated) then
        return maximum
    end
    return math.clamp(calculated, base, maximum)
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
    local maximum = numberOr(config and config.MaxTreadmillLevel, -1)
    local base = numberOr(config and config.UpgradeBaseCost, -1)
    local growth = numberOr(config and config.UpgradeCostGrowth, -1)
    if current < 1 or maximum < 1 or base <= 0 or growth < 1 then
        return nil
    end
    current = math.floor(current)
    if current >= maximum then
        return nil
    end
    local cost = base * growth ^ (current - 1)
    if not finite(cost) or cost <= 0 then
        return nil
    end
    return math.floor(cost)
end

function Rules.RebirthCost(rebirths, config)
    local current = numberOr(rebirths, -1)
    local maximum = numberOr(config and config.MaxRebirths, -1)
    local base = numberOr(config and config.RebirthBaseCost, -1)
    local growth = numberOr(config and config.RebirthCostGrowth, -1)
    local coinsLimit = numberOr(config and config.CoinsLimit, 2000000000)
    if current < 0 or maximum < 0 or base <= 0 or growth < 1 or coinsLimit < 1 then
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
    return math.clamp(math.floor(cost), 1, math.floor(coinsLimit))
end

function Rules.RebirthIncomeMultiplier(rebirths, config)
    local maximum = math.max(0, math.floor(numberOr(config and config.MaxRebirths, 0)))
    local count = math.clamp(math.floor(numberOr(rebirths, 0)), 0, maximum)
    local bonus = numberOr(config and config.RebirthIncomeBonus, 0)
    if bonus < 0 then
        return 1
    end
    local multiplier = 1 + count * bonus
    if not finite(multiplier) then
        return 1
    end
    return multiplier
end

return table.freeze(Rules)
