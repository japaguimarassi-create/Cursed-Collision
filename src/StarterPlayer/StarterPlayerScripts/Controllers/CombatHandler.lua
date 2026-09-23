--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationData = require(ReplicatedStorage.Animation.AnimationData)
local AnimationCache = require(script.Parent.AnimationCache)
local AnimationController: any = require(script.Parent.AnimationController)

local player = Players.LocalPlayer
local CombatHandler = {}
CombatHandler.__index = CombatHandler

type ActiveTrack = {
    Track: AnimationTrack,
    Connection: RBXScriptConnection,
    AttackId: string?,
    Finished: boolean
}

local active: {[Model]: ActiveTrack} = {}

local function getAnimator(model: Model): Animator?
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return nil
    end

    return humanoid:FindFirstChildOfClass("Animator")
end

local function stop(model: Model)
    local entry = active[model]
    if not entry then
        return
    end

    entry.Connection:Disconnect()

    if entry.Track.IsPlaying then
        entry.Track:Stop(0.04)
    end

    active[model] = nil
end

local function sendHit(
    actor: Model,
    attackId: string?,
    combatAction: RemoteEvent,
    route: string
)
    if actor ~= player.Character or not attackId then
        return
    end

    combatAction:FireServer(route, {
        attackId = attackId
    })
end

local function playMarkerAttack(
    actor: Model,
    key: string,
    attackId: string?,
    fallbackDelay: number,
    combatAction: RemoteEvent,
    route: string
)
    stop(actor)

    local animator = getAnimator(actor)
    local definition = AnimationData[key]

    if not animator or not definition then
        return
    end

    local track = AnimationCache:GetTrack(animator, key)

    if not track then
        if actor == player.Character and attackId then
            task.delay(math.max(0.01, fallbackDelay), function()
                sendHit(actor, attackId, combatAction, route)
            end)
        end
        return
    end

    track.Priority = Enum.AnimationPriority.Action
    track:Play(definition.FadeIn, 1, definition.Speed)

    local fired = false
    local connection = track:GetMarkerReachedSignal("Hit"):Connect(function()
        if fired then
            return
        end

        fired = true
        sendHit(actor, attackId, combatAction, route)
    end)

    active[actor] = {
        Track = track,
        Connection = connection,
        AttackId = attackId,
        Finished = false
    }

    -- Sem asset/marker utilizável, o servidor continua protegendo a janela e o cliente usa fallback.
    if actor == player.Character and attackId and definition.AnimationId == "" then
        task.delay(math.max(0.01, fallbackDelay), function()
            if not fired then
                fired = true
                sendHit(actor, attackId, combatAction, route)
            end
        end)
    end
end

function CombatHandler:OnCombatEvent(payload: {[string]: any}, combatAction: RemoteEvent): boolean
    local actor = payload.actor
    if not actor or not actor:IsA("Model") then
        return false
    end

    local action = tostring(payload.action or "")

    if action == "M1Start" then
        local combo = math.clamp(tonumber(payload.combo) or 1, 1, 4)
        playMarkerAttack(
            actor,
            "M1_" .. tostring(combo),
            type(payload.attackId) == "string" and payload.attackId or nil,
            tonumber(payload.fallbackHitDelay) or 0.075,
            combatAction,
            "M1Hit"
        )
        return true
    end

    if action == "SkillStart" then
        local slot = math.clamp(tonumber(payload.slot) or 1, 1, 4)
        playMarkerAttack(
            actor,
            "Skill" .. tostring(slot),
            type(payload.attackId) == "string" and payload.attackId or nil,
            tonumber(payload.fallbackHitDelay) or 0.12,
            combatAction,
            "SkillHit"
        )
        return true
    end

    if action == "Dash" then
        local animator = getAnimator(actor)
        if animator then
            AnimationCache:Play(
                animator,
                payload.air and "AirDash" or "Dash"
            )
        end
        return true
    end

    return false
end

function CombatHandler:Stop(model: Model)
    stop(model)
end

return CombatHandler
