--!strict

local StateManager = {}
StateManager.__index = StateManager

export type State = {
    Phase: string,
    StunnedUntil: number,
    RecoveryUntil: number,
    Blocking: boolean,
    Dodging: boolean,
    DodgeUntil: number,
    CounterUntil: number,
    PerfectBlockUntil: number,
    Combo: number,
    LastM1: number,
    Momentum: number,
    Clash: boolean,
    Domain: boolean,
    Awakening: boolean,
    BlackFlashWindow: number?,
}

local DEFAULTS: State = {
    Phase = "Idle",
    StunnedUntil = 0,
    RecoveryUntil = 0,
    Blocking = false,
    Dodging = false,
    DodgeUntil = 0,
    CounterUntil = 0,
    PerfectBlockUntil = 0,
    Combo = 0,
    LastM1 = 0,
    Momentum = 0,
    Clash = false,
    Domain = false,
    Awakening = false,
    BlackFlashWindow = nil,
}

local store = setmetatable({}, {__mode = "k"})

local function cloneDefaults(): State
    local result = {}
    for key, value in pairs(DEFAULTS) do
        result[key] = value
    end
    return result :: State
end

function StateManager:Get(player: Player): State?
    return store[player]
end

function StateManager:Init(player: Player): State
    local state = cloneDefaults()
    store[player] = state
    return state
end

function StateManager:Clear(player: Player)
    store[player] = nil
end

function StateManager:Set(player: Player, key: string, value: any)
    local state = store[player]
    if state then
        (state :: any)[key] = value
    end
end

function StateManager:GetValue(player: Player, key: string, fallback: any): any
    local state = store[player]
    if not state then
        return fallback
    end
    local value = (state :: any)[key]
    return if value == nil then fallback else value
end

function StateManager:ResetCombat(player: Player)
    local state = store[player]
    if not state then
        return
    end
    for key, value in pairs(DEFAULTS) do
        (state :: any)[key] = value
    end
end

function StateManager:TimeLeft(player: Player, key: string, now: number): number
    local value = self:GetValue(player, key, 0)
    if type(value) ~= "number" then
        return 0
    end
    return math.max(0, value - now)
end

return StateManager
