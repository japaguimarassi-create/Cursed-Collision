--!strict

local Rules = {}

function Rules.enemyCount(wave: number): number
    if wave <= 0 then
        return 0
    end
    return math.min(20, 6 + math.max(0, wave - 1) * 2)
end

function Rules.hasElite(wave: number): boolean
    return wave > 0
end

function Rules.waveReward(wave: number): number
    return math.max(0, wave) * 25
end

function Rules.normalTier(wave: number, index: number): string
    if wave <= 2 then
        return "Tier1"
    end
    if wave <= 4 then
        return index % 4 == 0 and "Tier2" or "Tier1"
    end
    if wave <= 7 then
        return index % 3 == 0 and "Tier2" or "Tier1"
    end
    return index % 3 == 0 and "Tier3" or (index % 2 == 0 and "Tier2" or "Tier1")
end

return Rules