--!strict

local CombatStateMachine = {}
CombatStateMachine.__index = CombatStateMachine

export type State = "Idle" | "Attack" | "Skill" | "Awakening" | "Domain" | "HitReact" | "Dash" | "Block" | "Recovery"

export type Record = {
    state: State,
    token: number,
    startedAt: number,
}

export type Machine = {
    _states: {[Model]: Record},
    _clock: () -> number,
}

local transitions: {[State]: {[State]: boolean}} = {
    Idle = {Attack=true, Skill=true, Awakening=true, Domain=true, HitReact=true, Dash=true, Block=true},
    Attack = {Idle=true, Attack=true, Skill=true, HitReact=true, Dash=true, Recovery=true},
    Skill = {Idle=true, Attack=true, Skill=true, HitReact=true, Domain=true, Recovery=true},
    Awakening = {Idle=true, Skill=true, HitReact=true, Recovery=true},
    Domain = {Idle=true, Skill=true, HitReact=true, Recovery=true},
    HitReact = {Idle=true, Attack=true, Skill=true, Dash=true, Recovery=true},
    Dash = {Idle=true, Attack=true, Skill=true, HitReact=true, Recovery=true},
    Block = {Idle=true, HitReact=true, Recovery=true},
    Recovery = {Idle=true, Attack=true, Skill=true, HitReact=true, Dash=true},
}

function CombatStateMachine.new(clock: (() -> number)?): Machine
    local stateStore: {[Model]: Record} = setmetatable({}, {__mode = "k"})
    local self = setmetatable({
        _states = stateStore,
        _clock = clock or os.clock,
    }, CombatStateMachine)

    return self :: Machine
end

function CombatStateMachine:Get(character: Model): Record?
    return self._states[character]
end

function CombatStateMachine:GetState(character: Model): State
    local record = self._states[character]
    return record and record.state or "Idle"
end

function CombatStateMachine:Begin(character: Model, state: State, force: boolean?): number?
    if not character or not character.Parent then
        return nil
    end

    local previous = self._states[character]
    if previous and previous.state ~= state and not force then
        local allowed = transitions[previous.state]
        if not allowed or not allowed[state] then
            return nil
        end
    end

    local token = (previous and previous.token or 0) + 1
    self._states[character] = {
        state = state,
        token = token,
        startedAt = self._clock(),
    }

    return token
end

function CombatStateMachine:IsCurrent(character: Model, token: number): boolean
    local record = self._states[character]
    return character.Parent ~= nil and record ~= nil and record.token == token
end

function CombatStateMachine:Finish(character: Model, token: number, nextState: State?): boolean
    local record: Record? = self._states[character]
    if not record or record.token ~= token then
        return false
    end

    local state = nextState or "Idle"
    self._states[character] = {
        state = state,
        token = record.token + 1,
        startedAt = self._clock(),
    }
    return true
end

function CombatStateMachine:Cancel(character: Model): number?
    local record: Record? = self._states[character]
    if not record then
        return self:Begin(character, "Idle", true)
    end

    local token = record.token + 1
    self._states[character] = {
        state = "Idle",
        token = token,
        startedAt = self._clock(),
    }
    return token
end

function CombatStateMachine:Destroy(character: Model)
    self._states[character] = nil
end

return CombatStateMachine
