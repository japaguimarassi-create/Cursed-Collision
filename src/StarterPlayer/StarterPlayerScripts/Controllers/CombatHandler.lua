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

    if entry.track and entry.track.IsPlaying then
        entry.track:Stop(0.04)
    end

    active[model] = nil
end

local function markerRequest(
    model: Model,
    attackId: string?,
    fallbackDelay: number,
    combatAction: RemoteEvent
)
    if not attackId or model ~= player.Character then
        return
    end

    local fired = false

    local function fireServer()
        if fired then
            return
        end

        fired = true
        combatAction:FireServer("M1Hit", {
            attackId = attackId
        })
    end

    task.delay(math.max(0.01, fallbackDelay), fireServer)

    return fireServer
end

local function playAttack(
    model: Model,
    key: string,
    attackId: string?,
    fallbackDelay: number,
    combatAction: RemoteEvent,
    action: "M1Hit" | "SkillHit"
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
        task.delay(math.max(0.01, fallbackDelay), submit)
        active[model] = {
            track = nil,
            markerConnection = nil,
            fired = false,
            attackId = attackId
        }
        return true
    end

    track.Priority = Enum.AnimationPriority.Action
    track.Looped = false
    track:Play(definition.FadeIn, 1, definition.Speed)

    local markerConnection: RBXScriptConnection?
    if definition.Marker then
        markerConnection = track:GetMarkerReachedSignal(definition.Marker):Connect(function()
            submit()
        end)
    end

    active[model] = {
        track = track,
        markerConnection = markerConnection,
        fired = false,
        attackId = attackId
    }

    -- Fallback apenas evita que uma animação sem marcador pare o ataque.
    task.delay(math.max(0.01, fallbackDelay), submit)

    return true
end

function CombatHandler:PlayM1(payload: any, combatAction: RemoteEvent): boolean
    local actor = payload.actor
    if not actor or not actor:IsA("Model") then
        return false
    end

    local combo = math.clamp(tonumber(payload.combo) or 1, 1, 4)
    local key = "M1_" .. tostring(combo)
    local attackId = type(payload.attackId) == "string" and payload.attackId or nil
    local fallbackDelay = math.max(0.01, tonumber(payload.hitDelay) or 0.08)

    return playAttack(
        actor,
        key,
        attackId,
        fallbackDelay,
        combatAction,
        "M1Hit"
    )
end

function CombatHandler:PlaySkill(payload: any, combatAction: RemoteEvent): boolean
    local actor = payload.actor
    if not actor or not actor:IsA("Model") then
        return false
    end

    local slot = math.clamp(tonumber(payload.slot) or 1, 1, 4)
    local key = "Skill" .. tostring(slot)
    local attackId = type(payload.attackId) == "string" and payload.attackId or nil
    local fallbackDelay = math.max(0.01, tonumber(payload.hitDelay) or 0.16)

    return playAttack(
        actor,
        key,
        attackId,
        fallbackDelay,
        combatAction,
        "SkillHit"
    )
end

function CombatHandler:OnCombatEvent(payload: any, combatAction: RemoteEvent): boolean
    local action = tostring(payload.action or "")

    if action == "M1Start" then
        return self:PlayM1(payload, combatAction)
    end

    if action == "SkillStart" then
        return self:PlaySkill(payload, combatAction)
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

        AnimationCache:Play(
            animator,
            payload.air == true and "AirDash" or "Dash"
        )

        return true
    end

    return false
end

function CombatHandler:Stop(model: Model)
    clear(model)
end

return CombatHandler
