local Rules = {}

local stages = { "Baby", "Child", "Teen", "Adult" }

function Rules.StageForAge(ageSeconds, config)
    local age = math.max(0, tonumber(ageSeconds) or 0)
    local selected = config.EvolutionStages[1]
    local index = 1
    for i, stage in ipairs(config.EvolutionStages) do
        if age >= stage.AgeSeconds then
            selected = stage
            index = i
        end
    end
    return selected, index
end

function Rules.StageMultiplier(stageIndex, config)
    local index = math.clamp(math.floor(tonumber(stageIndex) or 1), 1, #stages)
    return config.EvolutionIncomeMultiplier ^ (index - 1)
end

function Rules.AnimalIncome(baseIncome, stageIndex, config)
    if type(baseIncome) ~= "number" or baseIncome < 0 or baseIncome ~= baseIncome then
        return 0
    end
    return math.floor(baseIncome * Rules.StageMultiplier(stageIndex, config))
end

function Rules.CarrySpeed(baseSpeed, weight, config)
    if type(baseSpeed) ~= "number" or type(weight) ~= "number" or weight < 0 then
        return nil
    end
    local penalty = math.clamp(weight * config.CarryWeightPenalty, 0, config.CarryPenaltyCap)
    return math.max(config.CarrySpeedMinimum, baseSpeed * (1 - penalty))
end

function Rules.UpgradeCost(level, config)
    local current = math.max(0, math.floor(tonumber(level) or 0))
    if current >= config.MaxSpeedLevel then
        return nil
    end
    return math.floor(config.UpgradeBaseCost * config.UpgradeCostGrowth ^ current)
end

return table.freeze(Rules)
