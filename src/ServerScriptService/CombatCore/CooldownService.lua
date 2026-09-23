--!strict

local CooldownService = {}
CooldownService.__index = CooldownService

local store: {[Player]: {[string]: number}} = setmetatable({}, {__mode = "k"}) :: any

local function attrName(action: string): string
    return "CooldownUntil_" .. action
end

function CooldownService:_get(player: Player): {[string]: number}
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
    local t = now or os.clock()
    local readyAt = t + math.max(0, duration)
    self:_get(player)[action] = readyAt
    -- Atributo usa tempo sincronizado; a store interna continua usando os.clock() no servidor.\n    player:SetAttribute(attrName(action), workspace:GetServerTimeNow() + math.max(0, duration))
end

function CooldownService:Remaining(player: Player, action: string, now: number?): number
    local bucket = store[player]
    local readyAt = bucket and bucket[action]
    return if readyAt then math.max(0, readyAt - (now or os.clock())) else 0
end

function CooldownService:Clear(player: Player)
    store[player] = nil
    for _, action in ipairs({"M1", "Dash", "Special", "Skill1", "Skill2", "Skill3", "Skill4"}) do
        player:SetAttribute(attrName(action), 0)
    end
end

return CooldownService
