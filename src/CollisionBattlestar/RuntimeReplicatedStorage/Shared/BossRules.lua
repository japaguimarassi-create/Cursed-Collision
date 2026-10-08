--!strict

local BossRules = {}

function BossRules.getForWave(wave: number, definitions)
    local safeWave = math.max(1, math.floor(wave))

    if type(definitions) ~= "table" then
        return nil
    end

    if safeWave % 20 == 0 and definitions.CollisionWarden then
        return definitions.CollisionWarden
    end

    if safeWave % 10 == 0 and definitions.RiftTitan then
        return definitions.RiftTitan
    end

    return nil
end

function BossRules.scale(baseValue: number, multiplier: number)
    return baseValue * math.max(0, multiplier)
end

return table.freeze(BossRules)
