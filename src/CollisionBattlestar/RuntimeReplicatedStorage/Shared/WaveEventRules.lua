--!strict

local WaveEventRules = {}

function WaveEventRules.pick(wave: number, isBossWave: boolean)
    local safeWave = math.max(1, math.floor(wave))

    if isBossWave then
        return nil
    end

    if safeWave % 15 == 0 then
        return "CreditRush"
    elseif safeWave % 10 == 5 then
        return "Overdrive"
    elseif safeWave % 5 == 0 then
        return "RiftSurge"
    end

    return nil
end

return table.freeze(WaveEventRules)
