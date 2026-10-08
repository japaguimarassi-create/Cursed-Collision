--!strict

local RuntimeState = {}
RuntimeState.__index = RuntimeState

function RuntimeState.new()
    local changed = Instance.new("BindableEvent")

    local self = setmetatable({
        changed = changed,
        worldReady = false,
        phase = "Booting",
        wave = 0,
        enemiesAlive = 0,
        eliteAlive = false,
        intermissionEndsAt = 0,
    }, RuntimeState)

    return self
end

function RuntimeState:GetChangedEvent()
    return self.changed.Event
end

function RuntimeState:Set(name: string, value: any)
    if self[name] == value then
        return false
    end

    self[name] = value
    self.changed:Fire(name, value)
    return true
end

function RuntimeState:SetMany(values: {[string]: any})
    for name, value in pairs(values) do
        self:Set(name, value)
    end
end

function RuntimeState:Snapshot()
    return {
        worldReady = self.worldReady,
        phase = self.phase,
        wave = self.wave,
        enemiesAlive = self.enemiesAlive,
        eliteAlive = self.eliteAlive,
        intermissionEndsAt = self.intermissionEndsAt,
    }
end

function RuntimeState:Destroy()
    self.changed:Destroy()
end

return RuntimeState
