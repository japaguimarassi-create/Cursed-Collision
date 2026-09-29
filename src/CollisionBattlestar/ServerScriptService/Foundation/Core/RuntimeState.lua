--!strict

local State = {}
State.__index = State

function State.new()
    return setmetatable({
        Wave = 0,
        Phase = "Waiting",
        ActiveEnemies = 0,
        ElitePresent = false,
    }, State)
end

function State:Set(wave: number, phase: string, activeEnemies: number, elitePresent: boolean)
    self.Wave = wave
    self.Phase = phase
    self.ActiveEnemies = math.max(0, activeEnemies)
    self.ElitePresent = elitePresent
end

function State:Snapshot()
    return {
        Wave = self.Wave,
        Phase = self.Phase,
        ActiveEnemies = self.ActiveEnemies,
        ElitePresent = self.ElitePresent,
    }
end

return State