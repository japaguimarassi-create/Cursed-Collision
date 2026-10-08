--!strict

local WaveEventRules = {}

function WaveEventRules.pick(wave: number, isBossWave: boolean)
    local safeWave = math.max(1, math.floor(wave))

    if isBossWave then
        return nil
    end

    if safeWave % 20 == 5 then
        return "RiftSurge"
    elseif safeWave % 20 == 15 then
        return "CreditRush"
    elseif safeWave % 20 == 0 then
        return nil
    elseif safeWave % 10 == 5 then
        return "Overdrive"
    end

    return nil
end

return table.freeze(WaveEventRules)
