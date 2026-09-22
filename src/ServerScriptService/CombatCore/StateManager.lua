--!strict

local StateManager = {}

export type State = {
    Phase: string,
    Blocking: boolean,
    Combo: number,
    LastM1: number,
    DashUntil: number,
    StunnedUntil: number,
    RecoveryUntil: number,
    Vars: {[string]: any}
}

local DEFAULTS: State = {
    Phase = "Idle",
    Blocking = false,
    Combo = 0,
    LastM1 = 0,
    DashUntil = 0,
    StunnedUntil = 0,
    RecoveryUntil = 0,
    Vars = {}
}

local store = setmetatable({}, {__mode = "k"})

local function fresh(): State
    local state = {} :: any

    for key, value in pairs(DEFAULTS) do
        state[key] = value
    end

    state.Vars = {}
    return state :: State
end

function StateManager:Init(player: Player): State
    local state = fresh()
    store[player] = state
    return state
end

function StateManager:Get(player: Player): State?
    return store[player]
end

function StateManager:Clear(player: Player)
    store[player] = nil
end

function StateManager:Reset(player: Player)
    local state = store[player]

    if not state then
        return
    end

    for key, value in pairs(DEFAULTS) do
        (state :: any)[key] = value
    end

    state.Vars = {}
end

function StateManager:IsStunned(player: Player, now: number): boolean
    local state = store[player]
    return state ~= nil and state.StunnedUntil > now
end

function StateManager:IsDashing(player: Player, now: number): boolean
    local state = store[player]
    return state ~= nil and state.DashUntil > now
end

function StateManager:SetStun(player: Player, duration: number, now: number)
    local state = store[player]

    if not state then
        return
    end

    state.StunnedUntil = math.max(
        state.StunnedUntil,
        now + math.max(0, duration)
    )

    state.Phase = "HitReact"
    player:SetAttribute("CombatStunned", true)
end

function StateManager:ClearStunWhenReady(player: Player, now: number)
    local state = store[player]

    if not state or state.StunnedUntil > now then
        return
    end

    state.StunnedUntil = 0

    if not state.Blocking then
        state.Phase = "Idle"
    end

    player:SetAttribute("CombatStunned", false)
end

return StateManager