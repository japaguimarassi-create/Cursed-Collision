--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Timeline = require(ReplicatedStorage.Combat.AbilityTimeline)
local AnimationData = require(ReplicatedStorage.Animation.AnimationData)
local HitRegistry = require(ReplicatedStorage.Combat.HitRegistry)
local StateManager: any = require(script.Parent.StateManager)
local CooldownService = require(script.Parent.CooldownService)
local CharacterService = require(ReplicatedStorage.Characters.CharacterService)
local EmoteService = require(script.Parent.EmoteService)

local AbilityService: any = {}
AbilityService.__index = AbilityService

type ActiveAbility = {
    token: number,
    attackId: string,
    slot: number,
    startedAt: number,
    hitWindowStart: number,
    hitWindowEnd: number,
    markerRequired: boolean,
    hitResolved: boolean,
    cancelled: boolean
}

function AbilityService.new(context: any)
    return setmetatable({
        Context = context,
        Active = {} :: {[Player]: ActiveAbility}
    }, AbilityService)
end

local Movesets = require(ReplicatedStorage.Characters.CustomMovesets)

local function moveOf(player: Player, slot: number)
    local id = player:GetAttribute("CharacterId") or "PotentialMan"
    return Movesets.GetMove(id, slot)
end

local function rootOf(player: Player): BasePart?
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return if root and root:IsA("BasePart") then root else nil
end

function AbilityService:Cancel(player: Player)
    local current = self.Active[player]
    if not current then
        return
    end

    current.cancelled = true
    HitRegistry:End(player, current.attackId)
    self.Active[player] = nil

    local state = StateManager:Get(player)
    if state and state.Vars.ActiveAttackId == current.attackId then
        state.Vars.ActiveAttackId = nil
    end
end

function AbilityService:_resolve(player: Player, attackId: string): boolean
    local current = self.Active[player]

    if not current
        or current.attackId ~= attackId
        or current.cancelled
        or current.hitResolved then
        return false
    end

    local state = StateManager:Get(player)
    local move = moveOf(player, current.slot)
    local t = os.clock()

    if not state
        or not move
        or state.AbilityToken ~= current.token
        or t < current.hitWindowStart
        or t > current.hitWindowEnd
        or state.StunnedUntil > t
        or state.RagdollUntil > t
        or state.Phase == "Dead" then
        return false
    end

    current.hitResolved = true

    local root = rootOf(player)
    if root then
        self.Context.fx("AbilityTimeline", root.Position, {
            actor = player.Character,
            action = "Skill" .. tostring(current.slot),
            move = move.Name,
            phase = "HitFrame",
            attackId = attackId
        })
    end

    local success = CharacterService:SkillSlot(player, current.slot)

    if not success then
        current.hitResolved = true
    end

    return success
end

function AbilityService:Execute(player: Player, slot: number): boolean
    local state = StateManager:Get(player)
    if not state or slot < 1 or slot > 4 then
        return false
    end

    local now = os.clock()

    if not StateManager:CanAct(player, now)
        or state.Blocking
        or state.RecoveryUntil > now
        or state.Phase == "Attacking"
        or state.Phase == "Dashing"
        or state.Phase == "Ultimate"
        or state.Phase == "Awakening" then
        return false
    end

    local move = moveOf(player, slot)
    if not move then
        return false
    end

    local key = "Skill" .. tostring(slot)

    if not CooldownService:Ready(player, key, now) then
        return false
    end

    EmoteService:Stop(player)

    local token = StateManager:BeginAbility(player, key, now)
    if not token then
        return false
    end

    local timeline = Timeline:Get(move)
    local markers = Timeline:Markers(move)
    local attackId = tostring(player.UserId) .. ":" .. key .. ":" .. tostring(token)
    local animationDefinition = AnimationData[key]

    HitRegistry:Begin(player, attackId)

    local cooldown = math.clamp(
        tonumber(move.Cooldown) or 1,
        0.25,
        10
    )

    CooldownService:Set(player, key, cooldown, now)

    local markerRequired = animationDefinition ~= nil
        and animationDefinition.AnimationId ~= ""

    local record: ActiveAbility = {
        token = token,
        attackId = attackId,
        slot = slot,
        startedAt = now,
        hitWindowStart = now + math.max(0.025, timeline.Startup - 0.08),
        hitWindowEnd = now + timeline.Startup + 0.32,
        markerRequired = markerRequired,
        hitResolved = false,
        cancelled = false
    }

    self.Active[player] = record
    state.Vars.ActiveAttackId = attackId
    state.Vars.ActiveMove = move

    local root = rootOf(player)
    if root then
        self.Context.fx("AbilityTimeline", root.Position, {
            actor = player.Character,
            action = key,
            move = move.Name,
            phase = "Startup",
            markers = markers,
            attackId = attackId,
            marker = "Hit"
        })

        self.Context.fx("CombatAction", root.Position, {
            actor = player.Character,
            action = "SkillStart",
            slot = slot,
            move = move.Name,
            attackId = attackId,
            marker = "Hit",
            markerRequired = markerRequired,
            fallbackHitDelay = timeline.Startup
        })
    end

    task.delay(timeline.Startup, function()
        if self.Active[player] ~= record or record.cancelled then
            return
        end

        if not record.markerRequired then
            self:_resolve(player, attackId)
        end
    end)

    task.delay(timeline.Startup + 0.34, function()
        if self.Active[player] == record and not record.hitResolved then
            self:_resolve(player, attackId)
        end
    end)

    task.delay(timeline.Total, function()
        if self.Active[player] ~= record or record.cancelled then
            return
        end

        HitRegistry:End(player, attackId)

        local latestState = StateManager:Get(player)
        if latestState and latestState.Vars.ActiveAttackId == attackId then
            latestState.Vars.ActiveAttackId = nil
        end

        if StateManager:IsAbilityValid(player, token) then
            StateManager:SetPhase(player, "Idle")
        end

        self.Active[player] = nil
    end)

    return true
end

function AbilityService:ConfirmHit(player: Player, attackId: string): boolean
    return self:_resolve(player, attackId)
end

return AbilityService
