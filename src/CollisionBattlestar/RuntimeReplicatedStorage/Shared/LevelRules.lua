--!strict

local LevelRules = {}

function LevelRules.scoreForLevel(level: number)
    local safeLevel = math.max(1, math.floor(tonumber(level) or 1))
    local n = safeLevel - 1
    return 250 * n * (n + 1)
end

function LevelRules.levelForScore(score: number)
    local safeScore = math.max(0, math.floor(tonumber(score) or 0))
    local estimate = math.floor(math.sqrt(safeScore / 250 + 0.25))

    while LevelRules.scoreForLevel(estimate + 2) <= safeScore do
        estimate += 1
    end

    while estimate > 0 and LevelRules.scoreForLevel(estimate + 1) > safeScore do
        estimate -= 1
    end

    return math.max(1, estimate + 1)
end

function LevelRules.progress(score: number)
    local level = LevelRules.levelForScore(score)
    local current = LevelRules.scoreForLevel(level)
    local nextScore = LevelRules.scoreForLevel(level + 1)

    return {
        Level = level,
        Current = math.max(0, score - current),
        Required = math.max(1, nextScore - current),
    }
end

return table.freeze(LevelRules)
