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

function Rules.CanCapture(currentStrength, requiredStrength, alreadyCarrying)
    return alreadyCarrying ~= true
        and Rules.IsFinite(currentStrength)
        and Rules.IsFinite(requiredStrength)
        and currentStrength >= requiredStrength
end

function Rules.CarrySpeed(baseSpeed, weight, strength, startRatio, penaltyPerRatio, minimumSpeed)
    if not Rules.IsFinite(baseSpeed) or not Rules.IsFinite(weight) or not Rules.IsFinite(strength)
        or not Rules.IsFinite(startRatio) or not Rules.IsFinite(penaltyPerRatio) or not Rules.IsFinite(minimumSpeed)
        or baseSpeed < 0 or weight < 0 or strength < 1 or startRatio < 0 or penaltyPerRatio < 0 or minimumSpeed < 0 then
        return nil
    end
    local ratio = weight / math.max(strength, 1)
    local penalty = math.clamp((ratio - startRatio) * penaltyPerRatio, 0, 0.78)
    return math.max(minimumSpeed, baseSpeed * (1 - penalty)), penalty
end

function Rules.SalePrice(baseValue, rarityMultiplier, hasDoubleCoins, coinLimit)
    if not Rules.IsFinite(baseValue) or not Rules.IsFinite(rarityMultiplier) or not Rules.IsFinite(coinLimit)
        or baseValue < 0 or rarityMultiplier <= 0 or coinLimit < 0 then
        return nil
    end
    local value = baseValue * rarityMultiplier
    if hasDoubleCoins == true then
        value *= 2
    end
    if not Rules.IsFinite(value) then
        return coinLimit
    end
    return math.clamp(math.floor(value), 0, coinLimit)
end

function Rules.UpgradePrice(statName, data, config)
    if type(statName) ~= "string" or type(data) ~= "table" or type(config) ~= "table" then
        return nil
    end
    local upgrades = config.Upgrades
    if type(upgrades) ~= "table" or not Rules.IsFinite(config.CoinsLimit) or config.CoinsLimit < 1 then
        return nil
    end

    local level
    local baseCost
    local growth
    local exponent
    if statName == "Speed" then
        level = Rules.Integer(data.Speed, 0, config.MaxSpeedLevel, 0)
        if level >= config.MaxSpeedLevel then
            return nil
        end
        baseCost = upgrades.SpeedBaseCost
        growth = upgrades.SpeedCostGrowth
        exponent = level
    elseif statName == "Strength" then
        level = Rules.Integer(data.Strength, 1, config.MaxStrength, 10)
        if level >= config.MaxStrength then
            return nil
        end
        baseCost = upgrades.StrengthBaseCost
        growth = upgrades.StrengthCostGrowth
        local start = upgrades.StrengthCostStart or 10
        local step = upgrades.StrengthCostStep or 5
        if not Rules.IsFinite(start) or not Rules.IsFinite(step) or step < 1 then
            return nil
        end
        exponent = math.max(0, math.floor((level - start) / step))
    else
        return nil
    end

    if not Rules.IsFinite(baseCost) or baseCost < 1 or not Rules.IsFinite(growth) or growth < 1 then
        return nil
    end
    local value = baseCost * (growth ^ exponent)
    if not Rules.IsFinite(value) then
        return config.CoinsLimit
    end
    return math.clamp(math.floor(value + 0.0000001), 1, config.CoinsLimit)
end

return Rules
