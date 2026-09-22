--!strict

local CooldownService = {}
CooldownService.__index = CooldownService

local store = setmetatable({}, {__mode = "k"})

function CooldownService:_get(player: Player)
    local bucket = store[player]
    if not bucket then
        bucket = {}
        store[player] = bucket
    end
    return bucket
end

function CooldownService:Ready(player: Player, action: string, now: number?): boolean
    local bucket = store[player]
    local readyAt = bucket and bucket[action]
    return readyAt == nil or readyAt <= (now or os.clock())
end

function CooldownService:Set(player: Player, action: string, duration: number, now: number?)
    local bucket = self:_get(player)
    bucket[action] = (now or os.clock()) + math.max(0, duration)
end

function CooldownService:Remaining(player: Player, action: string, now: number?): number
    local bucket = store[player]
    local readyAt = bucket and bucket[action]
    return if readyAt then math.max(0, readyAt - (now or os.clock())) else 0
end

function CooldownService:Clear(player: Player)
    store[player] = nil
end

return CooldownService
