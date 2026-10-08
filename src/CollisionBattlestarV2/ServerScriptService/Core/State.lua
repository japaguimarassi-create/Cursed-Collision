--!strict

local State = {}
State.__index = State

function State.new()
    return setmetatable({
        phase = "Booting",
        wave = 0,
        enemiesAlive = 0,
        boss = false,
        event = nil,
        generation = 0,
        lastCompletedWave = 0,
        intermissionEndsAt = 0,
        error = nil,
        changed = Instance.new("BindableEvent"),
    }, State)
end

function State:Set(key: string, value: any)
    if self[key] == value then
        return
    end
    self[key] = value
    self.changed:Fire(key, value)
end

function State:SetMany(values: {[string]: any})
    for key, value in pairs(values) do
        self[key] = value
    end
    self.changed:Fire("*", self:Snapshot())
end

function State:Snapshot()
    return {
        phase = self.phase,
        wave = self.wave,
        enemiesAlive = self.enemiesAlive,
        boss = self.boss,
        event = self.event,
        generation = self.generation,
        lastCompletedWave = self.lastCompletedWave,
        intermissionEndsAt = self.intermissionEndsAt,
        error = self.error,
    }
end

function State:Changed()
    return self.changed.Event
end

return State
