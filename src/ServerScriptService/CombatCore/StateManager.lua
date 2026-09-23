--!strict

local StateManager = {}

export type Phase =
    "Idle" | "Running" | "Jumping" | "Falling" | "Attacking" | "Blocking" | "Stunned"
    | "Ragdolled" | "Dashing" | "UsingAbility" | "Ultimate" | "Awakening" | "Dead"

export type State = {
    Phase: Phase,
    Blocking: boolean,
    Combo: number,
    LastM1: number,
    LastAction: string,
    DashUntil: number,
    StunnedUntil: number,
    RecoveryUntil: number,
    InvulnerableUntil: number,
    PerfectBlockUntil: number,
    RagdollUntil: number,
    AbilityToken: number,
    Vars: {[string]: any}
}

local store: {[Player]: State} = {} :: any

local allowed: {[Phase]: {[Phase]: boolean}} = {
    Idle = {Idle=true, Running=true, Jumping=true, Falling=true, Attacking=true, Blocking=true, Dashing=true, UsingAbility=true, Ultimate=true, Awakening=true, Stunned=true, Dead=true},
    Running = {Idle=true, Running=true, Jumping=true, Falling=true, Attacking=true, Blocking=true, Dashing=true, UsingAbility=true, Stunned=true, Dead=true},
    Jumping = {Jumping=true, Falling=true, Attacking=true, Dashing=true, UsingAbility=true, Stunned=true, Dead=true},
    Falling = {Falling=true, Idle=true, Jumping=true, Attacking=true, Dashing=true, UsingAbility=true, Stunned=true, Dead=true},
    Attacking = {Attacking=true, Idle=true, Blocking=true, Dashing=true, UsingAbility=true, Stunned=true, Ragdolled=true, Ultimate=true, Awakening=true, Dead=true},
    Blocking = {Blocking=true, Idle=true, Attacking=true, Stunned=true, Ragdolled=true, Dead=true},
    Stunned = {Stunned=true, Idle=true, Falling=true, Ragdolled=true, Dead=true},
    Ragdolled = {Ragdolled=true, Idle=true, Falling=true, Dead=true},
    Dashing = {Dashing=true, Idle=true, Attacking=true, UsingAbility=true, Stunned=true, Ragdolled=true, Dead=true},
    UsingAbility = {UsingAbility=true, Idle=true, Attacking=true, Blocking=true, Stunned=true, Ragdolled=true, Ultimate=true, Awakening=true, Dead=true},
    Ultimate = {Ultimate=true, UsingAbility=true, Attacking=true, Idle=true, Stunned=true, Dead=true},
    Awakening = {Awakening=true, UsingAbility=true, Attacking=true, Idle=true, Stunned=true, Dead=true},
    Dead = {Dead=true}
}

local function fresh(): State
    return {
        Phase="Idle", Blocking=false, Combo=0, LastM1=0, LastAction="",
        DashUntil=0, StunnedUntil=0, RecoveryUntil=0, InvulnerableUntil=0,
        PerfectBlockUntil=0, RagdollUntil=0, AbilityToken=0, Vars={}
    }
end

function StateManager:Init(player: Player): State
    local state = fresh()
    store[player] = state
    self:Sync(player)
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
    if not state then return end
    store[player] = fresh()
    self:Sync(player)
end

function StateManager:Sync(player: Player)
    local state = store[player]
    if not state then return end
    local now = os.clock()
    player:SetAttribute("CombatState", state.Phase)
    player:SetAttribute("Blocking", state.Blocking)
    player:SetAttribute("CombatStunned", state.StunnedUntil > now)
    player:SetAttribute("Invulnerable", state.InvulnerableUntil > now)
    player:SetAttribute("Ragdolled", state.RagdollUntil > now)
    player:SetAttribute("PerfectBlockWindow", math.max(0, state.PerfectBlockUntil - now))
end

function StateManager:SetPhase(player: Player, phase: Phase): boolean
    local state = store[player]
    if not state or not allowed[state.Phase][phase] then return false end
    state.Phase = phase
    self:Sync(player)
    return true
end

function StateManager:CanAct(player: Player, now: number): boolean
    local state = store[player]
    return state ~= nil
        and state.Phase ~= "Dead"
        and state.Phase ~= "Ragdolled"
        and state.Phase ~= "Stunned"
        and state.StunnedUntil <= now
        and state.RagdollUntil <= now
end

function StateManager:SetStun(player: Player, duration: number, now: number)
    local state = store[player]
    if not state then return end
    state.StunnedUntil = math.max(state.StunnedUntil, now + math.max(0, duration))
    state.AbilityToken += 1
    state.PerfectBlockUntil = 0
    state.Blocking = false
    self:SetPhase(player, "Stunned")
end

function StateManager:SetInvulnerable(player: Player, duration: number, now: number)
    local state = store[player]
    if not state then return end
    state.InvulnerableUntil = math.max(state.InvulnerableUntil, now + math.max(0, duration))
    self:Sync(player)
end

function StateManager:BeginBlock(player: Player, perfectWindow: number, now: number): boolean
    local state = store[player]
    if not state or not self:CanAct(player, now) then return false end
    state.Blocking = true
    state.PerfectBlockUntil = now + math.max(0, perfectWindow)
    return self:SetPhase(player, "Blocking")
end

function StateManager:EndBlock(player: Player)
    local state = store[player]
    if not state then return end
    state.Blocking = false
    state.PerfectBlockUntil = 0
    if state.StunnedUntil <= os.clock() then
        self:SetPhase(player, "Idle")
    end
end

function StateManager:BeginAbility(player: Player, action: string, now: number): number?
    local state = store[player]
    if not state or not self:CanAct(player, now) then return nil end
    state.AbilityToken += 1
    state.LastAction = action
    state.Blocking = false
    if not self:SetPhase(player, "UsingAbility") then return nil end
    return state.AbilityToken
end

function StateManager:IsAbilityValid(player: Player, token: number): boolean
    local state = store[player]
    return state ~= nil
        and state.AbilityToken == token
        and state.StunnedUntil <= os.clock()
        and state.RagdollUntil <= os.clock()
        and state.Phase ~= "Dead"
end

function StateManager:BeginRagdoll(player: Player, duration: number, now: number)
    local state = store[player]
    if not state then return end
    state.RagdollUntil = math.max(state.RagdollUntil, now + math.max(0, duration))
    state.AbilityToken += 1
    state.Blocking = false
    state.PerfectBlockUntil = 0
    self:SetPhase(player, "Ragdolled")
end

function StateManager:IsStunned(player: Player, now: number): boolean
    local state = store[player]
    return state ~= nil and state.StunnedUntil > now
end

function StateManager:IsDashing(player: Player, now: number): boolean
    local state = store[player]
    return state ~= nil and state.DashUntil > now
end

function StateManager:ClearStunWhenReady(player: Player, now: number)
    local state = store[player]
    if not state then return end

    if state.StunnedUntil <= now then
        state.StunnedUntil = 0
        if state.Phase == "Stunned" then self:SetPhase(player, "Idle") end
    end

    if state.RagdollUntil <= now then
        state.RagdollUntil = 0
        if state.Phase == "Ragdolled" then self:SetPhase(player, "Idle") end
    end

    self:Sync(player)
end

return StateManager
