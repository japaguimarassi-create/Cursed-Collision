--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationData = require(ReplicatedStorage.Animation.AnimationData)
local AnimationCache: any = require(script.Parent.AnimationCache)
local AnimationController: any = require(script.Parent.AnimationController)

local player = Players.LocalPlayer
local CombatHandler = {}

type ActiveTrack = {
    track: AnimationTrack?,
    markerConnection: RBXScriptConnection?,
    stoppedConnection: RBXScriptConnection?,
    fired: boolean,
    attackId: string?
}

local active: {[Model]: ActiveTrack} = {}

local function getAnimator(model: Model): Animator?
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return nil
    end

    return humanoid:FindFirstChildOfClass("Animator")
end

local function clear(model: Model)
    local entry = active[model]
    if not entry then
        return
    end

    if entry.markerConnection then
        entry.markerConnection:Disconnect()
    end

    if entry.stoppedConnection then
        entry.stoppedConnection:Disconnect()
    end

    if entry.track and entry.track.IsPlaying then
        entry.track:Stop(0.04)
    end

    active[model] = nil
end

local function playAttack(
    model: Model,
    key: string,
    attackId: string?,
    combatAction: RemoteEvent,
    action: "M1Hit" | "SkillHit" | "SpecialHit"
): boolean
    clear(model)

    local animator = getAnimator(model)
    local definition = AnimationData[key]

    if not animator or not definition then
        return false
    end

    local track = AnimationCache:GetTrack(animator, key)
    local fired = false

    local function submit()
        if fired or model ~= player.Character or not attackId then
            return
        end

        fired = true
        combatAction:FireServer(action, {
            attackId = attackId
        })
    end

    if not track then
        -- A apresentação continua usando o controlador procedural; o servidor,
        -- e não o cliente, decide o momento do impacto quando não há marcador.
        AnimationController:Play(model, key, {
            attackId = attackId
        })
        return true
    end

    track.Priority = Enum.AnimationPriority.Action
    track.Looped = definition.Loop
    track:Play(definition.FadeIn, 1, definition.Speed)

    local markerConnection: RBXScriptConnection?
    if definition.Marker == "Hit" then
        markerConnection = track:GetMarkerReachedSignal("Hit"):Connect(function()
            submit()
        end)
    end

    local stoppedConnection = track.Stopped:Connect(function()
        local entry = active[model]
        if entry and entry.track == track then
            if entry.markerConnection then
                entry.markerConnection:Disconnect()
            end
            if entry.stoppedConnection then
                entry.stoppedConnection:Disconnect()
            end
            active[model] = nil
        end
    end)

    active[model] = {
        track = track,
        markerConnection = markerConnection,
        stoppedConnection = stoppedConnection,
        fired = false,
        attackId = attackId
    }

    return true
end

function CombatHandler:PlayM1(payload: {[string]: any}, combatAction: RemoteEvent): boolean
    local actor = payload.actor
    if not actor or not actor:IsA("Model") then
        return false
    end

    local combo = math.clamp(tonumber(payload.combo) or 1, 1, 4)
    local key = "M1_" .. tostring(combo)
    local attackId = type(payload.attackId) == "string" and payload.attackId or nil

    return playAttack(
        actor,
        key,
        attackId,
        combatAction,
        "M1Hit"
    )
end

function CombatHandler:PlaySpecial(payload: {[string]: any}, combatAction: RemoteEvent): boolean
    local actor = payload.actor
    if not actor or not actor:IsA("Model") then
        return false
    end

    local attackId = type(payload.attackId) == "string" and payload.attackId or nil

    return playAttack(
        actor,
        "Special",
        attackId,
        combatAction,
        "SpecialHit"
    )
end

function CombatHandler:PlaySkill(payload: {[string]: any}, combatAction: RemoteEvent): boolean
    local actor = payload.actor
    if not actor or not actor:IsA("Model") then
        return false
    end

    local slot = math.clamp(tonumber(payload.slot) or 1, 1, 4)
    local key = "Skill" .. tostring(slot)
    local attackId = type(payload.attackId) == "string" and payload.attackId or nil

    return playAttack(
        actor,
        key,
        attackId,
        combatAction,
        "SkillHit"
    )
end

function CombatHandler:OnCombatEvent(payload: {[string]: any}, combatAction: RemoteEvent): boolean
    local action = tostring(payload.action or "")

    if action == "M1Start" then
        return self:PlayM1(payload, combatAction)
    end

    if action == "SkillStart" then
        return self:PlaySkill(payload, combatAction)
    end

    if action == "SpecialStart" then
        return self:PlaySpecial(payload, combatAction)
    end

    if action == "Dash" then
        local actor = payload.actor
        if not actor or not actor:IsA("Model") then
            return false
        end

        AnimationController:Bind(actor)

        local animator = getAnimator(actor)
        if not animator then
            return false
        end

        local key = if payload.air == true
            then "AirDash"
            elseif payload.dashDirection == "Back"
            then "BackDash"
            elseif payload.dashDirection == "Left"
                or payload.dashDirection == "Right"
            then "SideDash"
            else "Dash"

        AnimationCache:Play(animator, key)

        return true
    end

    return false
end

function CombatHandler:Stop(model: Model)
    clear(model)
end

return CombatHandler
