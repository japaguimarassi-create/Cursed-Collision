--!strict

local WaveEventRules = {}

function WaveEventRules.pick(wave: number, isBossWave: boolean)
    local safeWave = math.max(1, math.floor(wave))

    if isBossWave then
        return nil
    end

    local cycle = ((safeWave - 1) % 30) + 1

    if cycle == 5 then
        return "RiftSurge"
    elseif cycle == 15 then
        return "CreditRush"
    elseif cycle == 25 then
        return "Overdrive"
    end

    return nil
end

return table.freeze(WaveEventRules)
