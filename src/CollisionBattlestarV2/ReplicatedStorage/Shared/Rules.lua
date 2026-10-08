--!strict

local Rules = {}

function Rules.combo(previous: number, elapsed: number)
    if elapsed > 0.9 or previous >= 3 or previous < 1 then
        return 1
    end
    return previous + 1
end

function Rules.comboMultiplier(step: number)
    return ({1, 1.1, 1.25})[step] or 1
end

function Rules.levelForScore(score: number)
    local safe = math.max(0, math.floor(tonumber(score) or 0))
    local level = 1
    while level < 100 and safe >= Rules.scoreForLevel(level + 1) do
        level += 1
    end
    return level
end

function Rules.scoreForLevel(level: number)
    local safe = math.max(1, math.floor(tonumber(level) or 1))
    local n = safe - 1
    return 250 * n * (n + 1)
end

function Rules.levelProgress(score: number)
    local safe = math.max(0, math.floor(tonumber(score) or 0))
    local level = Rules.levelForScore(safe)
    local current = Rules.scoreForLevel(level)
    local nextScore = Rules.scoreForLevel(level + 1)
    return level, safe - current, math.max(1, nextScore - current)
end

function Rules.waveProfile(wave: number)
    local w = math.max(1, math.floor(tonumber(wave) or 1))
    local total = math.min(15, 5 + math.floor(w * 0.75))
    local elite = math.min(1, math.floor(w / 3))
    local boss = w % 10 == 0
    if boss then
        total = math.max(1, total - 1)
    end

    return {
        Total = total,
        Elite = elite,
        Boss = boss,
    }
end

function Rules.aiProfile(wave: number)
    local w = math.max(0, math.floor(tonumber(wave) or 0))
    local skill = math.clamp(0.25 + w * 0.018, 0.25, 0.82)
    return {
        Skill = skill,
        ThinkInterval = math.max(0.16, 0.28 - math.min(0.12, w * 0.0025)),
        Prediction = math.min(0.35, 0.05 + w * 0.004),
        Stickiness = math.min(0.36, 0.08 + w * 0.012),
    }
end

return table.freeze(Rules)
