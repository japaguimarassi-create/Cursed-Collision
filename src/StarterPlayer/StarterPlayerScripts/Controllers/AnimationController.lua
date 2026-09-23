--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationData = require(ReplicatedStorage.Animation.AnimationData)
local AnimationCache: any = require(script.Parent.AnimationCache)
local StateMachine: any = require(script.Parent.AnimationStateMachine)
local Procedural = require(ReplicatedStorage.Combat.CombatAnimationService)

local AnimationController = {}
AnimationController.__index = AnimationController

type CharacterData = {
    animator: Animator,
    machine: any,
    markerConnections: {[string]: RBXScriptConnection},
}

local bound: {[Model]: CharacterData} = {}

local function animatorOf(character: Model): Animator?
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return nil
    end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then
        return animator
    end

    local created = Instance.new("Animator")
    created.Parent = humanoid
    return created
end

local function fallback(character: Model, key: string, payload: any): boolean
    local move = tostring(payload and (payload.move or payload.Name) or key)

    if key == "HitLight"
        or key == "HitHeavy"
        or key == "HitLaunch"
        or key == "HitSlam"
        or key == "HitFinisher" then
        local reaction =
            if key == "HitHeavy" then "Heavy"
            elseif key == "HitLaunch" then "Launcher"
            elseif key == "HitSlam" then "Slam"
            elseif key == "HitFinisher" then "Death"
            else "Light"

        Procedural:HitReact(character, tonumber(payload and payload.damage) or 1, reaction)
        return true
    end

    if string.match(key, "^M1_[1-4]$") then
        local combo = tonumber(string.sub(key, 4)) or 1
        return Procedural:PlayAttack(character, "M1", {
            combo = combo,
            move = move
        })
    end

    if string.match(key, "^Skill[1-4]$") then
        return Procedural:PlaySkill(character, move, payload or {})
    end

    if key == "Block" then
        return Procedural:PlayAttack(character, "Block", payload or {})
    end

    if key == "Parry" then
        return Procedural:HitReact(character, 1.5, "Parry")
    end

    if key == "Dash" or key == "AirDash" then
        return Procedural:PlayAttack(character, "Dash", payload or {})
    end

    if key == "Special" or key == "Ultimate" or key == "Awakening" then
        return Procedural:PlaySkill(character, move, payload or {})
    end

    if key == "Execution" then
        return Procedural:HitReact(character, 2, "Death")
    end

    return Procedural:PlayAttack(character, move, payload or {})
end

function AnimationController:Bind(character: Model): CharacterData?
    local current = bound[character]
    if current then
        return current
    end

    local animator = animatorOf(character)
    if not animator then
        return nil
    end

    local data: CharacterData = {
        animator = animator,
        machine = StateMachine.new(),
        markerConnections = {}
    }

    bound[character] = data
    return data
end

function AnimationController:Unbind(character: Model)
    local data = bound[character]
    if not data then
        return
    end

    for key, connection in pairs(data.markerConnections) do
        connection:Disconnect()
        data.markerConnections[key] = nil
    end

    AnimationCache:StopAll(data.animator, 0.04)
    bound[character] = nil
end

function AnimationController:Play(
    character: Model,
    key: string,
    payload: any,
    markerCallback: ((string, string?) -> ())?
): boolean
    local data = self:Bind(character)
    if not data then
        return false
    end

    local definition = AnimationData[key]
    if not definition then
        return fallback(character, key, payload)
    end

    local track = AnimationCache:GetTrack(data.animator, key)
    if not track then
        return fallback(character, key, payload)
    end

    local previous = data.markerConnections[key]
    if previous then
        previous:Disconnect()
        data.markerConnections[key] = nil
    end

    track.Looped = definition.Loop
    track.Priority = definition.Priority
    track:Play(definition.FadeIn, 1, definition.Speed)

    if markerCallback and definition.Marker then
        data.markerConnections[key] = track:GetMarkerReachedSignal(definition.Marker):Connect(function(value)
            markerCallback(definition.Marker :: string, value)
        end)
    end

    return true
end

function AnimationController:SetState(character: Model, state: string): boolean
    local data = self:Bind(character)
    if not data then
        return false
    end
    return data.machine:Set(state)
end

function AnimationController:ForceState(character: Model, state: string)
    local data = self:Bind(character)
    if data then
        data.machine:Force(state)
    end
end

function AnimationController:Stop(character: Model, key: string)
    local data = bound[character]
    if not data then
        return
    end

    local connection = data.markerConnections[key]
    if connection then
        connection:Disconnect()
        data.markerConnections[key] = nil
    end

    AnimationCache:Stop(data.animator, key, 0.04)
end

function AnimationController:PlayAttack(
    character: Model,
    move: string,
    comboOrOptions: any,
    power: any
): boolean
    local options =
        if type(comboOrOptions) == "table"
        then comboOrOptions
        else {
            combo = comboOrOptions,
            power = power
        }

    local combo = tonumber(options and options.combo)
    if combo then
        return self:Play(character, "M1_" .. tostring(math.clamp(combo, 1, 4)), options)
    end

    return fallback(character, tostring(move), options)
end

function AnimationController:PlaySkill(
    character: Model,
    skill: string,
    options: any
): boolean
    local slot = tonumber(options and options.slot) or 1
    local key = if slot >= 1 and slot <= 4
        then "Skill" .. tostring(math.floor(slot))
        else "Skill1"

    return self:Play(character, key, {
        move = skill,
        slot = slot,
        options = options
    })
end

function AnimationController:PlayDomain(character: Model, options: any): boolean
    return Procedural:PlayDomain(character, options or {})
end

function AnimationController:HitReact(
    character: Model,
    intensity: number,
    reaction: string
): boolean
    return Procedural:HitReact(character, intensity, reaction)
end

function AnimationController:ResetJoints(character: Model, duration: number?): boolean
    return Procedural:ResetJoints(character, duration or 0.12)
end

function AnimationController:Cancel(character: Model)
    return Procedural:Cancel(character)
end

function AnimationController:StartIdleCombat(character: Model, intensity: number?): boolean
    return Procedural:StartIdleCombat(character, intensity or 1)
end

function AnimationController:StopIdleCombat(character: Model)
    return Procedural:StopIdleCombat(character)
end

return AnimationController
