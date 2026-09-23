--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationData = require(ReplicatedStorage.Animation.AnimationData)
local AnimationCache: any = require(script.Parent.AnimationCache)
local AnimationController: any = require(script.Parent.AnimationController)

local player = Players.LocalPlayer
local CombatHandler = {}

type ActiveTrack = {
    track: AnimationTrack,
    connection: RBXScriptConnection?,
    attackId: string?,
    token: number?
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

    if entry.connection then
        entry.connection:Disconnect()
    end

    if entry.track.IsPlaying then
        entry.track:Stop(0.05)
    end

    active[model] = nil
end

local function fallbackHit(
    attackId: string?,
    token: number?,
    delayTime: number,
    action: string,
    fire: (string, any) -> ()
)
    if not attackId or delayTime <= 0 then
        return
    end

    task.delay(delayTime, function()
        local payload: {[string]: any} = {
            attackId = attackId
        }

        if token ~= nil then
            payload.token = token
        end

        fire(action, payload)
    end)
end

local function playMarkerAttack(
    model: Model,
    key: string,
    attackId: string?,
    token: number?,
    fallbackDelay: number,
    action: string,
    fire: (string, any) -> ()
)
    stop(model)

    local animator = getAnimator(model)
    if not animator then
        return
    end

    local definition = AnimationData[key]
    if not definition then
        return
    end

    local track = AnimationCache:GetTrack(animator, key)
    if not track then
        -- Fallback visual: mantém o combate apresentável enquanto os assets
        -- publicados ainda não estão configurados.
        AnimationController:Play(
            model,
            key,
            {
                move = key,
                attackId = attackId
            }
        )

        fallbackHit(
            attackId,
            token,
            fallbackDelay,
            action,
            fire
        )
        return
    end

    track.Priority = Enum.AnimationPriority.Action
    track:Play(definition.FadeIn, 1, definition.Speed)

    local fired = false
    local markerName = definition.Marker or "Hit"

    local connection = track:GetMarkerReachedSignal(markerName):Connect(function()
        if fired then
            return
        end

        fired = true

        if attackId then
            local payload: {[string]: any} = {
                attackId = attackId
            }

            if token ~= nil then
                payload.token = token
            end

            fire(action, payload)
        end
    end)

    active[model] = {
        track = track,
        connection = connection,
        attackId = attackId,
        token = token
    }
end

function CombatHandler:PlayM1(payload: any, combatAction: RemoteEvent)
    local actor = payload.actor
    if not actor or not actor:IsA("Model") then
        return
    end

    local combo = math.clamp(
        tonumber(payload.combo) or 1,
        1,
        4
    )

    local key = "M1_" .. tostring(combo)
    local attackId = type(payload.attackId) == "string"
        and payload.attackId
        or nil

    local token = tonumber(payload.token)
    local fallbackDelay = math.max(
        0.01,
        tonumber(payload.fallbackHitDelay) or 0.075
    )

    playMarkerAttack(
        actor,
        key,
        attackId,
        token,
        fallbackDelay,
        "M1Hit",
        function(action, data)
            if actor == player.Character then
                combatAction:FireServer(action, data)
            end
        end
    )
end

function CombatHandler:PlaySkill(payload: any, combatAction: RemoteEvent)
    local actor = payload.actor
    if not actor or not actor:IsA("Model") then
        return
    end

    local slot = math.clamp(
        tonumber(payload.slot) or 1,
        1,
        4
    )

    local key = "Skill" .. tostring(slot)
    local attackId = type(payload.attackId) == "string"
        and payload.attackId
        or nil

    local token = tonumber(payload.token)
    local fallbackDelay = math.max(
        0.01,
        tonumber(payload.fallbackHitDelay) or 0.12
    )

    playMarkerAttack(
        actor,
        key,
        attackId,
        token,
        fallbackDelay,
        "SkillHit",
        function(action, data)
            if actor == player.Character then
                combatAction:FireServer(action, data)
            end
        end
    )
end

function CombatHandler:OnCombatEvent(
    payload: any,
    combatAction: RemoteEvent
): boolean
    local action = tostring(payload.action or "")

    if action == "M1Start" then
        self:PlayM1(payload, combatAction)
        return true
    end

    if action == "SkillStart" then
        self:PlaySkill(payload, combatAction)
        return true
    end

    if action == "Dash" then
        local actor = payload.actor
        if actor and actor:IsA("Model") then
            local animator = getAnimator(actor)
            if animator then
                AnimationController:Bind(actor)
                AnimationController:StopIdleCombat(actor)
                AnimationCache:Play(
                    animator,
                    payload.air and "AirDash" or "Dash"
                )
            end
        end
        return true
    end

    return false
end

function CombatHandler:Stop(model: Model)
    stop(model)
end

return CombatHandler
