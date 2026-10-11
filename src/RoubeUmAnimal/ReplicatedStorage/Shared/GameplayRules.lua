local Rules = {}

function Rules.IsFinite(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function Rules.Integer(value, minimum, maximum, fallback)
    if not Rules.IsFinite(value) or not Rules.IsFinite(minimum) or not Rules.IsFinite(maximum) or minimum > maximum then
        return fallback
    end
    return math.clamp(math.floor(value), minimum, maximum)
end

function Rules.CanCapture(alreadyCarrying)
    return alreadyCarrying ~= true
end

function Rules.CarrySpeed(baseSpeed, weight, startWeight, penaltyPerWeight, maximumPenalty, minimumSpeed)
    if not Rules.IsFinite(baseSpeed) or not Rules.IsFinite(weight)
        or not Rules.IsFinite(startWeight) or not Rules.IsFinite(penaltyPerWeight)
        or not Rules.IsFinite(maximumPenalty) or not Rules.IsFinite(minimumSpeed)
        or baseSpeed < 0 or weight < 0 or startWeight < 0
        or penaltyPerWeight < 0 or maximumPenalty < 0 or minimumSpeed < 0 then
        return nil
    end
    local penalty = math.clamp(math.max(0, weight - startWeight) * penaltyPerWeight, 0, maximumPenalty)
    return math.max(minimumSpeed, baseSpeed * (1 - penalty)), penalty
end

function Rules.UpgradePrice(statName, data, config)
    if statName ~= "Speed" or type(data) ~= "table" or type(config) ~= "table" then
        return nil
    end
    local upgrades = config.Upgrades
    if type(upgrades) ~= "table" or not Rules.IsFinite(config.CoinsLimit) or config.CoinsLimit < 1 then
        return nil
    end
    local level = Rules.Integer(data.Speed, 0, config.MaxSpeedLevel, 0)
    if level >= config.MaxSpeedLevel then
        return nil
    end
    local baseCost = upgrades.SpeedBaseCost
    local growth = upgrades.SpeedCostGrowth
    if not Rules.IsFinite(baseCost) or baseCost < 1 or not Rules.IsFinite(growth) or growth < 1 then
        return nil
    end
    local value = baseCost * (growth ^ level)
    if not Rules.IsFinite(value) then
        return config.CoinsLimit
    end
    return math.clamp(math.floor(value + 0.0000001), 1, config.CoinsLimit)
end

return Rules
