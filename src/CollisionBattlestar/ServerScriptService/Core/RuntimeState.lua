--!strict

local RuntimeState = {}
RuntimeState.__index = RuntimeState

function RuntimeState.new()
    local changed = Instance.new("BindableEvent")

    return setmetatable({
        changed = changed,
        worldReady = false,
        phase = "Booting",
        wave = 0,
        enemiesAlive = 0,
        eliteAlive = false,
        bossId = nil,
        eventId = nil,
        intermissionEndsAt = 0,
    }, RuntimeState)
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
    local changed = false

    for name, value in pairs(values) do
        if self[name] ~= value then
            self[name] = value
            changed = true
        end
    end

    if changed then
        self.changed:Fire("Batch")
    end

    return changed
end

function RuntimeState:Snapshot()
    return {
        worldReady = self.worldReady,
        phase = self.phase,
        wave = self.wave,
        enemiesAlive = self.enemiesAlive,
        eliteAlive = self.eliteAlive,
        bossId = self.bossId,
        eventId = self.eventId,
        intermissionEndsAt = self.intermissionEndsAt,
    }
end

function RuntimeState:Destroy()
    self.changed:Destroy()
end

return RuntimeState
